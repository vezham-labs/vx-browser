import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum Failure: Error { case arguments, decode, geometry, write }
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
let pixelFormat = CGImageAlphaInfo.premultipliedLast.rawValue

func decode(_ url: URL) throws -> (Int, Int, [UInt8]) {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { throw Failure.decode }
    let width = image.width
    let height = image.height
    var pixels = [UInt8](repeating: 0, count: 4 * width * height)
    try pixels.withUnsafeMutableBytes { bytes in
        guard let context = CGContext(data: bytes.baseAddress, width: width, height: height,
                                      bitsPerComponent: 8, bytesPerRow: width * 4,
                                      space: colorSpace, bitmapInfo: pixelFormat) else { throw Failure.decode }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    }
    return (width, height, pixels)
}

func png(_ pixels: [UInt8], width: Int, height: Int, to url: URL) throws {
    guard let provider = CGDataProvider(data: Data(pixels) as CFData),
          let image = CGImage(width: width, height: height, bitsPerComponent: 8,
                              bitsPerPixel: 32, bytesPerRow: width * 4, space: colorSpace,
                              bitmapInfo: CGBitmapInfo(rawValue: pixelFormat), provider: provider,
                              decode: nil, shouldInterpolate: false, intent: .defaultIntent),
          let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
    else { throw Failure.write }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { throw Failure.write }
}

struct Region {
    let name: String
    let x: Range<Int>
    let y: Range<Int>
}

struct Differences {
    var count = 0
    var changed = 0
    var above8 = 0
    var absoluteSum: UInt64 = 0

    mutating func record(_ red: Int, _ green: Int, _ blue: Int) {
        count += 1
        let maxDelta = max(red, green, blue)
        if maxDelta > 0 { changed += 1 }
        if maxDelta > 8 { above8 += 1 }
        absoluteSum += UInt64(red + green + blue)
    }

    var metrics: [String: Any] {
        [
            "pixels": count,
            "differentPixels": changed,
            "mismatchPercent": 100 * Double(changed) / Double(count),
            "pixelsWithChannelDifferenceAbove8": above8,
            "mismatchAbove8Percent": 100 * Double(above8) / Double(count),
            "meanAbsoluteChannelDifference": Double(absoluteSum) / Double(3 * count)
        ]
    }
}

func luma(_ pixels: [UInt8], at i: Int) -> Double {
    0.2126 * Double(pixels[i]) + 0.7152 * Double(pixels[i + 1]) + 0.0722 * Double(pixels[i + 2])
}

func structuralSimilarity(_ a: [UInt8], _ b: [UInt8], width: Int, height: Int) -> Double {
    let c1 = pow(0.01 * 255, 2.0)
    let c2 = pow(0.03 * 255, 2.0)
    var sum = 0.0
    var blocks = 0
    for top in stride(from: 0, to: height, by: 8) {
        for left in stride(from: 0, to: width, by: 8) {
            var sx = 0.0, sy = 0.0, sx2 = 0.0, sy2 = 0.0, sxy = 0.0
            for y in top..<top + 8 {
                for x in left..<left + 8 {
                    let i = (y * width + x) * 4
                    let p = luma(a, at: i), q = luma(b, at: i)
                    sx += p
                    sy += q
                    sx2 += p * p
                    sy2 += q * q
                    sxy += p * q
                }
            }
            let mx = sx / 64, my = sy / 64
            let vx = max(0, (sx2 - sx * mx) / 63)
            let vy = max(0, (sy2 - sy * my) / 63)
            let cov = (sxy - sx * my) / 63
            sum += (2 * mx * my + c1) * (2 * cov + c2) / ((mx * mx + my * my + c1) * (vx + vy + c2))
            blocks += 1
        }
    }
    return sum / Double(blocks)
}

guard CommandLine.arguments.count == 4 else { throw Failure.arguments }
let inputs = CommandLine.arguments.dropFirst().map { URL(fileURLWithPath: $0) }
let (width, height, arc) = try decode(inputs[0])
let (otherWidth, otherHeight, vezham) = try decode(inputs[1])
guard width == 2880, height == 1648, width == otherWidth, height == otherHeight else { throw Failure.geometry }

// Fixed regions in unmodified screenshot coordinates, using the baseline Arc
// sidebar/content transition and keeping the full page in the comparison.
let regions = [
    Region(name: "window", x: 0..<width, y: 0..<height),
    Region(name: "sidebar", x: 0..<656, y: 0..<height),
    Region(name: "navigationAndAddress", x: 0..<656, y: 0..<175),
    Region(name: "workspaceAndTabs", x: 0..<656, y: 175..<1350),
    Region(name: "sidebarFooter", x: 0..<656, y: 1350..<height),
    Region(name: "mainBrowserArea", x: 656..<width, y: 0..<height)
]
var blend = arc
var difference = arc
var sideBySide = [UInt8]()
sideBySide.reserveCapacity(arc.count + vezham.count)
for y in 0..<height {
    let row = y * width * 4..<(y + 1) * width * 4
    sideBySide.append(contentsOf: arc[row])
    sideBySide.append(contentsOf: vezham[row])
}
for i in stride(from: 0, to: arc.count, by: 4) {
    for channel in i..<i + 3 {
        let a = Int(arc[channel]), v = Int(vezham[channel])
        difference[channel] = UInt8(abs(a - v))
        blend[channel] = UInt8((a + v) / 2)
    }
}
var regionalMetrics: [String: Any] = [:]
for region in regions {
    var summary = Differences()
    for y in region.y {
        for x in region.x {
            let i = (y * width + x) * 4
            summary.record(Int(difference[i]), Int(difference[i + 1]), Int(difference[i + 2]))
        }
    }
    regionalMetrics[region.name] = [
        "boundsXYWH": [region.x.lowerBound, region.y.lowerBound, region.x.count, region.y.count],
        "metrics": summary.metrics
    ]
}
let out = inputs[2]
try png(blend, width: width, height: height, to: out.appendingPathComponent("overlay.png"))
try png(difference, width: width, height: height, to: out.appendingPathComponent("pixel-difference.png"))
try png(sideBySide, width: width * 2, height: height, to: out.appendingPathComponent("side-by-side.png"))
let metrics: [String: Any] = [
    "width": width, "height": height, "regions": regionalMetrics,
    "structuralSimilarityLuma8x8": structuralSimilarity(arc, vezham, width: width, height: height),
    "method": "Full native JPEG capture, decoded sRGB. Exact RGB mismatch, absolute difference and 50/50 blend. No crop, resize or masks. SSIM is the mean of non-overlapping 8×8 Rec.709 luma block scores."
]
let json = try JSONSerialization.data(withJSONObject: metrics, options: [.prettyPrinted, .sortedKeys])
try json.write(to: out.appendingPathComponent("metrics.json"))
