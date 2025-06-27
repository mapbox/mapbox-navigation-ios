// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let (navNativeVersion, navNativeChecksum, navNativeRevision) = ("324.14.0-alpha.1", "b1767c0e0bd354c56007aae75843aca409e7ab0bb21384947e03d390a14366fc", "4b34fea46345862730d6e35709d693d1c3d36c50")
let mapsVersion: Version = "11.14.0-alpha.1"
// Snapshot versions that your app already uses
let snapshotCommon   = "24.14.0-SNAPSHOT-06-06--04-30.git-ae7b59c"
let snapshotCoreMaps = "11.14.0-SNAPSHOT-06-06--04-30.git-ae7b59c"
let snapshotMapsRev  = "bd848edd449d4d244ba4a38c12964ac8b9e43f9b" // full 40-char hash


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
            name: "_MapboxNavigationLocalization",
            targets: ["_MapboxNavigationLocalization"]
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
        // keep NavNative the way it already is
        .package(
            url: "https://github.com/mapbox/mapbox-navigation-native-ios.git",
            exact: Version(stringLiteral: navNativeVersion)
        ),
    
        // MapboxMaps pinned to the commit already in your project
        .package(
            url: "https://github.com/mapbox/mapbox-maps-ios.git",
            .revision(snapshotMapsRev)
        ),
    
        // Add explicit pins for Common and CoreMaps snapshots
        .package(
            url: "https://github.com/mapbox/mapbox-common-ios.git",
            .exact(snapshotCommon)
        ),
        .package(
            url: "https://github.com/mapbox/mapbox-core-maps-ios.git",
            .exact(snapshotCoreMaps)
        ),
    
        // everything below stays exactly the same
        .package(url: "https://github.com/mapbox/turf-swift.git", exact: "4.0.0"),
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs", from: "9.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.18.1"),
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
            name: "_MapboxNavigationLocalization",
            dependencies: [
                "_MapboxNavigationHelpers"
            ]),
        .target(
            name: "MapboxNavigationCore",
            dependencies: [
                "_MapboxNavigationLocalization",
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
