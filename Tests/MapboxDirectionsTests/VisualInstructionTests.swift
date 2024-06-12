import XCTest
#if !os(Linux)
import CoreLocation
import OHHTTPStubs
#if SWIFT_PACKAGE
import OHHTTPStubsSwift
#endif
@testable import MapboxDirections

class VisualInstructionsTests: XCTestCase {
    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testCoding() {
        let bannerJSON: [String: Any?] = [
            "distanceAlongGeometry": 393.3,
            "primary": [
                "text": "Weinstock Strasse",
                "components": [
                    [
                        "text": "Weinstock Strasse",
                        "type": "text",
                    ],
                ],
                "type": "turn",
                "modifier": "right",
            ],
            "secondary": nil,
            "view": [
                "text": "CA01610_1_E",
                "components": [
                    [
                        "text": "CA01610_1_E",
                        "type": "guidance-view",
                        "imageURL": "https://www.mapbox.com/navigation",
                    ],
                ],
                "type": "fork",
                "modifier": "right",
            ],
        ]
        let bannerData = try! JSONSerialization.data(withJSONObject: bannerJSON, options: [])
        var banner: VisualInstructionBanner?
        XCTAssertNoThrow(banner = try JSONDecoder().decode(VisualInstructionBanner.self, from: bannerData))
        XCTAssertNotNil(banner)
        if let banner {
            XCTAssertEqual(banner.distanceAlongStep, 393.3, accuracy: 1e-1)
            XCTAssertEqual(banner.primaryInstruction.text, "Weinstock Strasse")
            XCTAssertEqual(banner.primaryInstruction.components.count, 1)
            XCTAssertEqual(banner.primaryInstruction.maneuverType, .turn)
            XCTAssertEqual(banner.primaryInstruction.maneuverDirection, .right)
            XCTAssertNil(banner.secondaryInstruction)
            XCTAssertNotNil(banner.quaternaryInstruction)
            XCTAssertEqual(banner.quaternaryInstruction?.components.count, 1)
            XCTAssertEqual(banner.drivingSide, .default)
        }

        let componentGuidanceViewImage = banner?.quaternaryInstruction?.components.first
        XCTAssertNotNil(componentGuidanceViewImage)

        let component = VisualInstruction.Component.text(text: .init(
            text: "Weinstock Strasse",
            abbreviation: nil,
            abbreviationPriority: nil
        ))
        let primaryInstruction = VisualInstruction(
            text: "Weinstock Strasse",
            maneuverType: .turn,
            maneuverDirection: .right,
            components: [component]
        )

        let guideViewComponent = VisualInstruction.Component.guidanceView(
            image: GuidanceViewImageRepresentation(imageURL: URL(string: "https://www.mapbox.com/navigation")),
            alternativeText: VisualInstruction.Component.TextRepresentation(
                text: "CA01610_1_E",
                abbreviation: nil,
                abbreviationPriority: nil
            )
        )
        XCTAssert(componentGuidanceViewImage == guideViewComponent)
        let quaternaryInstruction = VisualInstruction(
            text: "CA01610_1_E",
            maneuverType: .reachFork,
            maneuverDirection: .right,
            components: [guideViewComponent]
        )

        banner = VisualInstructionBanner(
            distanceAlongStep: 393.3,
            primary: primaryInstruction,
            secondary: nil,
            tertiary: nil,
            quaternary: quaternaryInstruction,
            drivingSide: .right
        )
        let encoder = JSONEncoder()
        var encodedData: Data?
        XCTAssertNoThrow(encodedData = try encoder.encode(banner))
        XCTAssertNotNil(encodedData)

        if let encodedData {
            var encodedBannerJSON: [String: Any?]?
            XCTAssertNoThrow(
                encodedBannerJSON = try JSONSerialization
                    .jsonObject(with: encodedData, options: []) as? [String: Any?]
            )
            XCTAssertNotNil(encodedBannerJSON)

            // Verify then remove keys that wouldn’t necessarily be part of a BannerInstruction object in the Directions
            // API response.
            XCTAssertEqual(encodedBannerJSON?["drivingSide"] as? String, "right")
            encodedBannerJSON?.removeValue(forKey: "drivingSide")

            encodedBannerJSON?.updateValue(nil, forKey: "secondary")

            XCTAssert(JSONSerialization.objectsAreEqual(bannerJSON, encodedBannerJSON, approximate: false))
        }
    }

