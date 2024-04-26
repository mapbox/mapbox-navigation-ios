// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let version = "3.0.1"

let binaries = [
    "MapboxCoreMaps": "b50d9928a0c59ff9a4308dccb65bfffeb8a6e8a2fceeec7cc237cef015f4d951",
    "MapboxDirections": "604f184672dbeae5f627eec05804743ab4e6fccabc8c46751239e441e7cadbba",
    "MapboxMaps": "76c912983e0407ef93db1d56f3c6d065ec9d9d98812ef0e2bdd3395b974584a8",
    "Turf": "444855c9f08ffa459835e5f37b037515ec5f0abe8a6bc698c6c899ed3679aa41",
    "MapboxNavigationCore": "5b9f3f50f96e4c6827a48c3807e57c7a47fc3966760a4ec186b9e0f7ed72df7e",
    "_MapboxNavigationUXPrivate": "fa6a3a88beb66dd5d37154b16835e9555ce0db90d9308818f62e7f4bddc13c23",
    "MapboxNavigationUIKit": "1693f77fb0dcd72a4d919c4566190e8b41bab6aadfa75934eb384177687e28f4",
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
