// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MapboxNavigation",
    defaultLocalization: "en",
    platforms: [.iOS(.v11)],
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
        .package(name: "MapboxDirections", url: "https://github.com/mapbox/mapbox-directions-swift.git", from: "2.7.0"),
        .package(name: "MapboxMobileEvents", url: "https://github.com/mapbox/mapbox-events-ios.git", from: "1.0.0"),
        .package(name: "MapboxNavigationNative", url: "https://github.com/mapbox/mapbox-navigation-native-ios.git", from: "115.0.0"),
        .package(name: "MapboxMaps", url: "https://github.com/mapbox/mapbox-maps-ios.git", from: "10.8.0"),
        .package(name: "Solar", url: "https://github.com/ceeK/Solar.git", from: "3.0.0"),
        .package(name: "MapboxSpeech", url: "https://github.com/mapbox/mapbox-speech-swift.git", from: "2.0.0"),
        .package(name: "Quick", url: "https://github.com/Quick/Quick.git", from: "3.1.2"),
        .package(name: "Nimble", url: "https://github.com/Quick/Nimble.git", from: "9.0.1"),
        .package(name: "SnapshotTesting", url: "https://github.com/pointfreeco/swift-snapshot-testing.git", .exact("1.9.0")),
        .package(name: "OHHTTPStubs", url: "https://github.com/AliSoftware/OHHTTPStubs.git", from: "9.1.0"),
    ],
    targets: [
        .target(
            name: "MapboxCoreNavigation",
            dependencies: [
                "MapboxDirections",
                "MapboxMobileEvents",
                "MapboxNavigationNative",
            ],
            exclude: ["Info.plist"],
            resources: [.copy("MBXInfo.plist")]),
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
            resources: [.copy("MBXInfo.plist")]),
        .target(
            name: "CTestHelper",
            dependencies: [
                "MapboxMobileEvents",
                "MapboxCoreNavigation",
            ]),
        .target(
            name: "TestHelper",
            dependencies: [
                "CTestHelper",
                "Quick",
                "Nimble",
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
                "Quick",
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
