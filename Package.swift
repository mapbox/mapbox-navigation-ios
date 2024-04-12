// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let version = "3.0.0-rc.1"

let binaries = [
    "MapboxCoreMaps": "e03cbb9f9c60dcaaa6f58b83d57d7796e95d5cd9ae4e47cc194b7c917c930e31",
    "MapboxDirections": "974559a90d6aba462bb0527001456dc16ffd3ae506791cfd3d61fc986fe02d0e",
    "MapboxMaps": "97485654d30264683df34e9cf0be5e4d09262759b3b1550ea21910172413e8fe",
    "Turf": "2f5fffc7075f8582aca328f13b49e14cfb13d3ed1ee0789e53d657d827860b6f",
    "MapboxNavigationCore": "17f52c9aa1d941638489a3f2d55e8184ce17012c8eee0156e86cdcfbdb4bf189",
    "_MapboxNavigationUXPrivate": "1ee894eee848474826d5ab21761067d966e7343e0f436b985d21489fe6b2c3e2",
    "MapboxNavigationUIKit": "1111111",
]

let package = Package(
    name: "MapboxNavigation",
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
        .package(url: "https://github.com/mapbox/mapbox-common-ios.git", from: "24.3.1"),
        .package(url: "https://github.com/mapbox/mapbox-navigation-native-ios.git", from: "305.0.0"),
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

let usesRemoteBinaries = true

func binaryTargets() -> [Target] {
    return binaries.map { binaryName, checksum in
        if usesRemoteBinaries {
            return Target.binaryTarget(
                name: binaryName,
                url: "https://api.mapbox.com/downloads/v2/navsdk-v3-ios" +
                    "/releases/ios/packages/\(version)/\(binaryName).xcframework.zip",
                checksum: checksum
            )
        } else {
            return Target.binaryTarget(
                name: binaryName,
                path: "./XCFrameworks/\(binaryName).xcframework"
            )
        }
    }
}
