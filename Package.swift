// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let version = "3.1.1"

let binaries = [
"MapboxCoreMaps": "c713512cd14460733742e1262d2cbdec87eb547b14dd2927d7b3fc3d74719844",
"MapboxDirections": "1ce9a2c009829adfd9868aedc8f5677d7345d0c44cdd4a6bca1b12724ba9e6a9",
"MapboxMaps": "2bbff17cee17d458a72e8202e74f31a906daaf632834cf4a118ada68a9e2e0fb",
"Turf": "aa80c52c0d4b5fe9c48947056bee69792c1594700208f8301583781826e87f70",
"MapboxNavigationCore": "074d55aaf97f151a4d0a05680bec37a50f543ce632addcd3b5d8046dd5a83ce8",
"_MapboxNavigationUXPrivate": "704cdddabc6af352cb19da28b5f1289e2b2b1b36e8e0168ba5a358261f780845",
"MapboxNavigationUIKit": "76d673cf538005297e5c6755365189947c3487bd501be10308e18efbe1a87a5a",
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
        .package(url: "https://github.com/mapbox/mapbox-navigation-native-ios.git", exact: "311.0.0"),
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
