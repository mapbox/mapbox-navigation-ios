// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

let roadCamerasEnabled = FileManager.default
    .fileExists(atPath: FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent(".mapbox-navigation-ios.navigation_sdks_private_beta")
        .path
    )

let (navNativeVersion, navNativeChecksum, navNativeRevision) = ("324.26.0", "ccd1b2ae45065d2877df07db1298d149f44780a350418732ca760842de2d4092", "7e7e05e2714c04f15ba2c994af63b2d0454358cb")
let mapsVersion: Version = "11.26.0"
let navsdkVersion: Version = "0.26.0"

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
            name: "MapboxDirections",
            targets: ["MapboxDirections"]
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
    ].updatedWithBetaFeatures(),
    dependencies: [
        .package(url: "https://github.com/mapbox/mapbox-navigation-native-ios.git", exact: Version(stringLiteral: navNativeVersion)),
        .package(url: "https://github.com/mapbox/mapbox-maps-ios.git", exact: mapsVersion),
        .package(url: "https://github.com/mapbox/turf-swift.git", exact: "4.0.0"),
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs", from: "9.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.18.1"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    ].updatedWithBetaFeatures(),
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
        .testTarget(
            name: "MapboxNavigationCoreIntegrationTests",
            dependencies: [
                "MapboxNavigationCore",
                "_MapboxNavigationTestHelpers",
                .product(name:  "OHHTTPStubsSwift", package: "OHHTTPStubs"),
            ],
            resources: [
                .copy("Fixtures"),
                .copy("AdasTilestore"),
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
    ].updatedWithBetaFeatures()
)

// MARK: - Beta

extension [PackageDescription.Product] {
    func updatedWithBetaFeatures() -> Self {
        var products = self
        if roadCamerasEnabled {
            products.append(
                .library(
                    name: "MapboxNavigationCppRoadCameras",
                    targets: [
                        "MapboxNavigationCppRoadCameras",
                    ]
                ),
            )
        }
        return products
    }
}

extension [PackageDescription.Target] {
    func updatedWithBetaFeatures() -> Self {
        var targets = self
        if roadCamerasEnabled {
            targets.append(
                .target(
                    name: "MapboxNavigationCppRoadCameras",
                    dependencies: [
                        .product(name: "MapboxNavigationCpp", package: "mapbox-navigation-cpp-ios"),
                        .product(name: "MapboxMaps", package: "mapbox-maps-ios"),
                    ]
                )
            )
        }
        return targets
    }
}

extension [PackageDescription.Package.Dependency] {
    func updatedWithBetaFeatures() -> Self {
        var dependencies = self
        if roadCamerasEnabled {
            dependencies.append(
                .package(url: "https://github.com/mapbox/mapbox-navigation-cpp-ios.git", exact: navsdkVersion),
            )
        }
        return dependencies
    }
}