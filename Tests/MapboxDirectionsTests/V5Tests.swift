import XCTest
#if !os(Linux)
import CoreLocation
import OHHTTPStubs
#if SWIFT_PACKAGE
import OHHTTPStubsSwift
#endif
@testable import MapboxDirections

class V5Tests: XCTestCase {
    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    typealias JSONTransformer = (JSONDictionary) -> JSONDictionary

    @MainActor
    func test(
        shapeFormat: RouteShapeFormat,
        transformer: JSONTransformer? = nil,
        filePath: String? = nil
    ) throws {
        let expectation = expectation(description: "calculating directions should return results")

        let queryParams: [String: String?] = [
            "alternatives": "true",
            "geometries": shapeFormat.rawValue,
            "overview": "full",
            "steps": "true",
            "continue_straight": "true",
            "access_token": BogusToken,
        ]
        stub(
            condition: isHost("api.mapbox.com")
                && isPath("/directions/v5/mapbox/driving/-122.42,37.78;-77.03,38.91")
                && containsQueryParams(queryParams)
        ) { _ in
            let path = Bundle.module.path(
                forResource: filePath ?? "v5_driving_dc_\(shapeFormat.rawValue)",
                ofType: "json"
            )
            let filePath = URL(fileURLWithPath: path!)
            let data = try! Data(contentsOf: filePath, options: [])
            let jsonObject = try! JSONSerialization.jsonObject(with: data, options: [])
            let transformedData = transformer?(jsonObject as! JSONDictionary) ?? jsonObject
            return HTTPStubsResponse(
                jsonObject: transformedData,
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            )
        }

        let options = RouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 37.78, longitude: -122.42),
            CLLocationCoordinate2D(latitude: 38.91, longitude: -77.03),
        ])
        XCTAssertEqual(options.shapeFormat, .polyline, "Route shape format should be Polyline by default.")
        options.shapeFormat = shapeFormat
        options.includesSteps = true
        options.includesAlternativeRoutes = true
        options.routeShapeResolution = .full
        options.includesVisualInstructions = true
        options.includesSpokenInstructions = true
        options.locale = Locale(identifier: "en_US")
        options.includesExitRoundaboutManeuver = true
        var waypoints: [Waypoint]?
        var routes: [Route]?
        let task = Directions(credentials: BogusCredentials).calculate(options) { result in
            switch result {
            case .failure(let error):
                XCTFail("Error: \(error)")
            case .success(let resp):
                Task { @MainActor [r = resp.routes, w = resp.waypoints] in
                    routes = r
                    waypoints = w
                    expectation.fulfill()
                }
            }
        }
        XCTAssertNotNil(task)

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error, "Error: \(error!)")
            XCTAssertEqual(task.state, .completed)
        }
        XCTAssertEqual(waypoints?.count, 2)
        XCTAssertEqual(routes?.count, 2)

        try test(XCTUnwrap(XCTUnwrap(routes).first))
    }

    func test(_ route: Route?) {
        XCTAssertNotNil(route)
        guard let route else {
            return
        }

        XCTAssertNotNil(route.shape)
        XCTAssertEqual(route.shape!.coordinates.count, 30097)
        XCTAssertEqual(route.speechLocale?.identifier, "en-US")

        // confirming actual decoded values is important because the Directions API
        // uses an atypical precision level for polyline encoding
        XCTAssertEqual(route.shape?.coordinates.first?.latitude ?? 0, 38, accuracy: 1)
        XCTAssertEqual(route.shape?.coordinates.first?.longitude ?? 0, -122, accuracy: 1)
        XCTAssertEqual(route.legs.count, 1)

        XCTAssertEqual(route.legs.count, 1)
        let leg = route.legs.first
        XCTAssertEqual(leg?.name, "Dwight D. Eisenhower Highway, I-80")
        XCTAssertEqual(leg?.steps.count, 59)

        // The Carquinez Bridge is tolled.
        let tolledStep = leg?.steps[5]
        let tolledStepIntersections = tolledStep?.intersections
        XCTAssertNotNil(tolledStepIntersections)
        let tolledIntersection = tolledStepIntersections?[38]
        let roadClasses = tolledIntersection?.outletRoadClasses
        XCTAssertNotNil(roadClasses)
        XCTAssertEqual(roadClasses, [.toll, .motorway])

        let step = leg?.steps[48]
        XCTAssertEqual(step?.distance ?? 0, 621, accuracy: 1)
        XCTAssertEqual(step?.expectedTravelTime ?? 0, 31, accuracy: 1)
        XCTAssertEqual(step?.instructions, "Take exit 43-44 towards VA 193: George Washington Memorial Parkway")

        XCTAssertNil(step?.names)
        XCTAssertEqual(step?.destinationCodes, ["VA 193"])
        XCTAssertEqual(step?.destinations, ["George Washington Memorial Parkway", "Washington", "Georgetown Pike"])
        XCTAssertEqual(step?.maneuverType, .takeOffRamp)
        XCTAssertEqual(step?.maneuverDirection, .slightRight)
        XCTAssertEqual(step?.initialHeading, 192)
        XCTAssertEqual(step?.finalHeading, 202)

        XCTAssertNotNil(step?.shape)
        XCTAssertEqual(step?.shape?.coordinates.count, 13)
        XCTAssertEqual(step?.shape?.coordinates.first?.latitude ?? 0, 38.9667, accuracy: 1e-4)
        XCTAssertEqual(step?.shape?.coordinates.first?.longitude ?? 0, -77.1802, accuracy: 1e-4)

        XCTAssertEqual(leg?.steps[32].names, nil)
        XCTAssertEqual(leg?.steps[32].codes, ["I-80"])
        XCTAssertEqual(leg?.steps[32].destinationCodes, ["I-80 East", "I-90"])
        XCTAssertEqual(leg?.steps[32].destinations, ["Toll Road"])

        XCTAssertEqual(leg?.steps[35].names, ["Ohio Turnpike"])
        XCTAssertEqual(leg?.steps[35].codes, ["I-80 East"])
        XCTAssertNil(leg?.steps[35].destinationCodes)
        XCTAssertNil(leg?.steps[35].destinations)

        let intersections = leg?.steps[4].intersections
        XCTAssertNotNil(intersections)
        XCTAssertEqual(intersections?.count, 29)
        let intersection = intersections?[0]
        XCTAssertEqual(intersection?.outletIndexes, IndexSet([0, 1]))
        XCTAssertEqual(intersection?.approachIndex, 2)
        XCTAssertEqual(intersection?.outletIndex, 0)
        XCTAssertEqual(intersection?.headings, [105, 135, 285])
        XCTAssertEqual(intersection?.location.latitude ?? 0, 37.7691, accuracy: 1e-4)
        XCTAssertEqual(intersection?.location.longitude ?? 0, -122.4092, accuracy: 1e-4)
        XCTAssertEqual(intersection?.usableApproachLanes, IndexSet([0, 1]))
        XCTAssertNotNil(intersection?.approachLanes)
        XCTAssertEqual(intersection?.approachLanes?.count, 3)
        XCTAssertEqual(intersection?.approachLanes?[1], [.slightLeft, .slightRight])

        XCTAssertEqual(leg?.steps[58].names, ["Logan Circle Northwest"])
        XCTAssertNil(leg?.steps[58].exitNames)
        XCTAssertNil(leg?.steps[58].codes)
        XCTAssertNil(leg?.steps[58].destinationCodes)
        XCTAssertNil(leg?.steps[58].destinations)
    }

    @MainActor
    func testGeoJSON() throws {
        XCTAssertEqual(RouteShapeFormat.geoJSON.rawValue, "geojson")
        try test(shapeFormat: .geoJSON)
    }

    @MainActor
    func testPolyline() throws {
        XCTAssertEqual(RouteShapeFormat.polyline.rawValue, "polyline")
        try test(shapeFormat: .polyline)
    }

    @MainActor
    func testPolyline6() throws {
        XCTAssertEqual(RouteShapeFormat.polyline6.rawValue, "polyline6")

        // Transform polyline5 to polyline6
        let transformer: JSONTransformer = { json in
            var transformed = json
            var route = (transformed["routes"] as! [JSONDictionary])[0]
            let polyline = route["geometry"] as! String

            let decodedCoordinates: [CLLocationCoordinate2D] = decodePolyline(polyline, precision: 1e5)!
            route["geometry"] = Polyline(coordinates: decodedCoordinates, levels: nil, precision: 1e6).encodedPolyline

            let legs = route["legs"] as! [JSONDictionary]
            var newLegs = [JSONDictionary]()
            for var leg in legs {
                let steps = leg["steps"] as! [JSONDictionary]

                var newSteps = [JSONDictionary]()
                for var step in steps {
                    let geometry = step["geometry"] as! String
                    let coords: [CLLocationCoordinate2D] = decodePolyline(geometry, precision: 1e5)!
                    step["geometry"] = Polyline(coordinates: coords, precision: 1e6).encodedPolyline
                    newSteps.append(step)
                }

                leg["steps"] = newSteps
                newLegs.append(leg)
            }

            route["legs"] = newLegs

            let secondRoute = (json["routes"] as! [JSONDictionary])[1]
            transformed["routes"] = [route, secondRoute]

            return transformed
        }

        try test(shapeFormat: .polyline6, transformer: transformer, filePath: "v5_driving_dc_polyline")
    }

    @MainActor
    func testViaPoints() {
        let expectation = expectation(description: "calculating directions should return results")

        let queryParams: [String: String?] = [
            "geometries": "polyline",
            "overview": "full",
            "steps": "true",
            "language": "de_US",
            "waypoints": "0;2",
            "waypoint_names": "From;To",
            "alternatives": "false",
            "continue_straight": "true",
            "roundabout_exits": "true",
            "access_token": BogusToken,
        ]
        stub(
            condition: isHost("api.mapbox.com")
                && isPath("/directions/v5/mapbox/driving/-85.206232,39.33841;-85.203991,39.34181;-85.199697,39.342048")
                && containsQueryParams(queryParams)
        ) { _ in
            let path = Bundle.module.path(forResource: "v5_driving_oldenburg_polyline", ofType: "json")
            let filePath = URL(fileURLWithPath: path!)
            let data = try! Data(contentsOf: filePath, options: [])
            let jsonObject = try! JSONSerialization.jsonObject(with: data, options: [])
            return HTTPStubsResponse(
                jsonObject: jsonObject,
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            )
        }

        var waypoints = [
            Waypoint(
                coordinate: CLLocationCoordinate2D(latitude: 39.33841036211459, longitude: -85.20623174166413),
                coordinateAccuracy: -1,
                name: "From"
            ),
            Waypoint(
                coordinate: CLLocationCoordinate2D(latitude: 39.34181048315713, longitude: -85.20399062653789),
                coordinateAccuracy: -1,
                name: "Via"
            ),
            Waypoint(
                coordinate: CLLocationCoordinate2D(latitude: 39.34204769474999, longitude: -85.19969651878529),
                coordinateAccuracy: -1,
                name: "To"
            ),
        ]
        for index in waypoints.indices {
            waypoints[index].separatesLegs = false
        }

        let options = RouteOptions(waypoints: waypoints)
        XCTAssertEqual(options.shapeFormat, .polyline, "Route shape format should be Polyline by default.")

        options.shapeFormat = .polyline
        options.includesSteps = true
        options.routeShapeResolution = .full
        options.locale = Locale(identifier: "de_US")
        options.includesExitRoundaboutManeuver = true

        var route: Route?
        let task = Directions(credentials: BogusCredentials).calculate(options) { result in
            guard case .success(let response) = result else {
                XCTFail("Encountered unexpected error. \(result)")
                return
            }
            XCTAssertEqual(response.waypoints?.count, 3)

            XCTAssertNotNil(response.routes)
            XCTAssertEqual(response.routes!.count, 1)
            Task { @MainActor [r = response.routes!.first!] in
                route = r
                expectation.fulfill()
            }
        }
        XCTAssertNotNil(task)

        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error, "Error: \(error!)")
            XCTAssertEqual(task.state, .completed)
        }

        XCTAssertEqual(route?.legs.count, 1)
        let leg = route?.legs.first
        XCTAssertEqual(leg?.source!.name, waypoints[0].name)
        XCTAssertEqual(leg?.source?.coordinate.latitude ?? 0, waypoints[0].coordinate.latitude, accuracy: 1e-4)
        XCTAssertEqual(leg?.source?.coordinate.longitude ?? 0, waypoints[0].coordinate.longitude, accuracy: 1e-4)
        XCTAssertEqual(leg?.destination!.name, waypoints[2].name)
        XCTAssertEqual(leg?.destination?.coordinate.latitude ?? 0, waypoints[2].coordinate.latitude, accuracy: 1e-4)
        XCTAssertEqual(leg?.destination?.coordinate.longitude ?? 0, waypoints[2].coordinate.longitude, accuracy: 1e-4)
        XCTAssertEqual(leg?.name, "Perlen Strasse, Haupt Strasse")
        XCTAssertEqual(leg?.viaWaypoints!.count, 1)
        let silentWaypoint = leg?.viaWaypoints?.first!
        XCTAssertEqual(silentWaypoint?.waypointIndex, 1)
        XCTAssertEqual(silentWaypoint?.distanceFromStart, 610.733)
        XCTAssertEqual(silentWaypoint?.shapeCoordinateIndex, 21)
    }

    func testCoding() throws {
        let path = Bundle.module.path(forResource: "v5_driving_dc_polyline", ofType: "json")
        let filePath = URL(fileURLWithPath: path!)
        let data = try! Data(contentsOf: filePath)
        let options = RouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 37.78, longitude: -122.42),
            CLLocationCoordinate2D(latitude: 38.91, longitude: -77.03),
        ])

        let decoder = JSONDecoder()
        decoder.userInfo[.options] = options
        decoder.userInfo[.credentials] = Credentials(accessToken: "foo", host: URL(string: "http://sample.website"))
        let result = try decoder.decode(RouteResponse.self, from: data)

        let routes = result.routes
        let route = routes!.first!

        // Encode and decode the route securely.

        let encoder = JSONEncoder()
        encoder.userInfo[.options] = options
        encoder.outputFormatting = [.prettyPrinted]

        var jsonData: Data?
        XCTAssertNoThrow(jsonData = try encoder.encode(route))
        XCTAssertNotNil(jsonData)

        if let jsonData {
            var newRoute: Route?
            XCTAssertNoThrow(newRoute = try decoder.decode(Route.self, from: jsonData))
            XCTAssertNotNil(newRoute)
            test(newRoute)
        }
    }
}
#endif
