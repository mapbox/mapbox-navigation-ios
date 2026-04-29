@testable import MapboxDirections
import Turf
import XCTest

class MatchOptionsTests: XCTestCase {
    func testCoding() {
        let options = testMatchOptions

        let encoded: Data = try! JSONEncoder().encode(options)
        let optionsString = String(data: encoded, encoding: .utf8)!

        let unarchivedOptions: MatchOptions = try! JSONDecoder().decode(
            MatchOptions.self,
            from: optionsString.data(using: .utf8)!
        )

        XCTAssertNotNil(unarchivedOptions)

        let coordinates = testCoordinates
        let unarchivedWaypoints = unarchivedOptions.waypoints
        XCTAssertEqual(unarchivedWaypoints.count, coordinates.count)
        XCTAssertEqual(unarchivedWaypoints[0].coordinate.latitude, coordinates[0].latitude)
        XCTAssertEqual(unarchivedWaypoints[0].coordinate.longitude, coordinates[0].longitude)
        XCTAssertEqual(unarchivedWaypoints[1].coordinate.latitude, coordinates[1].latitude)
        XCTAssertEqual(unarchivedWaypoints[1].coordinate.longitude, coordinates[1].longitude)
        XCTAssertEqual(unarchivedWaypoints[2].coordinate.latitude, coordinates[2].latitude)
        XCTAssertEqual(unarchivedWaypoints[2].coordinate.longitude, coordinates[2].longitude)

        XCTAssertEqual(unarchivedOptions.resamplesTraces, options.resamplesTraces)
    }

    func testURLCoding() throws {
        let originalOptions = testMatchOptions
        originalOptions.resamplesTraces = true

        for index in originalOptions.waypoints.indices {
            originalOptions.waypoints[index].separatesLegs = index != 1
            if originalOptions.waypoints[index].separatesLegs {
                originalOptions.waypoints[index].name = "name_\(index)"
                originalOptions.waypoints[index].targetCoordinate = originalOptions.waypoints[index].coordinate
            }
        }

        let url = Directions(credentials: BogusCredentials).url(forCalculating: originalOptions)

        guard let decodedOptions = MatchOptions(url: url) else {
            XCTFail("Could not decode `MatchOptions`")
            return
        }

        let decodedWaypoints = decodedOptions.waypoints
        XCTAssertEqual(decodedWaypoints.count, testCoordinates.count)
        XCTAssertEqual(decodedWaypoints[0].coordinate.latitude, testCoordinates[0].latitude)
        XCTAssertEqual(decodedWaypoints[0].coordinate.longitude, testCoordinates[0].longitude)
        XCTAssertEqual(decodedWaypoints[1].coordinate.latitude, testCoordinates[1].latitude)
        XCTAssertEqual(decodedWaypoints[1].coordinate.longitude, testCoordinates[1].longitude)
        XCTAssertEqual(decodedWaypoints[2].coordinate.latitude, testCoordinates[2].latitude)
        XCTAssertEqual(decodedWaypoints[2].coordinate.longitude, testCoordinates[2].longitude)

        zip(decodedWaypoints, originalOptions.waypoints).forEach {
            XCTAssertEqual($0.0.separatesLegs, $0.1.separatesLegs)
            XCTAssertEqual($0.0.name, $0.1.name)
        }

        XCTAssertEqual(decodedOptions.profileIdentifier, originalOptions.profileIdentifier)
        XCTAssertEqual(decodedOptions.resamplesTraces, originalOptions.resamplesTraces)

        let matchURL =
            try XCTUnwrap(
                URL(
                    string: "https://api.mapbox.com/matching/v5/mapbox/driving/-121.913565,37.331832;-121.916282,37.328707.json"
                )
            )
        XCTAssertNotNil(MatchOptions(url: matchURL))
        XCTAssertNil(RouteOptions(url: matchURL))
    }

    // MARK: API name-handling tests

    private static var testTracepoints: [Match.Tracepoint] {
        let one = LocationCoordinate2D(latitude: 39.27664, longitude: -84.41139)
        let two = LocationCoordinate2D(latitude: 39.27277, longitude: -84.41226)
        return [one, two].map { Match.Tracepoint(coordinate: $0, countOfAlternatives: 0, name: nil) }
    }

