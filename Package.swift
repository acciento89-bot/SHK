// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SHKCore",
    platforms: [.macOS(.v13), .iOS(.v17)],
    products: [.library(name: "SHKCore", targets: ["SHKCore"])],
    targets: [
        .target(name: "SHKCore"),
        .testTarget(name: "SHKCoreTests", dependencies: ["SHKCore"])
    ]
)
