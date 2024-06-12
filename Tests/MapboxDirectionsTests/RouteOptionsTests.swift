@testable import MapboxDirections
import Turf
import XCTest

class RouteOptionsTests: XCTestCase {
    func testCoding() {
        let options = testRouteOptions

        let encoded: Data = try! JSONEncoder().encode(options)
        let optionsString = String(data: encoded, encoding: .utf8)!

        let unarchivedOptions: RouteOptions = try! JSONDecoder().decode(
            RouteOptions.self,
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
        XCTAssertEqual(unarchivedWaypoints[0].layer, -1)
        XCTAssertEqual(unarchivedWaypoints[2].layer, 3)

        XCTAssertEqual(unarchivedOptions.profileIdentifier, options.profileIdentifier)
        XCTAssertEqual(unarchivedOptions.locale, options.locale)
        XCTAssertEqual(unarchivedOptions.includesSpokenInstructions, options.includesSpokenInstructions)
        XCTAssertEqual(unarchivedOptions.distanceMeasurementSystem, options.distanceMeasurementSystem)
        XCTAssertEqual(unarchivedOptions.includesVisualInstructions, options.includesVisualInstructions)
        XCTAssertEqual(unarchivedOptions.roadClassesToAvoid, options.roadClassesToAvoid)
        XCTAssertEqual(unarchivedOptions.roadClassesToAllow, options.roadClassesToAllow)
        XCTAssertEqual(unarchivedOptions.initialManeuverAvoidanceRadius, options.initialManeuverAvoidanceRadius)
        XCTAssertEqual(unarchivedOptions.maximumWidth, options.maximumWidth)
        XCTAssertEqual(unarchivedOptions.maximumHeight, options.maximumHeight)
        XCTAssertEqual(unarchivedOptions.alleyPriority, options.alleyPriority)
        XCTAssertEqual(unarchivedOptions.walkwayPriority, options.walkwayPriority)
        XCTAssertEqual(unarchivedOptions.speed, options.speed)
        XCTAssertEqual(unarchivedOptions.includesTollPrices, options.includesTollPrices)
    }

    func testCodingWithRawCodingKeys() {
        let routeOptionsJSON: [String: Any?] = [
            "waypoints": [
                [
                    "location": [-77.036500000000004, 38.8977],
                    "name": "White House",
                ],
            ],
            "profile": "mapbox/driving-traffic",
            "steps": true,
            "geometries": "polyline",
            "overview": "simplified",
            "annotations": ["congestion"],
            "language": "en_US",
            "voice_instructions": true,
            "voice_units": "imperial",
            "banner_instructions": true,
            "continue_straight": true,
            "alternatives": false,
            "roundabout_exits": true,
            "exclude": ["toll"],
            "include": ["hov3", "hot"],
            "enable_refresh": false,
            "avoid_maneuver_radius": 300,
            "max_width": 2.3,
            "max_weight": 3.5,
            "max_height": 3,
            "alley_bias": DirectionsPriority.low.rawValue,
            "walkway_bias": DirectionsPriority.high.rawValue,
            "compute_toll_cost": true,
        ]

        let routeOptionsData = try! JSONSerialization.data(withJSONObject: routeOptionsJSON, options: [])
        var routeOptions: RouteOptions!
        XCTAssertNoThrow(routeOptions = try! JSONDecoder().decode(RouteOptions.self, from: routeOptionsData))

        XCTAssertEqual(routeOptions.profileIdentifier, .automobileAvoidingTraffic)
        XCTAssertEqual(routeOptions.includesSteps, true)
        XCTAssertEqual(routeOptions.shapeFormat, .polyline)
        XCTAssertEqual(routeOptions.routeShapeResolution, .low)
        XCTAssertEqual(routeOptions.attributeOptions, .congestionLevel)
        XCTAssertEqual(routeOptions.locale, Locale(identifier: "en_US"))
        XCTAssertEqual(routeOptions.includesSpokenInstructions, true)
        XCTAssertEqual(routeOptions.distanceMeasurementSystem, .imperial)
        XCTAssertEqual(routeOptions.includesVisualInstructions, true)
        XCTAssertEqual(routeOptions.allowsUTurnAtWaypoint, true)
        XCTAssertEqual(routeOptions.includesAlternativeRoutes, false)
        XCTAssertEqual(routeOptions.includesExitRoundaboutManeuver, true)
        XCTAssertEqual(routeOptions.roadClassesToAvoid, .toll)
        XCTAssertEqual(routeOptions.roadClassesToAllow, [.highOccupancyVehicle3, .highOccupancyToll])
        XCTAssertEqual(routeOptions.refreshingEnabled, false)
        XCTAssertEqual(routeOptions.initialManeuverAvoidanceRadius, 300)
        XCTAssertEqual(routeOptions.maximumWidth, Measurement(value: 2.3, unit: .meters))
        XCTAssertEqual(routeOptions.maximumHeight, Measurement(value: 3, unit: .meters))
        XCTAssertEqual(routeOptions.maximumWeight, Measurement(value: 3.5, unit: .metricTons))
        XCTAssertEqual(routeOptions.includesTollPrices, true)

        let encodedRouteOptions: Data = try! JSONEncoder().encode(routeOptions)
        let optionsString = String(data: encodedRouteOptions, encoding: .utf8)!

        let unarchivedOptions: RouteOptions = try! JSONDecoder().decode(
            RouteOptions.self,
            from: optionsString.data(using: .utf8)!
        )

        XCTAssertNotNil(unarchivedOptions)
        XCTAssertEqual(unarchivedOptions.profileIdentifier, routeOptions.profileIdentifier)
        XCTAssertEqual(unarchivedOptions.includesSteps, routeOptions.includesSteps)
        XCTAssertEqual(unarchivedOptions.shapeFormat, routeOptions.shapeFormat)
        XCTAssertEqual(unarchivedOptions.routeShapeResolution, routeOptions.routeShapeResolution)
        XCTAssertEqual(unarchivedOptions.attributeOptions, routeOptions.attributeOptions)
        XCTAssertEqual(unarchivedOptions.locale, routeOptions.locale)
        XCTAssertEqual(unarchivedOptions.includesSpokenInstructions, routeOptions.includesSpokenInstructions)
        XCTAssertEqual(unarchivedOptions.distanceMeasurementSystem, routeOptions.distanceMeasurementSystem)
        XCTAssertEqual(unarchivedOptions.includesVisualInstructions, routeOptions.includesVisualInstructions)
        XCTAssertEqual(unarchivedOptions.allowsUTurnAtWaypoint, routeOptions.allowsUTurnAtWaypoint)
        XCTAssertEqual(unarchivedOptions.includesAlternativeRoutes, routeOptions.includesAlternativeRoutes)
        XCTAssertEqual(unarchivedOptions.includesExitRoundaboutManeuver, routeOptions.includesExitRoundaboutManeuver)
        XCTAssertEqual(unarchivedOptions.roadClassesToAvoid, routeOptions.roadClassesToAvoid)
        XCTAssertEqual(unarchivedOptions.roadClassesToAllow, routeOptions.roadClassesToAllow)
        XCTAssertEqual(unarchivedOptions.refreshingEnabled, routeOptions.refreshingEnabled)
        XCTAssertEqual(unarchivedOptions.initialManeuverAvoidanceRadius, routeOptions.initialManeuverAvoidanceRadius)
        XCTAssertEqual(unarchivedOptions.maximumWidth, routeOptions.maximumWidth)
        XCTAssertEqual(unarchivedOptions.maximumHeight, routeOptions.maximumHeight)
        XCTAssertEqual(unarchivedOptions.includesTollPrices, routeOptions.includesTollPrices)
    }

    func testURLCoding() throws {
        let originalOptions = testRouteOptions
        originalOptions.includesAlternativeRoutes = true
        originalOptions.includesExitRoundaboutManeuver = true
        originalOptions.refreshingEnabled = true

        for index in originalOptions.waypoints.indices {
            originalOptions.waypoints[index].allowsArrivingOnOppositeSide = index == 2
            originalOptions.waypoints[index].coordinateAccuracy = LocationAccuracy(index)
            originalOptions.waypoints[index].heading = LocationDirection(index * 10)
            originalOptions.waypoints[index].headingAccuracy = LocationDirection(index)
            originalOptions.waypoints[index].separatesLegs = index != 1
            if originalOptions.waypoints[index].separatesLegs {
                originalOptions.waypoints[index].name = "name_\(index)"
                originalOptions.waypoints[index].targetCoordinate = originalOptions.waypoints[index].coordinate
            }
            originalOptions.waypoints[index].allowsSnappingToClosedRoad = index == 1
            originalOptions.waypoints[index].allowsSnappingToStaticallyClosedRoad = index == 1
        }

        let url = Directions(credentials: BogusCredentials).url(forCalculating: originalOptions)

        guard let decodedOptions = RouteOptions(url: url) else {
            XCTFail("Could not decode `RouteOptions`")
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
            XCTAssertEqual($0.0.allowsSnappingToClosedRoad, $0.1.allowsSnappingToClosedRoad)
            XCTAssertEqual($0.0.allowsSnappingToStaticallyClosedRoad, $0.1.allowsSnappingToStaticallyClosedRoad)
            XCTAssertEqual($0.0.allowsArrivingOnOppositeSide, $0.1.allowsArrivingOnOppositeSide)
            XCTAssertEqual($0.0.targetCoordinate, $0.1.targetCoordinate)
            XCTAssertEqual($0.0.separatesLegs, $0.1.separatesLegs)
            XCTAssertEqual($0.0.coordinateAccuracy, $0.1.coordinateAccuracy)
            XCTAssertEqual($0.0.heading, $0.1.heading)
            XCTAssertEqual($0.0.headingAccuracy, $0.1.headingAccuracy)
            XCTAssertEqual($0.0.name, $0.1.name)
        }

        XCTAssertEqual(decodedOptions.includesAlternativeRoutes, originalOptions.includesAlternativeRoutes)
        XCTAssertEqual(decodedOptions.includesExitRoundaboutManeuver, originalOptions.includesExitRoundaboutManeuver)
        XCTAssertEqual(decodedOptions.refreshingEnabled, originalOptions.refreshingEnabled)
        XCTAssertEqual(decodedOptions.shapeFormat, originalOptions.shapeFormat)
        XCTAssertEqual(decodedOptions.routeShapeResolution, originalOptions.routeShapeResolution)
        XCTAssertEqual(decodedOptions.includesSteps, originalOptions.includesSteps)
        XCTAssertEqual(decodedOptions.attributeOptions, originalOptions.attributeOptions)
        XCTAssertEqual(decodedOptions.profileIdentifier, originalOptions.profileIdentifier)
        XCTAssertEqual(decodedOptions.locale, originalOptions.locale)
        XCTAssertEqual(decodedOptions.includesSpokenInstructions, originalOptions.includesSpokenInstructions)
        XCTAssertEqual(decodedOptions.distanceMeasurementSystem, originalOptions.distanceMeasurementSystem)
        XCTAssertEqual(decodedOptions.includesVisualInstructions, originalOptions.includesVisualInstructions)
        XCTAssertEqual(decodedOptions.roadClassesToAvoid, originalOptions.roadClassesToAvoid)
        XCTAssertEqual(decodedOptions.roadClassesToAllow, originalOptions.roadClassesToAllow)
        XCTAssertEqual(decodedOptions.initialManeuverAvoidanceRadius, originalOptions.initialManeuverAvoidanceRadius)
        XCTAssertEqual(decodedOptions.maximumWidth, originalOptions.maximumWidth)
        XCTAssertEqual(decodedOptions.maximumHeight, originalOptions.maximumHeight)
        XCTAssertEqual(decodedOptions.alleyPriority, originalOptions.alleyPriority)
        XCTAssertEqual(decodedOptions.walkwayPriority, originalOptions.walkwayPriority)
        XCTAssertEqual(decodedOptions.speed, originalOptions.speed)
        XCTAssertEqual(decodedOptions.includesTollPrices, originalOptions.includesTollPrices)
        XCTAssertNil(decodedOptions.arriveBy)
        // URL encoding skips seconds, so we check that dates are within 1 minute delta
        XCTAssertTrue(abs(decodedOptions.departAt!.timeIntervalSince(originalOptions.departAt!)) < 60)

        let routeURL =
            try XCTUnwrap(
                URL(
                    string: "https://api.mapbox.com/directions/v5/mapbox/driving-traffic/-121.913565,37.331832;-121.916282,37.328707.json"
                )
            )
        XCTAssertNotNil(RouteOptions(url: routeURL))
        XCTAssertNil(MatchOptions(url: routeURL))
    }

    // MARK: API name-handling tests

    private static var testWaypoints: [Waypoint] {
        return [
            Waypoint(coordinate: LocationCoordinate2D(latitude: 39.27664, longitude: -84.41139)),
            Waypoint(coordinate: LocationCoordinate2D(latitude: 39.27277, longitude: -84.41226)),
        ]
    }

    private func response(
        for fixtureName: String,
        waypoints: [Waypoint] = testWaypoints
    ) -> (waypoints: [Waypoint], route: Route)? {
        let testBundle = Bundle.module
        guard let fixtureURL = testBundle.url(forResource: fixtureName, withExtension: "json") else {
            XCTFail()
            return nil
        }
        guard let fixtureData = try? Data(contentsOf: fixtureURL, options: .mappedIfSafe) else {
            XCTFail()
            return nil
        }

        let subject = RouteOptions(waypoints: waypoints)
        let decoder = JSONDecoder()
        decoder.userInfo[.options] = subject
        decoder.userInfo[.credentials] = Credentials(accessToken: "foo", host: URL(string: "https://test.website")!)
        var response: RouteResponse?
        XCTAssertNoThrow(response = try decoder.decode(RouteResponse.self, from: fixtureData))
        XCTAssertNotNil(response)

        if let response {
            XCTAssertNotNil(response.waypoints)
            XCTAssertNotNil(response.routes)
        }
        guard let waypoints = response?.waypoints, let route = response?.routes?.first else {
            return nil
        }
        return (waypoints: waypoints, route: route)
    }

    func testResponseWithoutDestinationName() throws {
        // https://api.mapbox.com/directions/v5/mapbox/driving/-84.411389,39.27665;-84.412115,39.272675?overview=false&steps=false&access_token=pk.feedcafedeadbeef
        let response = try XCTUnwrap(response(for: "noDestinationName"))
        XCTAssertNil(
            response.route.legs.last?.destination?.name,
            "Empty-string waypoint name in API responds should be represented as nil."
        )
    }

    func testResponseWithDestinationName() throws {
        // https://api.mapbox.com/directions/v5/mapbox/driving/-84.411389,39.27665;-84.41195,39.27260?overview=false&steps=false&access_token=pk.feedcafedeadbeef
        let response = try XCTUnwrap(response(for: "apiDestinationName"))
        XCTAssertEqual(
            response.route.legs.last?.destination?.name,
            "Reading Road",
            "Waypoint name in fixture response not parsed correctly."
        )
    }

    func testResponseWithManuallySetDestinationName() throws {
        var manuallySet = RouteOptionsTests.testWaypoints
        manuallySet[manuallySet.endIndex - 1].name = "manuallyset"

        let response = try XCTUnwrap(response(for: "apiDestinationName", waypoints: manuallySet))
        XCTAssertEqual(
            response.route.legs.last?.destination?.name,
            "manuallyset",
            "Waypoint with manually set name should override any computed name."
        )
    }

    func testApproachesURLQueryParams() {
        let coordinate = LocationCoordinate2D(latitude: 0, longitude: 0)
        var wp1 = Waypoint(coordinate: coordinate, coordinateAccuracy: 0)
        wp1.allowsArrivingOnOppositeSide = false
        let waypoints = [
            Waypoint(coordinate: coordinate, coordinateAccuracy: 0),
            wp1,
            Waypoint(coordinate: coordinate, coordinateAccuracy: 0),
        ]

        let routeOptions = RouteOptions(waypoints: waypoints)
        routeOptions.includesSteps = true
        let urlQueryItems = routeOptions.urlQueryItems
        let approaches = urlQueryItems.filter { $0.name == "approaches" }.first!
        XCTAssertEqual(approaches.value!, "unrestricted;curb;unrestricted", "waypoints[1] should be restricted to curb")
    }

    func testMissingApproaches() {
        let coordinate = LocationCoordinate2D(latitude: 0, longitude: 0)
        let waypoints = [
            Waypoint(coordinate: coordinate, coordinateAccuracy: 0),
            Waypoint(coordinate: coordinate, coordinateAccuracy: 0),
            Waypoint(coordinate: coordinate, coordinateAccuracy: 0),
        ]

        let routeOptions = RouteOptions(waypoints: waypoints)
        routeOptions.includesSteps = true
        let urlQueryItems = routeOptions.urlQueryItems
        let hasApproaches = !urlQueryItems.filter { $0.name == "approaches" }.isEmpty
        XCTAssertFalse(
            hasApproaches,
            "approaches query param should be omitted unless any waypoint is restricted to curb"
        )
    }

    func testDecimalPrecision() {
        let start = LocationCoordinate2D(latitude: 9.945497000000003, longitude: 53.03218800000006)
        let end = LocationCoordinate2D(latitude: 10.945497000000003, longitude: 54.03218800000006)

        let answer = [start.requestDescription, end.requestDescription]
        let correct = ["53.032188,9.945497", "54.032188,10.945497"]
        XCTAssert(answer == correct, "Coordinates should be truncated.")
    }

    func testWaypointSerialization() {
        let origin = Waypoint(coordinate: LocationCoordinate2D(latitude: 39.15031, longitude: -84.47182), name: "XU")
        var destination = Waypoint(
            coordinate: LocationCoordinate2D(latitude: 39.12971, longitude: -84.51638),
            name: "UC"
        )
        destination.targetCoordinate = LocationCoordinate2D(latitude: 39.13115, longitude: -84.51619)
        let options = RouteOptions(waypoints: [origin, destination])
        XCTAssertEqual(options.coordinates, "-84.47182,39.15031;-84.51638,39.12971")
        XCTAssertTrue(options.urlQueryItems.contains(URLQueryItem(name: "waypoint_names", value: "XU;UC")))
        XCTAssertTrue(options.urlQueryItems.contains(URLQueryItem(
            name: "waypoint_targets",
            value: ";-84.51619,39.13115"
        )))
    }

    func testWaypointLayers() {
        var from = Waypoint(coordinate: LocationCoordinate2D(latitude: 0, longitude: 0))
        let through = Waypoint(coordinate: LocationCoordinate2D(latitude: 0, longitude: 0))
        var to = Waypoint(coordinate: LocationCoordinate2D(latitude: 0, longitude: 0))
        from.layer = -1
        to.layer = 3
        let options = RouteOptions(waypoints: [from, through, to])
        XCTAssertTrue(options.urlQueryItems.contains(URLQueryItem(name: "layers", value: "-1;;3")))
    }

    func testInitialManeuverAvoidanceRadiusSerialization() {
        let options = RouteOptions(coordinates: testCoordinates)

        options.initialManeuverAvoidanceRadius = 123.456

        XCTAssertTrue(options.urlQueryItems.contains(URLQueryItem(name: "avoid_maneuver_radius", value: "123.456")))

        options.initialManeuverAvoidanceRadius = nil

        XCTAssertFalse(options.urlQueryItems.contains(URLQueryItem(name: "avoid_maneuver_radius", value: nil)))
    }

    func testMaximumWidthAndMaximimHeightSerialization() {
        let options = RouteOptions(coordinates: testCoordinates)
        let widthValue = 2.3
        let heightValue = 2.0
        options.maximumWidth = Measurement(value: widthValue, unit: .meters)
        options.maximumHeight = Measurement(value: heightValue, unit: .meters)
        XCTAssertTrue(options.urlQueryItems.contains(URLQueryItem(name: "max_width", value: String(widthValue))))
        XCTAssertTrue(options.urlQueryItems.contains(URLQueryItem(name: "max_height", value: String(heightValue))))
    }

    func testMaximumWeightSerialization() {
        let options = RouteOptions(coordinates: [])
        let weightValue = 13.3
        options.maximumWeight = Measurement(value: weightValue, unit: .metricTons)
        XCTAssertTrue(options.urlQueryItems.contains(URLQueryItem(name: "max_weight", value: String(weightValue))))
    }

    func testExcludeAndIncludeRoadClasses() {
        let options = RouteOptions(coordinates: testCoordinates)
        options.roadClassesToAvoid = [.toll, .motorway, .ferry, .unpaved, .cashTollOnly]
        options.roadClassesToAllow = [.highOccupancyVehicle2, .highOccupancyVehicle3, .highOccupancyToll]

        let expectedExcludeQueryItem = URLQueryItem(
            name: "exclude",
            value: "toll,motorway,ferry,unpaved,cash_only_tolls"
        )
        XCTAssertTrue(options.urlQueryItems.contains(expectedExcludeQueryItem))

        let expectedIncludeQueryItem = URLQueryItem(name: "include", value: "hov2,hov3,hot")
        XCTAssertTrue(options.urlQueryItems.contains(expectedIncludeQueryItem))
    }

    func testReturnPathIfNoWaypointsAndOneWaypoint() {
        let noWaypointOptions = RouteOptions(coordinates: [])
        XCTAssertEqual(noWaypointOptions.path, noWaypointOptions.abridgedPath)

        let oneWaypointOptions = RouteOptions(coordinates: [LocationCoordinate2D(latitude: 0.0, longitude: 0.0)])
        XCTAssertEqual(oneWaypointOptions.path, oneWaypointOptions.abridgedPath)

        let waypoints = [
            Waypoint(coordinate: LocationCoordinate2D(latitude: 0.0, longitude: 0.0), name: "name"),
        ]
        let oneWaypointOptionsWithNonNilName = RouteOptions(waypoints: waypoints)
        XCTAssertEqual(oneWaypointOptionsWithNonNilName.path, oneWaypointOptionsWithNonNilName.abridgedPath)
    }

    func testReturnUrlQueryWaypoinNameItemsIfNoWaypointsAndOneWaypoint() {
        let noWaypointOptions = RouteOptions(coordinates: [])
        XCTAssertFalse(noWaypointOptions.urlQueryItems.map(\.name).contains("waypoint_names"))

        let oneWaypointOptionsWithNilName = RouteOptions(coordinates: [LocationCoordinate2D(
            latitude: 0.0,
            longitude: 0.0
        )])
        XCTAssertFalse(oneWaypointOptionsWithNilName.urlQueryItems.map(\.name).contains("waypoint_names"))

        let waypoints = [
            Waypoint(coordinate: LocationCoordinate2D(latitude: 0.0, longitude: 0.0), name: "name"),
        ]

        let oneWaypointOptionsWithNonNilName = RouteOptions(waypoints: waypoints)
        XCTAssertFalse(oneWaypointOptionsWithNonNilName.urlQueryItems.map(\.name).contains("waypoint_names"))
    }
}

private let testCoordinates = [
    LocationCoordinate2D(latitude: 52.5109, longitude: 13.4301),
    LocationCoordinate2D(latitude: 52.5080, longitude: 13.4265),
    LocationCoordinate2D(latitude: 52.5021, longitude: 13.4316),
]

var testRouteOptions: RouteOptions {
    var waypoints = testCoordinates.map { Waypoint(coordinate: $0) }
    waypoints[0].layer = -1
    waypoints[2].layer = 3

    let opts = RouteOptions(waypoints: waypoints, profileIdentifier: .automobileAvoidingTraffic)
    opts.locale = Locale(identifier: "en_US")
    opts.allowsUTurnAtWaypoint = true
    opts.shapeFormat = .polyline
    opts.routeShapeResolution = .full
    opts.attributeOptions = [.congestionLevel]
    opts.includesExitRoundaboutManeuver = true
    opts.includesSpokenInstructions = true
    opts.distanceMeasurementSystem = .metric
    opts.includesVisualInstructions = true
    opts.roadClassesToAvoid = .toll
    opts.roadClassesToAllow = [.highOccupancyVehicle3, .highOccupancyToll]
    opts.initialManeuverAvoidanceRadius = 100
    opts.maximumWidth = Measurement(value: 2, unit: .meters)
    opts.maximumHeight = Measurement(value: 3, unit: .meters)
    opts.alleyPriority = .low
    opts.walkwayPriority = .high
    opts.speed = 1
    opts.departAt = Date(timeIntervalSince1970: 500)
    opts.arriveBy = Date(timeIntervalSince1970: 600)
    opts.includesTollPrices = true

    return opts
}