    func testWaypointSerialization() {
        var origin = Waypoint(coordinate: LocationCoordinate2D(latitude: 39.15031, longitude: -84.47182), name: "XU")
        origin.allowsSnappingToClosedRoad = true
        origin.allowsSnappingToStaticallyClosedRoad = true
        let destination = Waypoint(
            coordinate: LocationCoordinate2D(latitude: 39.12971, longitude: -84.51638),
            name: "UC"
        )
        let options = MatchOptions(waypoints: [origin, destination])
        XCTAssertEqual(options.coordinates, "-84.47182,39.15031;-84.51638,39.12971")
        XCTAssertTrue(options.urlQueryItems.contains(URLQueryItem(name: "waypoint_names", value: "XU;UC")))

        options.waypoints[0].heading = 90.0
        options.waypoints[0].headingAccuracy = 1.0
        XCTAssertFalse(options.urlQueryItems.map { $0.name }.contains("bearings"))
        XCTAssertFalse(options.urlQueryItems.map { $0.name }.contains("snapping_include_static_closures"))
        XCTAssertFalse(options.urlQueryItems.map { $0.name }.contains("snapping_include_closures"))
    }

    func testRouteOptionsConvertedFromMatchOptions() {
        let matchOptions = testMatchOptions
        matchOptions.waypoints[0].heading = 90.0
        matchOptions.waypoints[0].headingAccuracy = 1.0
        let subject = RouteOptions(matchOptions: matchOptions)

        XCTAssertEqual(subject.includesSteps, matchOptions.includesSteps)
        XCTAssertEqual(subject.shapeFormat, matchOptions.shapeFormat)
        XCTAssertEqual(subject.attributeOptions, matchOptions.attributeOptions)
        XCTAssertEqual(subject.routeShapeResolution, matchOptions.routeShapeResolution)
        XCTAssertEqual(subject.locale, matchOptions.locale)
        XCTAssertEqual(subject.includesSpokenInstructions, matchOptions.includesSpokenInstructions)
        XCTAssertEqual(subject.includesVisualInstructions, matchOptions.includesVisualInstructions)
        XCTAssertEqual(subject.bearings, "90.0,1.0;;")
    }

    // MARK: Attribute Options URL Query Item Tests

    func testAttributeOptionsWithFullResolutionAndTrafficProfile() {
        // Happy path: full resolution with automobileAvoidingTraffic profile should include all supported attributes
        let options = MatchOptions(coordinates: testCoordinates, profileIdentifier: .automobileAvoidingTraffic)
        options.routeShapeResolution = .full
        options.attributeOptions = [
            .distance,
            .expectedTravelTime,
            .speed,
            .congestionLevel,
            .maximumSpeedLimit,
            .numericCongestionLevel,
        ]

        let annotationsItem = options.urlQueryItems.first { $0.name == "annotations" }
        XCTAssertNotNil(annotationsItem, "Annotations query item should be present")

        let annotationsValue = annotationsItem?.value ?? ""
        XCTAssertTrue(annotationsValue.contains("distance"), "Should contain distance")
        XCTAssertTrue(annotationsValue.contains("duration"), "Should contain duration (expectedTravelTime)")
        XCTAssertTrue(annotationsValue.contains("speed"), "Should contain speed")
        XCTAssertTrue(annotationsValue.contains("congestion"), "Should contain congestion")
        XCTAssertTrue(annotationsValue.contains("maxspeed"), "Should contain maxspeed")
        XCTAssertTrue(annotationsValue.contains("congestion_numeric"), "Should contain congestion_numeric")
    }

    func testAttributeOptionsDoesNotIncludeClosures() {
        // MatchOptions should NOT support closures attribute (unlike RouteOptions)
        let options = MatchOptions(coordinates: testCoordinates, profileIdentifier: .automobileAvoidingTraffic)
        options.routeShapeResolution = .full
        options.attributeOptions = [
            .distance,
            .closures, // This should be filtered out for MatchOptions
        ]

        let annotationsItem = options.urlQueryItems.first { $0.name == "annotations" }
        XCTAssertNotNil(annotationsItem, "Annotations query item should be present")

        let annotationsValue = annotationsItem?.value ?? ""
        XCTAssertTrue(annotationsValue.contains("distance"), "Should contain distance")
        XCTAssertFalse(annotationsValue.contains("closure"), "Should NOT contain closure for MatchOptions")
    }

    func testAttributeOptionsFilteredForNonTrafficProfile() {
        // Test that traffic-specific attributes are filtered out for non-traffic profiles
        let options = MatchOptions(coordinates: testCoordinates, profileIdentifier: .automobile)
        options.routeShapeResolution = .full
        options.attributeOptions = [
            .distance,
            .expectedTravelTime,
            .speed,
            .congestionLevel,
            .maximumSpeedLimit,
            .numericCongestionLevel,
        ]

        let annotationsItem = options.urlQueryItems.first { $0.name == "annotations" }
        XCTAssertNotNil(annotationsItem, "Annotations query item should be present")

        let annotationsValue = annotationsItem?.value ?? ""
        // These should be included for automobile profile
        XCTAssertTrue(annotationsValue.contains("distance"), "Should contain distance")
        XCTAssertTrue(annotationsValue.contains("duration"), "Should contain duration")
        XCTAssertTrue(annotationsValue.contains("speed"), "Should contain speed")
        XCTAssertTrue(annotationsValue.contains("maxspeed"), "Should contain maxspeed for automobile profile")

        // These should be filtered out for non-traffic profiles
        XCTAssertFalse(annotationsValue.contains("congestion"), "Should NOT contain congestion")
        XCTAssertFalse(annotationsValue.contains("congestion_numeric"), "Should NOT contain congestion_numeric")
    }

