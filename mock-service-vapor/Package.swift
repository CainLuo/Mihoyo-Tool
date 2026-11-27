// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "MockServer",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "mock-server", targets: ["MockServerCLI"]),
        .library(name: "MockServerCore", targets: ["MockServerCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.92.0"),
    ],
    targets: [
        .executableTarget(
            name: "MockServerCLI",
            dependencies: ["MockServerCore"]
        ),
        .target(
            name: "MockServerCore",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
            ]
        ),
        .testTarget(
            name: "MockServerCoreTests",
            dependencies: ["MockServerCore"]
        ),
    ]
)
