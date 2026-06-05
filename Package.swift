// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "FluidReader",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "FluidReader", targets: ["FluidReader"])
    ],
    targets: [
        .executableTarget(
            name: "FluidReader",
            path: "Sources/FluidReader"
        ),
        .testTarget(
            name: "FluidReaderTests",
            dependencies: ["FluidReader"],
            path: "Tests/FluidReaderTests"
        )
    ]
)
