// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let (navNativeVersion, navNativeChecksum, navNativeRevision) = ("323.0.0", "4a806426df5f97c8f8a472d4ea44f4559a0ca8dc9cd7d15b51d341a81d1680b2", "9e90c87316b7223c66b5013a2afcc7644610c15d")
let mapsVersion: Version = "11.10.0"

let mapboxApiDownloads = "https://api.mapbox.com/downloads/v2"

// This flag controls how the NavSDK will be resolved.
enum BuildMode {
    /// The NavSDK and its deps will be built from source.
    case allSources

    /// The NavSDK itself will be built from source, but all dependencies are taken as xcframeworks.
    /// Usually, you don't want to use this mode directly, it's only used to build the release artifacts.
    case binaryDeps

    /// The NavSDK and all dependencies are taken as xcframeworks, this is how a customer would use our SDK.
    /// Prerequisite: prebuilt xcframeworks should be located in XCFrameworks folder.
    case allBinaries
}

let buildMode = BuildMode.binaryDeps

let package = Package(
    name: "MapboxNavigation",
    defaultLocalization: "en",
    // The Nav SDK doesn't support macOS but declared the minimum macOS requirement with downstream deps to enable `swift run` cli tools
    platforms: [.iOS(.v14), .macOS(.v10_15)],
    products: getProducts(),
    dependencies: getPackageDependencies(),
    targets: getMainTargets() + getAdditionalTargets()
)

func getProducts() -> [Product] {
    switch buildMode {
    case .allSources:
        return [
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
                targets: ["MapboxDirectionsCLI"]
            ),
        ]
    case .binaryDeps:
        return [
            .library(
                name: "MapboxNavigationUIKit",
                targets: ["MapboxNavigationUIKit"]
            ),
            .library(
                name: "MapboxNavigationCore",
                targets: ["MapboxNavigationCore"]
            ),
        ]
    case .allBinaries:
        return [
            .library(
                name: "MapboxNavigationUIKit",
                targets: [
                    "MapboxNavigationUIKitWrapper"
                ]
            ),
            .library(
                name: "MapboxNavigationCore",
                targets: [
                    "MapboxNavigationCoreWrapper"
                ]
            ),
        ]
    }
}

func getPackageDependencies() -> [Package.Dependency] {
    let baseDependencies: [Package.Dependency] = [
                .package(url: "https://github.com/mapbox/mapbox-navigation-native-ios.git", exact: Version(stringLiteral: navNativeVersion)),
    ]
    switch buildMode {
    case .allBinaries:
        return baseDependencies
    case .binaryDeps:
        return [
            .package(path: "../FrameworkDistribution/BinaryDependencies")
        ]
    case .allSources:
        return baseDependencies + [
            .package(url: "https://github.com/mapbox/mapbox-maps-ios.git", exact: mapsVersion),
            .package(url: "https://github.com/mapbox/turf-swift.git", exact: "4.0.0"),
            .package(url: "https://github.com/AliSoftware/OHHTTPStubs", from: "9.1.0"),
            .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", exact: "1.12.0"),
            .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        ]
    }
}

func getMainTargets() -> [Target] {
    switch buildMode {
    case .allSources, .binaryDeps:
        return [
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
                    "MapboxDirections",
                    buildMode == .allSources ? .product(
                        name: "MapboxNavigationNative",
                        package: "mapbox-navigation-native-ios"
                    ) : "MapboxNavigationNative",
                    .product(
                        name: "MapboxMaps",
                        package: buildMode == .allSources ? "mapbox-maps-ios" : "BinaryDependencies"
                    ),
                ],
                resources: [
                    .process("Resources")
                ]
            ),
            .target(
                name: "MapboxDirections",
                dependencies: [
                    .product(name: "Turf", package: buildMode == .allSources ? "turf-swift" : "BinaryDependencies"),
                ]
            ),
        ]
    case .allBinaries:
        let binaryNames = [
            "_MapboxNavigationHelpers",
            "MapboxCoreMaps",
            "MapboxDirections",
            "MapboxMaps",
            "MapboxNavigationCore",
            "MapboxNavigationUIKit"
        ]

        let externalDependencies: [Target.Dependency] = [
            .product(name: "MapboxNavigationNative", package: "mapbox-navigation-native-ios"),
        ]

        return binaryNames.map { name in
            .binaryTarget(name: name, path: "./XCFrameworks/\(name).xcframework")
        } + [
            .target(
                name: "MapboxNavigationCoreWrapper",
                dependencies: externalDependencies +
                    binaryNames.filter { $0 != "MapboxNavigationUIKit" }
                    .map { .byName(name: $0) },
                path: "Sources/.empty/MapboxNavigationCoreWrapper"
            ),
            .target(
                name: "MapboxNavigationUIKitWrapper",
                dependencies: [
                    "MapboxNavigationCoreWrapper"
                ],
                path: "Sources/.empty/MapboxNavigationUIKitWrapper"
            ),
        ]
    }
}

func getTestTargets() -> [Target] {
    return [
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
                .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs"),
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
                .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs"),
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
    ]
}

func getAdditionalTargets() -> [Target] {
    switch buildMode {
    case .allBinaries:
        return []
    case .allSources:
        return getTestTargets() + [
            .executableTarget(
                name: "MapboxDirectionsCLI",
                dependencies: [
                    "MapboxDirections",
                    .product(name: "ArgumentParser", package: "swift-argument-parser")
                ]
            )
        ]
    case .binaryDeps:
        return [
            navNativeBinaryTarget(
                name: "MapboxNavigationNative",
                version: navNativeVersion,
                checksum: navNativeChecksum
            )
        ]
    }
}

private func navNativeBinaryTarget(name: String, version: String, checksum: String) -> Target {
    let releaseType = version.contains("SNAPSHOT") ? "snapshots" : "releases"
    let url = "\(mapboxApiDownloads)/dash-native/\(releaseType)/ios/packages/\(version)/MapboxNavigationNative.xcframework.zip"
    return .binaryTarget(name: name, url: url, checksum: checksum)
}