    @MainActor
    func testPrimaryAndSecondaryInstructions() throws {
        let expectation = expectation(
            description: "calculating directions with primary and secondary instructions should return results"
        )

        let queryParams: [String: String?] = [
            "alternatives": "false",
            "geometries": "polyline",
            "overview": "full",
            "steps": "true",
            "continue_straight": "true",
            "access_token": BogusToken,
            "voice_instructions": "true",
            "voice_units": "imperial",
            "banner_instructions": "true",
            "waypoint_names": "the hotel;the gym",
        ]

        stub(
            condition: isHost("api.mapbox.com")
                && containsQueryParams(queryParams)
        ) { _ in
            let path = Bundle.module.path(forResource: "instructions", ofType: "json")
            return HTTPStubsResponse(
                fileAtPath: path!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            )
        }

        let startWaypoint = Waypoint(
            location: CLLocation(latitude: 37.780602, longitude: -122.431373),
            heading: nil,
            name: "the hotel"
        )
        let endWaypoint = Waypoint(
            location: CLLocation(latitude: 37.758859, longitude: -122.404058),
            heading: nil,
            name: "the gym"
        )

        let options = RouteOptions(
            waypoints: [startWaypoint, endWaypoint],
            profileIdentifier: .automobileAvoidingTraffic
        )
        options.shapeFormat = .polyline
        options.includesSteps = true
        options.includesAlternativeRoutes = false
        options.routeShapeResolution = .full
        options.includesSpokenInstructions = true
        options.distanceMeasurementSystem = .imperial
        options.includesVisualInstructions = true
        var route: Route!
        let task = Directions(credentials: BogusCredentials).calculate(options) { result in
            switch result {
            case .failure(let error):
                XCTFail("Error! \(error)")
            case .success(let resp):
                Task { @MainActor [r = resp.routes?.first] in
                    route = r
                    expectation.fulfill()
                }
            }
        }
        XCTAssertNotNil(task)

        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error, "Error: \(error!.localizedDescription)")
            XCTAssertEqual(task.state, .completed)
        }
        _ = try XCTUnwrap(route)

        XCTAssertNotNil(route)

        let leg = route.legs.first!
        let step = leg.steps[1]

        XCTAssertEqual(step.instructionsSpokenAlongStep!.count, 3)

        let spokenInstructions = step.instructionsSpokenAlongStep!

        XCTAssertEqual(spokenInstructions[0].distanceAlongStep, 1107.1)
        XCTAssertEqual(
            spokenInstructions[0].ssmlText,
            "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">Continue on Baker Street for a half mile</prosody></amazon:effect></speak>"
        )
        XCTAssertEqual(spokenInstructions[0].text, "Continue on Baker Street for a half mile")
        XCTAssertEqual(
            spokenInstructions[1].ssmlText,
            "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">In 900 feet, turn left onto Page Street</prosody></amazon:effect></speak>"
        )
        XCTAssertEqual(spokenInstructions[1].text, "In 900 feet, turn left onto Page Street")
        XCTAssertEqual(
            spokenInstructions[2].ssmlText,
            "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">Turn left onto Page Street</prosody></amazon:effect></speak>"
        )
        XCTAssertEqual(spokenInstructions[2].text, "Turn left onto Page Street")

        let arrivalStep = leg.steps[leg.steps.endIndex - 2]
        XCTAssertEqual(arrivalStep.instructionsSpokenAlongStep!.count, 1)

        let arrivalSpokenInstructions = arrivalStep.instructionsSpokenAlongStep!
        XCTAssertEqual(arrivalSpokenInstructions[0].text, "You have arrived at the gym")
        XCTAssertEqual(
            arrivalSpokenInstructions[0].ssmlText,
            "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">You have arrived at the gym</prosody></amazon:effect></speak>"
        )

        let visualInstructions = step.instructionsDisplayedAlongStep
        XCTAssertNotNil(visualInstructions)

        XCTAssertEqual(visualInstructions?.first?.primaryInstruction.text, "Page Street")
        XCTAssertEqual(visualInstructions?.first?.distanceAlongStep, 1107.1)
        XCTAssertEqual(visualInstructions?.first?.primaryInstruction.finalHeading, nil)
        XCTAssertEqual(visualInstructions?.first?.primaryInstruction.maneuverType, .turn)
        XCTAssertEqual(visualInstructions?.first?.primaryInstruction.maneuverDirection, .left)

        if let firstComponent = visualInstructions?.first?.primaryInstruction.components.first,
           case VisualInstruction.Component.text(let text) = firstComponent
        {
            XCTAssertEqual(text.text, "Page Street")
            XCTAssertEqual(text.abbreviation, "Page St")
            XCTAssertEqual(text.abbreviationPriority, 0)
        } else {
            XCTFail("First primary component of visual instruction should be text component")
        }

        XCTAssertEqual(visualInstructions?.first?.drivingSide, .right)
        XCTAssertNil(visualInstructions?.first?.secondaryInstruction)

        let arrivalVisualInstructions = arrivalStep.instructionsDisplayedAlongStep!
        XCTAssertEqual(arrivalVisualInstructions.first?.secondaryInstruction?.text, "the gym")
    }

    @MainActor
    func testSubWithLaneInstructions() throws {
        let expectation =
            expectation(description: "calculating directions with tertiary lane instructions should return results")
        let queryParams: [String: String?] = [
            "geometries": "polyline",
            "steps": "true",
            "access_token": BogusToken,
            "banner_instructions": "true",
        ]

        stub(condition: isHost("api.mapbox.com") && containsQueryParams(queryParams)) { _ in
            let path = Bundle.module.path(forResource: "subLaneInstructions", ofType: "json")
            return HTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }

        let startWaypoint = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 39.132063, longitude: -84.531074))
        let endWaypoint = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 39.138953, longitude: -84.532934))

        let options = RouteOptions(
            waypoints: [startWaypoint, endWaypoint],
            profileIdentifier: .automobileAvoidingTraffic
        )
        options.shapeFormat = .polyline
        options.includesSteps = true
        options.includesAlternativeRoutes = false
        options.includesVisualInstructions = true

        var route: Route!
        let task = Directions(credentials: BogusCredentials).calculate(options) { result in
            switch result {
            case .failure(let error):
                XCTFail("Error! \(error)")
            case .success(let resp):
                Task { @MainActor [r = resp.routes?.first] in
                    route = r
                    expectation.fulfill()
                }
            }
        }
        XCTAssertNotNil(task)

        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error, "Error: \(error!.localizedDescription)")
            XCTAssertEqual(task.state, .completed)
        }

        _ = try XCTUnwrap(route)

        XCTAssertNotNil(route)

        let step = route.legs.first!.steps.first!
        let visualInstructions = step.instructionsDisplayedAlongStep

        let tertiaryInstruction = visualInstructions?.first?.tertiaryInstruction
        XCTAssertNotNil(tertiaryInstruction)
        XCTAssertEqual(tertiaryInstruction?.text, "")

        let laneIndicationComponents = tertiaryInstruction?.components.filter { component -> Bool in
            if case VisualInstruction.Component.lane = component {
                return true
            }
            return false
        }
        XCTAssertEqual(laneIndicationComponents?.count, 2)

        if let laneIndicationComponents, laneIndicationComponents.count > 1 {
            if case VisualInstruction.Component
                .lane(let indications, let isUsable, let preferredDirection) = laneIndicationComponents[0]
            {
                XCTAssertEqual(indications, .straightAhead)
                XCTAssertFalse(isUsable)
                XCTAssertEqual(preferredDirection, nil)
            }
            if case VisualInstruction.Component
                .lane(let indications, let isUsable, let preferredDirection) = laneIndicationComponents[1]
            {
                XCTAssertEqual(indications, .right)
                XCTAssertTrue(isUsable)
                XCTAssertEqual(preferredDirection, nil)
            }
        }
    }

    @MainActor
    func testSubWithVisualInstructions() throws {
        let expectation =
            expectation(description: "calculating directions with tertiary visual instructions should return results")
        let queryParams: [String: String?] = [
            "geometries": "polyline",
            "steps": "true",
            "access_token": BogusToken,
            "banner_instructions": "true",
        ]

        stub(condition: isHost("api.mapbox.com") && containsQueryParams(queryParams)) { _ in
            let path = Bundle.module.path(forResource: "subVisualInstructions", ofType: "json")
            return HTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }

        let startWaypoint = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.775469, longitude: -122.449158))
        let endWaypoint = Waypoint(coordinate: CLLocationCoordinate2D(
            latitude: 37.347439837741376,
            longitude: -121.92883115196378
        ))

        let options = RouteOptions(
            waypoints: [startWaypoint, endWaypoint],
            profileIdentifier: .automobileAvoidingTraffic
        )
        options.shapeFormat = .polyline
        options.includesSteps = true
        options.includesAlternativeRoutes = false
        options.includesVisualInstructions = true

        var route: Route!
        let task = Directions(credentials: BogusCredentials).calculate(options) { result in
            guard case .success(let resp) = result else {
                XCTFail("Encountered unexpected error. \(result)")
                return
            }
            Task { @MainActor [r = resp.routes?.first] in
                route = r
                expectation.fulfill()
            }
        }
        XCTAssertNotNil(task)

        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error, "Error: \(error!.localizedDescription)")
            XCTAssertEqual(task.state, .completed)
        }

        _ = try XCTUnwrap(route)

        let step = route.legs.first!.steps.first!
        let visualInstructions = step.instructionsDisplayedAlongStep

        let tertiaryInstruction = visualInstructions?.first?.tertiaryInstruction
        XCTAssertNotNil(tertiaryInstruction)
        XCTAssertEqual(tertiaryInstruction?.text, "Grove Street")
        XCTAssertEqual(tertiaryInstruction?.maneuverType, .turn)
        XCTAssertEqual(tertiaryInstruction?.maneuverDirection, .left)

        let tertiaryInstructionComponent = tertiaryInstruction?.components.first { component -> Bool in
            if case VisualInstruction.Component.text(let textRepresentation) = component {
                XCTAssertEqual(textRepresentation.text, "Grove Street")
                XCTAssertEqual(textRepresentation.abbreviation, "Grove St")
                XCTAssertEqual(textRepresentation.abbreviationPriority, 0)
                return true
            }
            return false
        }
        XCTAssertNotNil(tertiaryInstructionComponent)
    }
}
#endif
