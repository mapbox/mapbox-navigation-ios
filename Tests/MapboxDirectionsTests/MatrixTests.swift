import XCTest
#if !os(Linux)
import OHHTTPStubs
#if SWIFT_PACKAGE
import OHHTTPStubsSwift
#endif
#endif
#if canImport(CoreLocation)
import CoreLocation
#endif
@testable import MapboxDirections
import Turf

let MatrixBogusCredentials = Credentials(accessToken: BogusToken)

#if !os(Linux)
class MatrixTests: XCTestCase {
    override func tearDown() {
#if !os(Linux)
        HTTPStubs.removeAllStubs()
#endif
        super.tearDown()
    }

    func testConfiguration() {
        let matrices = Matrix(credentials: MatrixBogusCredentials)
        XCTAssertEqual(matrices.credentials, MatrixBogusCredentials)
    }

    func testRequest() {
        let options = MatrixOptions(
            sources: testMatrixWaypoints,
            destinations: testMatrixWaypoints,
            profileIdentifier: .automobile
        )
        options.attributeOptions = [.distance, .expectedTravelTime]

        let matrices = Matrix(credentials: MatrixBogusCredentials)
        let url = matrices.url(forCalculating: options)
        let request = matrices.urlRequest(forCalculating: options)

        guard let components = URLComponents(string: url.absoluteString),
              let queryItems = components.queryItems else { XCTFail("Invalid url"); return }

        XCTAssertEqual(queryItems.count, 2)
        XCTAssertTrue(
            components.path
                .contains(testMatrixWaypoints.map(\.coordinate.requestDescription).joined(separator: ";"))
        )
        XCTAssertTrue(queryItems.contains(where: { $0.name == "access_token" && $0.value == BogusToken }))
        XCTAssertTrue(queryItems.contains(where: {
            let annotations = Set($0.value?.split(separator: ",").map { String($0) } ?? [])
            return $0.name == "annotations" &&
                annotations == Set(["distance", "duration"])
        }))

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url, url)
    }

    func testWaypointParameters() {
        var waypoints = testMatrixWaypoints

        waypoints[1].allowsArrivingOnOppositeSide = false

        let options = MatrixOptions(
            sources: Array(waypoints[1...2]),
            destinations: Array(waypoints[0...1]),
            profileIdentifier: .automobile
        )

        let matrices = Matrix(credentials: MatrixBogusCredentials)
        let url = matrices.url(forCalculating: options)

        for waypoint in waypoints {
            XCTAssertTrue(options.waypoints.contains(where: { $0 == waypoint }), "Waypoints are not composed correctly")
        }

        guard let components = URLComponents(string: url.absoluteString),
              let queryItems = components.queryItems else { XCTFail("Invalid url"); return }

        XCTAssertTrue(queryItems.contains(where: { $0.name == "sources" && $0.value == "0;1" }))
        XCTAssertTrue(queryItems.contains(where: { $0.name == "destinations" && $0.value == "0;2" }))

        XCTAssertTrue(
            queryItems
                .contains(where: { $0.name == "approaches" && $0.value == "curb;unrestricted;unrestricted" })
        )
    }

    func testUnknownBadResponse() {
        let message = "Lorem ipsum."
        HTTPStubs.stubRequests(passingTest: { request -> Bool in
            return request.url!.absoluteString.contains("https://api.mapbox.com/directions-matrix")
        }) { _ -> HTTPStubsResponse in
            return HTTPStubsResponse(
                data: message.data(using: .utf8)!,
                statusCode: 420,
                headers: ["Content-Type": "text/plain"]
            )
        }
        let expectation = expectation(description: "Async callback")
        let one = CLLocation(latitude: 0.0, longitude: 0.0)
        let two = CLLocation(latitude: 2.0, longitude: 2.0)
        let waypoints = [Waypoint(location: one), Waypoint(location: two)]

        let matrix = Matrix(credentials: MatrixBogusCredentials)
        let options = MatrixOptions(
            sources: waypoints,
            destinations: waypoints,
            profileIdentifier: .automobile
        )
        matrix.calculate(options, completionHandler: { result in
            defer { expectation.fulfill() }

            guard case .failure(let error) = result else {
                XCTFail("Expecting an error, none returned. \(result)")
                return
            }

            guard case .invalidResponse = error else {
                XCTFail("Wrong error type returned.")
                return
            }
        })
        wait(for: [expectation], timeout: 2.0)
    }

    func testDownNetwork() {
        let notConnected = NSError(
            domain: NSURLErrorDomain,
            code: URLError.notConnectedToInternet.rawValue
        ) as! URLError

        HTTPStubs.stubRequests(passingTest: { request -> Bool in
            return request.url!.absoluteString.contains("https://api.mapbox.com/directions-matrix")
        }) { _ -> HTTPStubsResponse in
            return HTTPStubsResponse(error: notConnected)
        }

        let expectation = expectation(description: "Async callback")
        let one = CLLocation(latitude: 0.0, longitude: 0.0)
        let two = CLLocation(latitude: 2.0, longitude: 2.0)
        let waypoints = [Waypoint(location: one), Waypoint(location: two)]

        let matrix = Matrix(credentials: MatrixBogusCredentials)
        let options = MatrixOptions(
            sources: waypoints,
            destinations: waypoints,
            profileIdentifier: .automobile
        )

        matrix.calculate(options, completionHandler: { result in
            defer { expectation.fulfill() }

            guard case .failure(let error) = result else {
                XCTFail("Error expected, none returned. \(result)")
                return
            }

            guard case .network(let err) = error else {
                XCTFail("Wrong error type returned. \(error)")
                return
            }

            // Comparing just the code and domain to avoid comparing unessential `UserInfo` that might be added.
            XCTAssertEqual(type(of: err).errorDomain, type(of: notConnected).errorDomain)
            XCTAssertEqual(err.code, notConnected.code)
        })
        wait(for: [expectation], timeout: 2.0)
    }

    func testRateLimitErrorParsing() {
        let url = URL(string: "https://api.mapbox.com")!
        let headerFields = [
            "X-Rate-Limit-Interval": "60",
            "X-Rate-Limit-Limit": "600",
            "X-Rate-Limit-Reset": "1479460584",
        ]
        let response = HTTPURLResponse(url: url, statusCode: 429, httpVersion: nil, headerFields: headerFields)

        let resultError = MatrixError(code: "429", message: "Hit rate limit", response: response, underlyingError: nil)
        if case .rateLimited(let rateLimitInterval, let rateLimit, let resetTime) = resultError {
            XCTAssertEqual(rateLimitInterval, 60.0)
            XCTAssertEqual(rateLimit, 600)
            XCTAssertEqual(resetTime, Date(timeIntervalSince1970: 1479460584))
        } else {
            XCTFail("Code 429 should be interpreted as a rate limiting error.")
        }
    }

    func testResponseParsing() {
        let waypoints = [
            Waypoint(
                coordinate: CLLocationCoordinate2D(latitude: 37.751668, longitude: -122.418408),
                name: "Mission Street"
            ),
            Waypoint(
                coordinate: CLLocationCoordinate2D(latitude: 37.755184, longitude: -122.422959),
                name: "22nd Street"
            ),
            Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.759695, longitude: -122.426911)),
        ]

        let options = MatrixOptions(
            sources: waypoints,
            destinations: waypoints,
            profileIdentifier: .automobile
        )
        options.attributeOptions = [.distance, .expectedTravelTime]

        let matrix = Matrix(credentials: MatrixBogusCredentials)
        let expectation = expectation(description: "Handler should be called.")

        HTTPStubs.stubRequests(passingTest: { request -> Bool in
            return request.url!.absoluteString.contains("https://api.mapbox.com/directions-matrix")
        }) { _ -> HTTPStubsResponse in
            let response = Fixture.stringFromFileNamed(name: "matrix")
            return HTTPStubsResponse(
                data: response.data(using: .utf8)!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            )
        }

        matrix.calculate(options, completionHandler: { result in
            defer { expectation.fulfill() }

            guard case .success(let response) = result else {
                XCTFail("Unexpected error. \(result)")
                return
            }

            XCTAssertEqual(
                response.destinations?.removingSnappedDistances(),
                options.waypoints
            )
            XCTAssertEqual(
                response.sources?.removingSnappedDistances(),
                options.waypoints
            )
            XCTAssertNil(response.distance(from: 0, to: 1))
            XCTAssertNil(response.travelTime(from: 0, to: 1))
            XCTAssertEqual(response.travelTime(from: 1, to: 2), 597.0)
            XCTAssertEqual(response.distance(from: 1, to: 2), 5970.0)
            XCTAssertNotNil(response.distances?[2])
            XCTAssertEqual(response.distances?.count, 3)
            XCTAssertNotNil(response.travelTimes?[2])
            XCTAssertEqual(response.travelTimes?.count, 3)
        })
        wait(for: [expectation], timeout: 2.0)
    }

    func testUrlWithCustomParametersWithAccessToken() {
        let customParameterKey = "custom_parameter"
        let customParameterValue = "custom_value"
        let queryItems = requestQueryItems(with: [
            URLQueryItem(name: "access_token", value: "invalid_token"),
            URLQueryItem(name: customParameterKey, value: customParameterValue),
        ])
        let accessTokenItems = queryItems.filter { $0.name == "access_token" }
        XCTAssertEqual(accessTokenItems.count, 1)
        XCTAssert(queryItems.contains(where: { $0.name == "access_token" && $0.value == BogusToken }))
        XCTAssert(queryItems.contains(where: { $0.name == customParameterKey && $0.value == customParameterValue }))
    }

    func testNoDuplicatedParameters() {
        checkForDuplicatedParameters(requestQueryItems: requestQueryItems(with:))
    }

    private func requestQueryItems(with customParameters: [URLQueryItem]) -> [URLQueryItem] {
        let coordinate = LocationCoordinate2D(latitude: 0, longitude: 0)
        let waypoint = Waypoint(coordinate: coordinate)
        let options = CustomMatrixOptions(
            sources: [waypoint],
            destinations: [waypoint],
            profileIdentifier: .automobileAvoidingTraffic,
            customParameters: customParameters
        )

        let matrix = Matrix(credentials: MatrixBogusCredentials)
        let url = matrix.url(forCalculating: options)
        guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else {
            XCTFail("Unexpected nil queryItems")
            return []
        }
        return queryItems
    }

    // MARK: Attribute Options URL Query Item Tests

    private var testMatrixWaypoints: [Waypoint] {
        [
            Waypoint(
                coordinate: CLLocationCoordinate2D(latitude: 37.751668, longitude: -122.418408),
                name: "Mission Street"
            ),
            Waypoint(
                coordinate: CLLocationCoordinate2D(latitude: 37.755184, longitude: -122.422959),
                name: "22nd Street"
            ),
            Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.759695, longitude: -122.426911)),
        ]
    }

    func testAttributeOptionsWithSupportedAttributes() {
        // Happy path: MatrixOptions only supports distance and expectedTravelTime
        let options = MatrixOptions(
            sources: testMatrixWaypoints,
            destinations: testMatrixWaypoints,
            profileIdentifier: .automobileAvoidingTraffic
        )
        options.attributeOptions = [.distance, .expectedTravelTime]

        let annotationsItem = options.urlQueryItems.first { $0.name == "annotations" }
        XCTAssertNotNil(annotationsItem, "Annotations query item should be present")

        let annotationsValue = annotationsItem?.value ?? ""
        XCTAssertTrue(annotationsValue.contains("distance"), "Should contain distance")
        XCTAssertTrue(annotationsValue.contains("duration"), "Should contain duration (expectedTravelTime)")
    }

    func testAttributeOptionsFiltersUnsupportedAttributes() {
        // Test that unsupported attributes are filtered out for MatrixOptions
        let options = MatrixOptions(
            sources: testMatrixWaypoints,
            destinations: testMatrixWaypoints,
            profileIdentifier: .automobileAvoidingTraffic
        )
        // Try to set attributes that MatrixOptions doesn't support
        options.attributeOptions = [
            .distance,
            .expectedTravelTime,
            .speed,
            .congestionLevel,
            .maximumSpeedLimit,
            .numericCongestionLevel,
            .closures,
        ]

        let annotationsItem = options.urlQueryItems.first { $0.name == "annotations" }
        XCTAssertNotNil(annotationsItem, "Annotations query item should be present")

        let annotationsValue = annotationsItem?.value ?? ""
        // Only distance and duration should be included
        XCTAssertTrue(annotationsValue.contains("distance"), "Should contain distance")
        XCTAssertTrue(annotationsValue.contains("duration"), "Should contain duration")

        // All other attributes should be filtered out
        XCTAssertFalse(annotationsValue.contains("speed"), "Should NOT contain speed")
        XCTAssertFalse(annotationsValue.contains("congestion"), "Should NOT contain congestion")
        XCTAssertFalse(annotationsValue.contains("maxspeed"), "Should NOT contain maxspeed")
        XCTAssertFalse(annotationsValue.contains("congestion_numeric"), "Should NOT contain congestion_numeric")
        XCTAssertFalse(annotationsValue.contains("closure"), "Should NOT contain closure")
    }

    func testAttributeOptionsWithAutomobileProfile() {
        // Test that profile identifier doesn't affect filtering for MatrixOptions
        let options = MatrixOptions(
            sources: testMatrixWaypoints,
            destinations: testMatrixWaypoints,
            profileIdentifier: .automobile
        )
        options.attributeOptions = [
            .distance,
            .expectedTravelTime,
            .maximumSpeedLimit, // Not supported even for automobile profile
        ]

        let annotationsItem = options.urlQueryItems.first { $0.name == "annotations" }
        XCTAssertNotNil(annotationsItem, "Annotations query item should be present")

        let annotationsValue = annotationsItem?.value ?? ""
        XCTAssertTrue(annotationsValue.contains("distance"), "Should contain distance")
        XCTAssertTrue(annotationsValue.contains("duration"), "Should contain duration")
        XCTAssertFalse(annotationsValue.contains("maxspeed"), "Should NOT contain maxspeed for MatrixOptions")
    }

    func testAttributeOptionsWithWalkingProfile() {
        // Test that MatrixOptions behavior is the same regardless of profile
        let options = MatrixOptions(
            sources: testMatrixWaypoints,
            destinations: testMatrixWaypoints,
            profileIdentifier: .walking
        )
        options.attributeOptions = [.distance, .expectedTravelTime, .speed]

        let annotationsItem = options.urlQueryItems.first { $0.name == "annotations" }
        XCTAssertNotNil(annotationsItem, "Annotations query item should be present")

        let annotationsValue = annotationsItem?.value ?? ""
        XCTAssertTrue(annotationsValue.contains("distance"), "Should contain distance")
        XCTAssertTrue(annotationsValue.contains("duration"), "Should contain duration")
        XCTAssertFalse(annotationsValue.contains("speed"), "Should NOT contain speed for MatrixOptions")
    }

    func testAttributeOptionsEmpty() {
        // Test that no annotations query item is present when attributeOptions is empty
        let options = MatrixOptions(
            sources: testMatrixWaypoints,
            destinations: testMatrixWaypoints,
            profileIdentifier: .automobileAvoidingTraffic
        )
        options.attributeOptions = []

        let annotationsItem = options.urlQueryItems.first { $0.name == "annotations" }
        XCTAssertNil(annotationsItem, "Annotations query item should be nil when attributeOptions is empty")
    }

    func testAttributeOptionsWithOnlyDistance() {
        // Test with only distance attribute
        let options = MatrixOptions(
            sources: testMatrixWaypoints,
            destinations: testMatrixWaypoints,
            profileIdentifier: .automobileAvoidingTraffic
        )
        options.attributeOptions = [.distance]

        let annotationsItem = options.urlQueryItems.first { $0.name == "annotations" }
        XCTAssertNotNil(annotationsItem, "Annotations query item should be present")

        let annotationsValue = annotationsItem?.value ?? ""
        XCTAssertTrue(annotationsValue.contains("distance"), "Should contain distance")
        XCTAssertFalse(annotationsValue.contains("duration"), "Should NOT contain duration when not requested")
    }

    func testAttributeOptionsWithOnlyTravelTime() {
        // Test with only expectedTravelTime attribute
        let options = MatrixOptions(
            sources: testMatrixWaypoints,
            destinations: testMatrixWaypoints,
            profileIdentifier: .automobileAvoidingTraffic
        )
        options.attributeOptions = [.expectedTravelTime]

        let annotationsItem = options.urlQueryItems.first { $0.name == "annotations" }
        XCTAssertNotNil(annotationsItem, "Annotations query item should be present")

        let annotationsValue = annotationsItem?.value ?? ""
        XCTAssertTrue(annotationsValue.contains("duration"), "Should contain duration")
        XCTAssertFalse(annotationsValue.contains("distance"), "Should NOT contain distance when not requested")
    }

    func testAttributeOptionsWithCustomOption() {
        // Test that custom attributes are preserved
        let options = MatrixOptions(
            sources: testMatrixWaypoints,
            destinations: testMatrixWaypoints,
            profileIdentifier: .automobileAvoidingTraffic
        )
        var customAttributeOptions = AttributeOptions(rawValue: 1 << 30)
        customAttributeOptions.customOptionsByRawValue[1 << 30] = "customOption"
        options.attributeOptions = customAttributeOptions

        let annotationsItem = options.urlQueryItems.first { $0.name == "annotations" }
        // Custom options should be included even if not in the supported list
        XCTAssertNotNil(annotationsItem, "Annotations query item should be present")
    }

    func testAttributeOptionsCombinedSupportedAndCustom() {
        // Test that custom attributes are preserved alongside supported ones
        let options = MatrixOptions(
            sources: testMatrixWaypoints,
            destinations: testMatrixWaypoints,
            profileIdentifier: .automobileAvoidingTraffic
        )
        var customAttributeOption = AttributeOptions(rawValue: 1 << 30)
        customAttributeOption.customOptionsByRawValue[1 << 30] = "customOption"
        options.attributeOptions = [
            .distance,
            .expectedTravelTime,
            customAttributeOption,
        ]

        let annotationsItem = options.urlQueryItems.first { $0.name == "annotations" }
        XCTAssertNotNil(annotationsItem, "Annotations query item should be present")

        let annotationsValue = annotationsItem?.value ?? ""
        XCTAssertTrue(annotationsValue.contains("distance"), "Should contain distance")
        XCTAssertTrue(annotationsValue.contains("duration"), "Should contain duration")
        // Custom option should be included
        XCTAssertTrue(annotationsValue.contains("customOption"), "Should contain customOption")
    }

    func testAttributeOptionsWithCustomProfile() {
        // Test that custom profiles don't change filtering behavior
        let customProfile = ProfileIdentifier(rawValue: "custom/driving-traffic")
        let options = MatrixOptions(
            sources: testMatrixWaypoints,
            destinations: testMatrixWaypoints,
            profileIdentifier: customProfile
        )
        options.attributeOptions = [
            .distance,
            .expectedTravelTime,
            .congestionLevel, // Should still be filtered out
        ]

        let annotationsItem = options.urlQueryItems.first { $0.name == "annotations" }
        XCTAssertNotNil(annotationsItem, "Annotations query item should be present")

        let annotationsValue = annotationsItem?.value ?? ""
        XCTAssertTrue(annotationsValue.contains("distance"), "Should contain distance")
        XCTAssertTrue(annotationsValue.contains("duration"), "Should contain duration")
        // Even with traffic profile, congestion should be filtered for MatrixOptions
        XCTAssertFalse(annotationsValue.contains("congestion"), "Should NOT contain congestion for MatrixOptions")
    }
}
#endif

extension Collection<Waypoint> {
    func removingSnappedDistances() -> [Element] {
        map {
            var waypoint = $0
            waypoint.snappedDistance = nil
            return waypoint
        }
    }
}
