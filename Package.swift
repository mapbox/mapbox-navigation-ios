// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let version = "3.0.2"

let binaries = [
    "MapboxCoreMaps": "a164dc57d0c3eaffe9a6fd493f5d2bef47cbf3fd9a0365679771e78df0421f37",
    "MapboxDirections": "a2e19aa52a0aa78417f379fb60aef1772ae00da777e92c761febc6a6ea744554",
    "MapboxMaps": "ffd302cd2d6fbadd37bff6d391a2c48fcb7aa2620a219103ce7a2a5e3c7b9fb0",
    "Turf": "4eabc83d358f6962a80bec3a988723c5e7eda20d85333d019966c4ec12b5c066",
    "MapboxNavigationCore": "ecfab910af2df3b430c3094501b904c54e12fb773a63f2eabaa8885fb75dec43",
    "_MapboxNavigationUXPrivate": "9c3a30a473e28361c34d6dd8ab8c8c5f501094b2a1699a31fe898448cdebba25",
    "MapboxNavigationUIKit": "203e840e647bb10799a6348ade7730cc2a5d59f058fc74ef8b69437e737a86a3",
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
        .package(url: "https://github.com/mapbox/mapbox-common-ios.git", exact: "24.3.1"),
        .package(url: "https://github.com/mapbox/mapbox-navigation-native-ios.git", exact: "305.0.0"),
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
