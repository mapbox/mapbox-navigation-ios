// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let (navNativeVersion, navNativeChecksum, navNativeRevision) = ("317.0.0", "42af932c7d97a5c8a5c3836dda80cbc6524f410ef5f81b925300f7e70764ca6b", "40135b86650b4837c77a19a05d76266b66763232")
let mapsVersion: Version = "11.6.0"

let mapboxApiDownloads = "https://api.mapbox.com/downloads/v2"

let package = Package(
    name: "MapboxNavigation",
    defaultLocalization: "en",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "MapboxNavigationUIKit",
            targets: ["MapboxNavigationUIKit"]
        ),
        .library(
            name: "MapboxNavigationCore",
            targets: ["MapboxNavigationCore"]
        ),
        .library(
            name: "_MapboxNavigationTestKit",
            targets: ["_MapboxNavigationTestKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/mapbox/mapbox-navigation-native-ios.git", revision: navNativeRevision),
        .package(url: "https://github.com/mapbox/mapbox-maps-ios.git", exact: mapsVersion),
        .package(url: "https://github.com/mapbox/turf-swift.git", exact: "2.8.0"),
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs", from: "9.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", exact: "1.12.0"),
    ],
    targets: [
        .target(
            name: "MapboxNavigationUIKit",
            dependencies: [
                "MapboxNavigationCore",
            ],
            exclude: ["Info.plist"],
            resources: [
                .copy("Resources/MBXInfo.plist"),
                .copy("Resources/PrivacyInfo.xcprivacy")
            ]
        ),
        .target(name: "_MapboxNavigationHelpers"),
        .target(
            name: "MapboxNavigationCore",
            dependencies: [
                "_MapboxNavigationHelpers",
                .product(name: "MapboxNavigationNative", package: "mapbox-navigation-native-ios"),
                "MapboxDirections",
                .product(name: "MapboxMaps", package: "mapbox-maps-ios"),
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "MapboxDirections",
            dependencies: [
                .product(name: "Turf", package: "turf-swift"),
            ]
        ),

        // Test targets
        .testTarget(
            name: "MapboxNavigationCoreTests",
            dependencies: [
                "MapboxNavigationCore",
                "_MapboxNavigationTestHelpers",
            ],
            resources: [
                .copy("Fixtures"),
                .process("Resources"),
            ]
        ),
        .target(
            name: "_MapboxNavigationTestHelpers",
            dependencies: [
                "MapboxNavigationCore"
            ]
        ),
        .testTarget(
            name: "MapboxDirectionsTests",
            dependencies: [
                "MapboxDirections",
                .product(name:  "OHHTTPStubsSwift", package: "OHHTTPStubs"),
            ],
            resources: [.process("Fixtures")]
        ),
        .target(
            name: "TestHelper",
            dependencies: [
                "MapboxNavigationCore",
                "MapboxNavigationUIKit",
            ],
            exclude: ["Info.plist"],
            resources: [
                .process("Fixtures"),
            ]
        ),
        .target(
            name: "CarPlayTestHelper",
            exclude: [
                "Info.plist",
                "CarPlayTestHelper.h",
            ]
        ),
        .testTarget(
            name: "MapboxNavigationPackageTests",
            dependencies: [
                "MapboxNavigationUIKit",
                "TestHelper",
                "CarPlayTestHelper",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                .product(name:  "OHHTTPStubsSwift", package: "OHHTTPStubs"),
            ],
            exclude: [
                "Info.plist",
                "__Snapshots__", // Ignore snapshots folder
            ]
        ),
        .target(
            name: "_MapboxNavigationTestKit",
            dependencies: [
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                "_MapboxNavigationTestHelpers",
            ],
            path: "Sources/.empty/_MapboxNavigationTestKit"
        )
    ]
)
