// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DuoKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "DuoKit", targets: ["DuoKit"]),
        .executable(name: "duo-lint", targets: ["duo-lint"]),
    ],
    targets: [
        // Pure layout decisions: posture, grid columns, fold displacement,
        // tab placement. No SwiftUI, so it is unit-tested on the Mac.
        .target(name: "DuoKitCore"),
        // The SwiftUI components. iOS only; empty on other platforms.
        .target(name: "DuoKit", dependencies: ["DuoKitCore"]),
        .target(name: "DuoLintCore"),
        .executableTarget(name: "duo-lint", dependencies: ["DuoLintCore"]),
        .testTarget(name: "DuoKitCoreTests", dependencies: ["DuoKitCore"]),
        .testTarget(name: "DuoLintCoreTests", dependencies: ["DuoLintCore"]),
    ]
)
