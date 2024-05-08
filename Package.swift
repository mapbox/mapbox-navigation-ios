// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let version = "3.1.0-beta.1"

let binaries = [
    "MapboxCoreMaps": "392c84f53b47c56b331d886b9dd3495adf006a44a90b8ba7df2ce716994bc9c9",
    "MapboxDirections": "3eb6235bc9a67aea527307a8e0108d54478e55d033548b0d485e3ea36e3c71a3",
    "MapboxMaps": "6cbcf09b52c027d404826f8f9a73ea976f24fc6174b38d03a08a660a085b6542",
    "Turf": "40308a5749eb8065164d015596d6c0b9075225a02cb44034b49a34b3a71f654c",
    "MapboxNavigationCore": "50c0a8b784681065581eefdcf5ac76ee6f55384a66b156bc40bed8c6d600e3ff",
    "_MapboxNavigationUXPrivate": "bfdb8b27166a8e20744de0af1ab6eb8c32ccd8dec5150812ba92d477975169ff",
    "MapboxNavigationUIKit": "5050749aed456e2f670bc31c00aeba3a58e801cc54f1def7e83b438d8faa9e4a",
]

let package = Package(
    name: "MapboxNavigation",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "MapboxNavigationCore",
            targets: ["MapboxNavigationCoreWrapper"]
        ),
        .library(
            name: "MapboxNavigationUIKit",
            targets: ["MapboxNavigationUIKitWrapper"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/mapbox/mapbox-common-ios.git", exact: "24.4.0-beta.3"),
        .package(url: "https://github.com/mapbox/mapbox-navigation-native-ios.git", exact: "308.0.0"),
    ],
    targets: [
        .target(
            name: "MapboxNavigationCoreWrapper",
            dependencies: binaries.keys.map { .byName(name: $0) } + [
                .product(name: "MapboxCommon", package: "mapbox-common-ios"),
                .product(name: "MapboxNavigationNative", package: "mapbox-navigation-native-ios"),
            ]
        ),
        .target(
            name: "MapboxNavigationUIKitWrapper",
            dependencies: [
                "MapboxNavigationCoreWrapper"
            ]
        ),
    ] + binaryTargets()
)

func binaryTargets() -> [Target] {
    return binaries.map { binaryName, checksum in
        Target.binaryTarget(
            name: binaryName,
            url: "https://api.mapbox.com/downloads/v2/navsdk-v3-ios" +
                "/releases/ios/packages/\(version)/\(binaryName).xcframework.zip",
            checksum: checksum
        )
    }
}
