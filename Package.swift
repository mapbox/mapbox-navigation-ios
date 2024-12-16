// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let (navNativeVersion, navNativeChecksum, navNativeRevision) = ("322.0.0-rc.1", "613de47f120adfba829151182d83fb4e401ae327ce6587099ad15f208da28685", "a235dae4e6f747c5f1fac31a2c3a74ae439a9573")
let mapsVersion: Version = "11.9.0-rc.1"

let package = Package(
    name: "MapboxNavigation",
    defaultLocalization: "en",
    // The Nav SDK doesn't support macOS but declared the minimum macOS requirement with downstream deps to enable `swift run` cli tools
    platforms: [.iOS(.v14), .macOS(.v10_15)],
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
        .executable(
            name: "mapbox-directions-swift",
            targets: ["MapboxDirectionsCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mapbox/mapbox-navigation-native-ios.git", exact: Version(stringLiteral: navNativeVersion)),
        .package(url: "https://github.com/mapbox/mapbox-maps-ios.git", exact: mapsVersion),
        .package(url: "https://github.com/mapbox/turf-swift.git", exact: "4.0.0-beta.1"),
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs", from: "9.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", exact: "1.12.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
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
        ),
        .executableTarget(
            name: "MapboxDirectionsCLI",
            dependencies: [
                "MapboxDirections",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),
    ]
)
