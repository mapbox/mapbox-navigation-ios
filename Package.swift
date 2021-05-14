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
            ]),
        .library(
            name: "MapboxNavigation",
            targets: [
                "MapboxNavigation"
            ])
    ],
    dependencies: [
        .package(name: "MapboxDirections", url: "https://github.com/mapbox/mapbox-directions-swift.git", .exact("2.0.0-beta.3")),
        .package(name: "MapboxGeocoder", url: "https://github.com/mapbox/MapboxGeocoder.swift.git", from: "0.14.0"),
        .package(name: "MapboxMobileEvents", url: "https://github.com/mapbox/mapbox-events-ios.git", from: "0.10.8"),
        .package(name: "MapboxNavigationNative", url: "https://github.com/mapbox/mapbox-navigation-native-ios.git", from: "49.0.0"),
        .package(name: "MapboxMaps", url: "https://github.com/mapbox/mapbox-maps-ios.git", .exact("10.0.0-beta.19.1")),
        .package(name: "Solar", url: "https://github.com/ceeK/Solar.git", from: "2.2.0"),
        .package(name: "MapboxSpeech", url: "https://github.com/mapbox/mapbox-speech-swift.git", from: "2.0.0-alpha.1"),
        .package(name: "Quick", url: "https://github.com/Quick/Quick.git", from: "2.0.0"),
        .package(name: "Nimble", url: "https://github.com/Quick/Nimble.git", from: "8.0.0"),
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
            resources: [.process("Fixtures")]),
        .testTarget(
            name: "MapboxCoreNavigationTests",
            dependencies: ["TestHelper"],
            exclude: ["Info.plist"]),
    ]
)