    func testAttributeOptionsFilteredForNonAutomobileProfile() {
        // Test that automobile-specific attributes are filtered out for non-automobile profiles
        let options = MatchOptions(coordinates: testCoordinates, profileIdentifier: .walking)
        options.routeShapeResolution = .full
        options.attributeOptions = [
            .distance,
            .expectedTravelTime,
            .speed,
            .maximumSpeedLimit,
        ]

        let annotationsItem = options.urlQueryItems.first { $0.name == "annotations" }
        XCTAssertNotNil(annotationsItem, "Annotations query item should be present")

        let annotationsValue = annotationsItem?.value ?? ""
        // These should be included for walking profile
        XCTAssertTrue(annotationsValue.contains("distance"), "Should contain distance")
        XCTAssertTrue(annotationsValue.contains("duration"), "Should contain duration")
        XCTAssertTrue(annotationsValue.contains("speed"), "Should contain speed")

        // maximumSpeedLimit should be filtered out for non-automobile profiles
        XCTAssertFalse(annotationsValue.contains("maxspeed"), "Should NOT contain maxspeed for walking profile")
    }

    func testAttributeOptionsWithLowResolution() {
        // Test that annotations are omitted when routeShapeResolution is not .full
        let options = MatchOptions(coordinates: testCoordinates, profileIdentifier: .automobileAvoidingTraffic)
        options.routeShapeResolution = .low
        options.attributeOptions = [
            .congestionLevel,
            .distance,
            .expectedTravelTime,
        ]

        let annotationsItem = options.urlQueryItems.first { $0.name == "annotations" }
        XCTAssertNil(annotationsItem, "Annotations query item should be nil for low resolution")
    }

    func testAttributeOptionsWithSimplifiedResolution() {
        // Test that annotations are omitted when routeShapeResolution is .low (simplified)
        let options = MatchOptions(coordinates: testCoordinates, profileIdentifier: .automobileAvoidingTraffic)
        options.routeShapeResolution = .low
        options.attributeOptions = [.congestionLevel, .distance]

        let annotationsItem = options.urlQueryItems.first { $0.name == "annotations" }
        XCTAssertNil(annotationsItem, "Annotations should be omitted for simplified resolution")
    }

    func testAttributeOptionsWithNoResolution() {
        // Test that annotations are omitted when routeShapeResolution is .none
        let options = MatchOptions(coordinates: testCoordinates, profileIdentifier: .automobileAvoidingTraffic)
        options.routeShapeResolution = .none
        options.attributeOptions = [.congestionLevel]

        let annotationsItem = options.urlQueryItems.first { $0.name == "annotations" }
        XCTAssertNil(annotationsItem, "Annotations should be omitted when resolution is none")
    }

    func testAttributeOptionsEmpty() {
        // Test that no annotations query item is present when attributeOptions is empty
        let options = MatchOptions(coordinates: testCoordinates, profileIdentifier: .automobileAvoidingTraffic)
        options.routeShapeResolution = .full
        options.attributeOptions = []

        let annotationsItem = options.urlQueryItems.first { $0.name == "annotations" }
        XCTAssertNil(annotationsItem, "Annotations query item should be nil when attributeOptions is empty")
    }

    func testAttributeOptionsWithCyclingProfile() {
        // Test attribute options for cycling profile
        let options = MatchOptions(coordinates: testCoordinates, profileIdentifier: .cycling)
        options.routeShapeResolution = .full
        options.attributeOptions = [
            .distance,
            .expectedTravelTime,
            .speed,
            .maximumSpeedLimit,
            .congestionLevel,
        ]

        let annotationsItem = options.urlQueryItems.first { $0.name == "annotations" }
        XCTAssertNotNil(annotationsItem, "Annotations query item should be present")

        let annotationsValue = annotationsItem?.value ?? ""
        // Basic attributes should be included
        XCTAssertTrue(annotationsValue.contains("distance"), "Should contain distance")
        XCTAssertTrue(annotationsValue.contains("duration"), "Should contain duration")
        XCTAssertTrue(annotationsValue.contains("speed"), "Should contain speed")

        // Automobile-specific attributes should be filtered out
        XCTAssertFalse(annotationsValue.contains("maxspeed"), "Should NOT contain maxspeed for cycling")
        XCTAssertFalse(annotationsValue.contains("congestion"), "Should NOT contain congestion for cycling")
    }

