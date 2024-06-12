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
        let origin = Waypoint(coordinate: LocationCoordinate2D(latitude: 39.15031, longitude: -84.47182), name: "XU")
        let destination = Waypoint(
            coordinate: LocationCoordinate2D(latitude: 39.12971, longitude: -84.51638),
            name: "UC"
        )
        let options = MatchOptions(waypoints: [origin, destination])
        XCTAssertEqual(options.coordinates, "-84.47182,39.15031;-84.51638,39.12971")
        XCTAssertTrue(options.urlQueryItems.contains(URLQueryItem(name: "waypoint_names", value: "XU;UC")))
    }

    func testRouteOptionsConvertedFromMatchOptions() {
        let matchOpts = testMatchOptions
        let subject = RouteOptions(matchOptions: matchOpts)

        XCTAssertEqual(subject.includesSteps, matchOpts.includesSteps)
        XCTAssertEqual(subject.shapeFormat, matchOpts.shapeFormat)
        XCTAssertEqual(subject.attributeOptions, matchOpts.attributeOptions)
        XCTAssertEqual(subject.routeShapeResolution, matchOpts.routeShapeResolution)
        XCTAssertEqual(subject.locale, matchOpts.locale)
        XCTAssertEqual(subject.includesSpokenInstructions, matchOpts.includesSpokenInstructions)
        XCTAssertEqual(subject.includesVisualInstructions, matchOpts.includesVisualInstructions)
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
