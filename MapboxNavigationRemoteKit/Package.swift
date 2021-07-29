// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "MapboxNavigationRemoteKit",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(
            name: "MapboxNavigationRemoteKit",
            targets: ["MapboxNavigationRemoteKit"]),
        .library(
            name: "MapboxNavigationRemoteMultipeerKit",
            targets: ["MapboxNavigationRemoteMultipeerKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/insidegui/MultipeerKit.git", .branch("main")),
    ],
    targets: [
        .target(
            name: "MapboxNavigationRemoteKit",
            dependencies: []),
        .target(
            name: "MapboxNavigationRemoteMultipeerKit",
            dependencies: ["MultipeerKit"]),
    ]
)
