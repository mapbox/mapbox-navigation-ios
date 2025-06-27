// swift-tools-version:5.8          // 5.8 compiles on every recent Xcode
import PackageDescription

let (navNativeVersion, navNativeChecksum, navNativeRevision) =
    ("324.14.0-alpha.1",
     "b1767c0e0bd354c56007aae75843aca409e7ab0bb21384947e03d390a14366fc",
     "4b34fea46345862730d6e35709d693d1c3d36c50")

let mapsVersion: Version = "11.14.0-alpha.1"
// Snapshot versions that your app already uses
let snapshotCommon   = "24.14.0-SNAPSHOT-06-06--04-30.git-ae7b59c"
let snapshotCoreMaps = "11.14.0-SNAPSHOT-06-06--04-30.git-ae7b59c"
let snapshotMapsRev  = "de09f0f4bd20db55bf7e87fb7274135371281b6c" // full 40-char hash


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
    // NavNative stays version-locked
    .package(
        url: "https://github.com/mapbox/mapbox-navigation-native-ios.git",
        exact: Version(stringLiteral: navNativeVersion)
    ),

    // Mapbox packages all track branch “main” — same as your app target
    .package(
        url: "https://github.com/mapbox/mapbox-maps-ios.git",
        branch: "main"
    ),
    .package(
        url: "https://github.com/mapbox/mapbox-core-maps-ios.git",
        branch: "main"
    ),
    .package(
        url: "https://github.com/mapbox/mapbox-common-ios.git",
        branch: "main"
    ),

    // Unchanged third-party deps
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
