// swift-tools-version:5.3
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
                "CMapboxCoreNavigation",
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
        .package(name: "MapboxDirections", url: "https://github.com/mapbox/mapbox-directions-swift.git", .exact("2.0.0-beta.3")),
        .package(name: "MapboxGeocoder", url: "https://github.com/mapbox/MapboxGeocoder.swift.git", from: "0.14.0"),
        .package(name: "MapboxMobileEvents", url: "https://github.com/mapbox/mapbox-events-ios.git", from: "1.0.0"),
        .package(name: "MapboxNavigationNative", url: "https://github.com/mapbox/mapbox-navigation-native-ios.git", from: "50.0.0"),
        .package(name: "MapboxMaps", url: "https://github.com/mapbox/mapbox-maps-ios.git", .exact("10.0.0-beta.21")),
        .package(name: "Solar", url: "https://github.com/ceeK/Solar.git", from: "2.2.0"),
        .package(name: "MapboxSpeech", url: "https://github.com/mapbox/mapbox-speech-swift.git", from: "2.0.0-alpha.1"),
        .package(name: "Quick", url: "https://github.com/Quick/Quick.git", from: "3.1.2"),
        .package(name: "Nimble", url: "https://github.com/Quick/Nimble.git", from: "9.0.1"),
        .package(name: "FBSnapshotTestCase", url: "https://github.com/alanzeino/ios-snapshot-test-case.git", .branch("master")),
        .package(name: "OHHTTPStubs", url: "https://github.com/AliSoftware/OHHTTPStubs.git", .upToNextMajor(from: "9.1.0")),
    ],
    targets: [
        .target(
            name: "MapboxCoreNavigation",
            dependencies: [
                "CMapboxCoreNavigation",
                "MapboxDirections",
                "MapboxMobileEvents",
                "MapboxNavigationNative",
            ],
            exclude: ["Info.plist"],
            resources: [.copy("MBXInfo.plist")]),
        .target(name: "CMapboxCoreNavigation"),
        .target(
            name: "MapboxNavigation",
            dependencies: [
                "MapboxCoreNavigation",
                "MapboxDirections",
                "MapboxGeocoder",
                "MapboxMaps",
                "MapboxSpeech",
                "Solar",
            ],
            exclude: ["Info.plist"],
            resources: [.copy("MBXInfo.plist")]),
        .target(
            name: "CTestHelper",
            dependencies: ["MapboxMobileEvents"]),
        .target(
            name: "TestHelper",
            dependencies: [
                "CTestHelper",
                "Quick",
                "Nimble",
                "MapboxCoreNavigation",
                "MapboxNavigation",
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
                "FBSnapshotTestCase",
                "Quick",
                "TestHelper",
                "OHHTTPStubs",
                "CarPlayTestHelper",
            ],
            exclude: [
                // Exclude snapshot testing tests because it is not clear how to configure FBSnapshotTestCase in SPM.
                "Info.plist",
                "MapboxNavigationTests-Bridging.h",
                "BottomBannerSnapshotTests.swift",
                "CarPlayCompassViewSnapshotTests.swift",
                "GuidanceCardsSnapshotTests.swift",
                "SnapshotTest+Mapbox.swift",
                "NavigationViewControllerTests.swift",
                "CarPlayManagerTests.swift", // There are issues with setting accessToken
                "LeaksSpec.swift", // UNUserNotificationCenter.current() crashes tests
                "InstructionsBannerViewSnapshotTests.swift",
                "ManeuverViewTests.swift",
                "ManeuverArrowTests.swift",
                "LaneTests.swift",
                "LaneViewTests.swift",
                "NavigationMapViewTests.swift",
            ],
            resources: [
                .process("Fixtures"),
                .process("ReferenceImages"),
                .process("ReferenceImages_64"),
                .process("Fixtures.xcassets"),
            ]
        ),
    ]
)
