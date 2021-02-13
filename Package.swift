// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MapboxNavigation",
    defaultLocalization: "en",
    platforms: [.iOS(.v10)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "MapboxCoreNavigation",
            targets: [
                "CMapboxCoreNavigation",
                "MapboxCoreNavigation",
            ]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(name: "MapboxAccounts", url: "https://github.com/mapbox/mapbox-accounts-ios.git", from: "2.3.1"),
        .package(name: "MapboxCommon", url: "https://github.com/mapbox/mapbox-common-ios.git", from: "9.2.0"),
        .package(name: "MapboxDirections", url: "https://github.com/mapbox/mapbox-directions-swift.git", from: "1.2.0"),
        .package(name: "MapboxMobileEvents", url: "https://github.com/mapbox/mapbox-events-ios.git", from: "0.10.6"),
        .package(name: "MapboxNavigationNative", url: "https://github.com/mapbox/mapbox-navigation-native-ios.git", from: "31.0.0"),
        .package(name: "Quick", url: "https://github.com/Quick/Quick.git", from: "2.0.0"),
        .package(name: "Nimble", url: "https://github.com/Quick/Nimble.git", from: "8.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "MapboxCoreNavigation",
            dependencies: [
                "CMapboxCoreNavigation",
                "MapboxAccounts",
                "MapboxCommon",
                "MapboxDirections",
                "MapboxMobileEvents",
                "MapboxNavigationNative",
            ],
            exclude: ["Info.plist"]),
        .target(
            name: "CMapboxCoreNavigation",
            dependencies: [
                "MapboxAccounts",
            ]),
        .testTarget(
            name: "MapboxCoreNavigationTests",
            dependencies: [
                "MapboxCoreNavigation",
                "Quick",
                "Nimble",
            ],
            exclude: ["Info.plist"],
            resources: [
                .process("Fixtures"),
            ]),
    ]
)

