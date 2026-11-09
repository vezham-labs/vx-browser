// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "BrowserStorageRuntime", platforms: [.macOS("26.0")],
    products: [.library(name: "BrowserNativeStorage", targets: ["BrowserNativeStorage"])],
    dependencies: [.package(path: "../../../qualification/webkit-storage-f0")],
    targets: [
        .target(name: "BrowserNativeStorage", dependencies: [
            .product(name: "BrowserDomain", package: "webkit-storage-f0"),
            .product(name: "BrowserPorts", package: "webkit-storage-f0"),
            .product(name: "BrowserCore", package: "webkit-storage-f0"),
            .product(name: "BrowserPersistence", package: "webkit-storage-f0")]),
        .testTarget(name: "StorageModelTests", dependencies: [
            "BrowserNativeStorage",
            .product(name: "BrowserDomain", package: "webkit-storage-f0"),
            .product(name: "BrowserCore", package: "webkit-storage-f0"),
            .product(name: "WSF0Qualification", package: "webkit-storage-f0")])
    ], swiftLanguageModes: [.v6])
