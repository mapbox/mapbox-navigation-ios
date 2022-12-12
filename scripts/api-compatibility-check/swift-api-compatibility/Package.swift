// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "swift-api-compatibility",
    products: [
        .executable(
            name: "swift-api-compatibility",
            targets: ["SwiftApiCompatibility"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "SwiftApiCompatibility",
            dependencies: [
                "SwiftApiCompatibilityKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(name: "SwiftApiCompatibilityKit"),
        .testTarget(name: "SwiftApiCompatibilityKitTests", dependencies: [
            "SwiftApiCompatibilityKit",
        ])
    ]
)
