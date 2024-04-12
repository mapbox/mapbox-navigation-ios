// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let version = "3.0.0"

let binaries = [
    "MapboxCoreMaps": "2f514f7127673d21e6074b949f5ca224d3c847a82513ed247a4bb3d4e0c0c271",
    "MapboxDirections": "fc246f668f167879d08f0de519d6884b1e9c01a77c641fd07fdce79fd316fe38",
    "MapboxMaps": "3c8fee306569216b0cade7d27bb66e7138cca01eed34d738ebeb6f204e820be1",
    "Turf": "595897f7f4117394c1b25f31c497feb539fc91b711099313c5cfc321b4bbfca8",
    "MapboxNavigationCore": "d6b3dbdf80e2894b45a84898b4905b2ae6ec95b4cfb0812fa23f059fa3feaedb",
    "_MapboxNavigationUXPrivate": "6dbb7a32a50464a2e4f5f0ab851ad03fbebf6c0fb8bcb9d660322529489f4806",
    "MapboxNavigationUIKit": "06c550195001293b09e96a36fd4c42288cb97bd9f10ec1dfa9ad45eadff0b580",
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
