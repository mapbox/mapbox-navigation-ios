#!/usr/bin/swift sh

import Foundation
import XcodeProj // @tuist ~> 8.8.0
import PathKit

guard CommandLine.arguments.count == 3 else {
    let firstArgument = Path(CommandLine.arguments[0]).lastComponent
    fputs("Usage: \(firstArgument) <project_path> <expected_mapbox_navigation_version>\n", stderr)

    exit(1)
}

let projectPath = Path(CommandLine.arguments[1])
let xcodeproj = try XcodeProj(path: projectPath)

let expectedMapboxNavigationVersion = CommandLine.arguments[2]

guard let rootObject = xcodeproj.pbxproj.rootObject else {
    print("Root object should be valid")

    exit(1)
}

guard let package = rootObject.packages.first else {
    print("Package should be valid")

    exit(1)
}

guard case let .exact(actualMapboxNavigationVersion) = package.versionRequirement else {
    print("Resolved Mapbox Navigation version should be valid")

    exit(1)
}

if actualMapboxNavigationVersion != expectedMapboxNavigationVersion {
    print("Unexpected Mapbox Navigation version. Expected version: \(expectedMapboxNavigationVersion), actual version: \(actualMapboxNavigationVersion). Exiting...")

    exit(1)
}

print("Expected Mapbox Navigation version is correct and is: \(actualMapboxNavigationVersion)")
