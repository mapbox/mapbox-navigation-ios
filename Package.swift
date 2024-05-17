// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let version = "3.1.0-beta.1"

let binaries = [
"MapboxCoreMaps": "73cc825f796586a821583a8c8ad39f5ec1cefcc56b3aaf611a5197dbca32b967",
"MapboxDirections": "adc51709e37c92e3e548189dcf53bb5c6472f9c9aee68150018cdd860611c26f",
"MapboxMaps": "056c4e484f996ce6977dcf5e9dc785e029124b584f70e6678cac86348e9f60d5",
"Turf": "8309276d8b47c17d6225c66f88f63571db76e03fb4f61cf22483b05046ee26d4",
"MapboxNavigationCore": "499bf8fad13f4b8a9a1e44911405aecb2c7848d83cf5048c294e06f1550412a2",
"_MapboxNavigationUXPrivate": "d67f4e9bd2a46c493fee22431eb6eaa7d432a5759b124f0ee62f346a19220000",
"MapboxNavigationUIKit": "97bb238bdc313a67e5b858305304f9ecb34c54050e029afa86fbba7463b0820d",
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
        .package(url: "https://github.com/mapbox/mapbox-common-ios.git", exact: "24.4.0-rc.2"),
        .package(url: "https://github.com/mapbox/mapbox-navigation-native-ios.git", exact: "309.0.0"),
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
