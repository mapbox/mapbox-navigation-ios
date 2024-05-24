// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let version = "3.1.0"

let binaries = [
"MapboxCoreMaps": "c713512cd14460733742e1262d2cbdec87eb547b14dd2927d7b3fc3d74719844",
"MapboxDirections": "2058a3d6e67de92dd678f3aefd996025d09c5c0d9139a541cda9f25f576d4b76",
"MapboxMaps": "2bbff17cee17d458a72e8202e74f31a906daaf632834cf4a118ada68a9e2e0fb",
"Turf": "aa80c52c0d4b5fe9c48947056bee69792c1594700208f8301583781826e87f70",
"MapboxNavigationCore": "4910fa45d1643f1002a1e7e937c734b5db015ae5082cece73410d4a09050fab7",
"_MapboxNavigationUXPrivate": "af7558a09b488ee215d0fd9e6d0316d889383219e8473fc41c82e9c00549b5b7",
"MapboxNavigationUIKit": "c9b42fda558b5d86012314a46b489113cee6ffd61f088af5a3799e7732549652",
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
        .package(url: "https://github.com/mapbox/mapbox-common-ios.git", exact: "24.4.0"),
        .package(url: "https://github.com/mapbox/mapbox-navigation-native-ios.git", exact: "310.0.1"),
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
