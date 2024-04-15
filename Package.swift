// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MapboxNavigation",
    defaultLocalization: "en",
    platforms: [.iOS(.v12)],
    products: [
        .library(
            name: "MapboxCoreNavigation",
            targets: [
                "MapboxCoreNavigation",
            ]
        ),
        .library(
            name: "MapboxNavigation",
            targets: [
                "MapboxNavigation",
            ]
        )
    ],
    dependencies: [
        .package(name: "MapboxDirections", url: "https://github.com/mapbox/mapbox-directions-swift.git", from: "2.12.0"),
        .package(name: "MapboxNavigationNative", url: "https://github.com/mapbox/mapbox-navigation-native-ios.git", from: "204.0.1"),
        .package(name: "MapboxMaps", url: "https://github.com/mapbox/mapbox-maps-ios.git", from: "10.17.0"),
        .package(name: "Solar", url: "https://github.com/ceeK/Solar.git", from: "3.0.0"),
        .package(name: "MapboxSpeech", url: "https://github.com/mapbox/mapbox-speech-swift.git", from: "2.0.0"),
        .package(name: "CwlPreconditionTesting", url: "https://github.com/mattgallagher/CwlPreconditionTesting.git", from: "2.1.0"),
        .package(name: "SnapshotTesting", url: "https://github.com/pointfreeco/swift-snapshot-testing.git", .exact("1.9.0")),
        .package(name: "OHHTTPStubs", url: "https://github.com/AliSoftware/OHHTTPStubs.git", from: "9.1.0"),
    ],
    targets: [
        .target(
            name: "MapboxCoreNavigation",
            dependencies: [
                "MapboxDirections",
                "MapboxNavigationNative",
            ],
            exclude: ["Info.plist"],
            resources: [
                .copy("Resources/MBXInfo.plist"),
                .copy("Resources/PrivacyInfo.xcprivacy"),
            ]),
        .target(
            name: "MapboxNavigation",
            dependencies: [
                "MapboxCoreNavigation",
                "MapboxDirections",
                "MapboxMaps",
                "MapboxSpeech",
                "Solar",
            ],
            exclude: ["Info.plist"],
            resources: [
                .copy("Resources/MBXInfo.plist"),
                .copy("Resources/PrivacyInfo.xcprivacy")
            ]),
        .target(
            name: "TestHelper",
            dependencies: [
                "CwlPreconditionTesting",
                "MapboxCoreNavigation",
                "MapboxNavigation",
                "MapboxMaps",
            ],
            exclude: ["Info.plist"],
            resources: [
                .process("Fixtures"),
                .process("tiles"),
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
            name: "MapboxCoreNavigationTests",
            dependencies: ["TestHelper"],
            exclude: ["Info.plist"],
            resources: [
                .process("Fixtures"),
            ]
        ),
        .testTarget(
            name: "MapboxNavigationTests",
            dependencies: [
                "MapboxNavigation",
                "TestHelper",
                "OHHTTPStubs",
                "CarPlayTestHelper",
                "SnapshotTesting",
            ],
            exclude: [
                "Info.plist",
                "__Snapshots__", // Ignore snapshots folder
            ]
        ),
    ]
)
