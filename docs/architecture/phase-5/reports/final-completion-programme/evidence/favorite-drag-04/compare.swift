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

guard CommandLine.arguments.count == 4 else { throw Failure.arguments }
let inputs = CommandLine.arguments.dropFirst().map { URL(fileURLWithPath: $0) }
let (width, height, arc) = try decode(inputs[0])
let (otherWidth, otherHeight, vezham) = try decode(inputs[1])
guard width == otherWidth, height == otherHeight else { throw Failure.geometry }
var blend = arc
var difference = arc
var changed = 0
var changedBeyond8 = 0
var absoluteSum: UInt64 = 0
for i in stride(from: 0, to: arc.count, by: 4) {
    var largest = 0
    for c in i ..< i + 3 {
        let delta = abs(Int(arc[c]) - Int(vezham[c]))
        largest = max(largest, delta)
        difference[c] = UInt8(delta)
        blend[c] = UInt8((Int(arc[c]) + Int(vezham[c])) / 2)
        absoluteSum += UInt64(delta)
    }
    if largest > 0 { changed += 1 }
    if largest > 8 { changedBeyond8 += 1 }
}
let destination = inputs[2]
try png(blend, width: width, height: height, to: destination.appendingPathComponent("overlay.png"))
try png(difference, width: width, height: height, to: destination.appendingPathComponent("pixel-difference.png"))
let metrics: [String: Any] = [
    "width": width, "height": height, "pixels": width * height,
    "pixelsWithAnyRGBDifference": changed,
    "pixelsWithAnyChannelDifferenceAbove8": changedBeyond8,
    "meanAbsoluteRGBChannelDifference": Double(absoluteSum) / Double(width * height * 3),
    "method": "Native-size JPEG input, decoded as sRGB. 50/50 channel average and absolute RGB difference. No crop or resize."
]
let json = try JSONSerialization.data(withJSONObject: metrics, options: [.prettyPrinted, .sortedKeys])
try json.write(to: destination.appendingPathComponent("pixel-metrics.json"))
