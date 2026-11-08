// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WSF0Qualification",
    platforms: [.macOS("26.0")],
    products: [.library(name: "WSF0Qualification", targets: ["BrowserCore", "BrowserPersistence", "WSF0Fakes"])],
    targets: [
        .target(name: "BrowserDomain"),
        .target(name: "BrowserPorts", dependencies: ["BrowserDomain"]),
        .target(name: "BrowserCore", dependencies: ["BrowserDomain", "BrowserPorts"]),
        .target(name: "BrowserPersistence", dependencies: ["BrowserDomain", "BrowserPorts"]),
        .target(name: "WSF0Fakes", dependencies: ["BrowserDomain", "BrowserPorts"]),
        .testTarget(name: "WSF0Tests", dependencies: ["BrowserDomain", "BrowserPorts", "BrowserCore", "BrowserPersistence", "WSF0Fakes"])
    ],
    swiftLanguageModes: [.v6]
)
