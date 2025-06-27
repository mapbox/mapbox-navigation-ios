// swift-tools-version:5.8
import PackageDescription

let navNativeVersion = "324.14.0-alpha.1"

let package = Package(
    name: "MapboxNavigation",
    defaultLocalization: "en",
    platforms: [.iOS(.v14), .macOS(.v10_15)],

    products: [
        .library(name: "MapboxNavigationUIKit", targets: ["MapboxNavigationUIKit"]),
        .library(name: "MapboxNavigationCore",   targets: ["MapboxNavigationCore"]),
        .library(name: "_MapboxNavigationLocalization", targets: ["_MapboxNavigationLocalization"]),
        .library(name: "_MapboxNavigationTestKit",      targets: ["_MapboxNavigationTestKit"]),
        .executable(name: "mapbox-directions-swift", targets: ["MapboxDirectionsCLI"]),
    ],

    dependencies: [
        // NavNative stays pinned
        .package(
            url: "https://github.com/mapbox/mapbox-navigation-native-ios.git",
            branch: "main"
        ),

        // All Mapbox packages follow the SAME branch as your app
        .package(url: "https://github.com/mapbox/mapbox-maps-ios.git",
                 branch: "main"),
        .package(url: "https://github.com/mapbox/mapbox-core-maps-ios.git",
                 branch: "main"),
),

        // Third-party deps untouched
        .package(url: "https://github.com/mapbox/turf-swift.git",               exact: "4.0.0"),
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs",             from: "9.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git",
                 from: "1.18.1"),
        .package(url: "https://github.com/apple/swift-argument-parser",         from: "1.0.0"),
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