    func testAttributeOptionsWithCustomProfile() {
        // Test that custom profiles behave correctly
        let customAutomobileProfile = ProfileIdentifier(rawValue: "custom/driving")
        let options = MatchOptions(coordinates: testCoordinates, profileIdentifier: customAutomobileProfile)
        options.routeShapeResolution = .full
        options.attributeOptions = [
            .distance,
            .expectedTravelTime,
            .speed,
            .maximumSpeedLimit,
        ]

        let annotationsItem = options.urlQueryItems.first { $0.name == "annotations" }
        XCTAssertNotNil(annotationsItem, "Annotations query item should be present")

        let annotationsValue = annotationsItem?.value ?? ""
        XCTAssertTrue(annotationsValue.contains("distance"), "Should contain distance")
        XCTAssertTrue(annotationsValue.contains("duration"), "Should contain duration")
        XCTAssertTrue(annotationsValue.contains("speed"), "Should contain speed")
        XCTAssertTrue(annotationsValue.contains("maxspeed"), "Should contain maxspeed for custom automobile profile")
    }

    func testAttributeOptionsWithCustomOption() {
        // Test that custom attributes are handled correctly
        let options = MatchOptions(coordinates: testCoordinates, profileIdentifier: .automobileAvoidingTraffic)
        options.routeShapeResolution = .full
        var customAttributeOptions = AttributeOptions(rawValue: 1 << 30)
        customAttributeOptions.customOptionsByRawValue[1 << 30] = "customOption"
        options.attributeOptions = customAttributeOptions

        let annotationsItem = options.urlQueryItems.first { $0.name == "annotations" }
        // customOption is not in the supported options list for MatchOptions, so it should fall through
        // to the default case and be included as-is
        XCTAssertNotNil(annotationsItem, "Annotations query item should be present")
    }

    func testAttributeOptionsCombinedSupportedAndCustom() {
        // Test that custom (unsupported) attributes are preserved alongside supported ones
        let options = MatchOptions(coordinates: testCoordinates, profileIdentifier: .automobileAvoidingTraffic)
        options.routeShapeResolution = .full
        var customAttributeOption = AttributeOptions(rawValue: 1 << 30)
        customAttributeOption.customOptionsByRawValue[1 << 30] = "customOption"
        options.attributeOptions = [
            .distance,
            .congestionLevel,
            customAttributeOption, // Not in the standard supported list for MatchOptions
        ]

        let annotationsItem = options.urlQueryItems.first { $0.name == "annotations" }
        XCTAssertNotNil(annotationsItem, "Annotations query item should be present")

        let annotationsValue = annotationsItem?.value ?? ""
        XCTAssertTrue(annotationsValue.contains("distance"), "Should contain distance")
        XCTAssertTrue(annotationsValue.contains("congestion"), "Should contain congestion")
        // customOption should be included as a custom option
        XCTAssertTrue(annotationsValue.contains("customOption"), "Should contain customOption")
    }

    func testAttributeOptionsWithCustomTrafficProfile() {
        // Test custom traffic profiles filter attributes correctly
        let customTrafficProfile = ProfileIdentifier(rawValue: "custom/driving-traffic")
        let options = MatchOptions(coordinates: testCoordinates, profileIdentifier: customTrafficProfile)
        options.routeShapeResolution = .full
        options.attributeOptions = [
            .distance,
            .congestionLevel,
            .numericCongestionLevel,
            .maximumSpeedLimit,
        ]

        let annotationsItem = options.urlQueryItems.first { $0.name == "annotations" }
        XCTAssertNotNil(annotationsItem, "Annotations query item should be present")

        let annotationsValue = annotationsItem?.value ?? ""
        // All traffic-related attributes should be included for custom traffic profile
        XCTAssertTrue(annotationsValue.contains("distance"), "Should contain distance")
        XCTAssertTrue(annotationsValue.contains("congestion"), "Should contain congestion for traffic profile")
        XCTAssertTrue(
            annotationsValue.contains("congestion_numeric"),
            "Should contain congestion_numeric for traffic profile"
        )
        XCTAssertTrue(annotationsValue.contains("maxspeed"), "Should contain maxspeed for traffic profile")
    }
}

private let testCoordinates = [
    LocationCoordinate2D(latitude: 52.5109, longitude: 13.4301),
    LocationCoordinate2D(latitude: 52.5080, longitude: 13.4265),
    LocationCoordinate2D(latitude: 52.5021, longitude: 13.4316),
]

var testMatchOptions: MatchOptions {
    let opts = MatchOptions(coordinates: testCoordinates, profileIdentifier: .automobileAvoidingTraffic)
    opts.resamplesTraces = true
    return opts
}
