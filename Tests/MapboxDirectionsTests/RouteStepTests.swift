@testable import MapboxDirections
import Turf
import XCTest

class RoadTests: XCTestCase {
    func testEmpty() {
        let r = Road(name: "", ref: nil, exits: nil, destination: nil, rotaryName: nil)
        XCTAssertNil(r.names)
        XCTAssertNil(r.codes)
        XCTAssertNil(r.exitCodes)
        XCTAssertNil(r.destinations)
        XCTAssertNil(r.destinationCodes)
        XCTAssertNil(r.rotaryNames)
    }

    func testNamesCodes() {
        var r: Road

        // Name only
        r = Road(name: "Way Name", ref: nil, exits: nil, destination: nil, rotaryName: nil)
        XCTAssertEqual(r.names ?? [], ["Way Name"])
        XCTAssertNil(r.codes)
        r = Road(name: "Way Name 1; Way Name 2", ref: nil, exits: nil, destination: nil, rotaryName: nil)
        XCTAssertEqual(r.names ?? [], ["Way Name 1", "Way Name 2"])
        XCTAssertNil(r.codes)

        // Ref only
        r = Road(name: "", ref: "Ref 1", exits: nil, destination: nil, rotaryName: nil)
        XCTAssertNil(r.names)
        XCTAssertEqual(r.codes ?? [], ["Ref 1"])
        r = Road(name: "", ref: "Ref 1; Ref 2", exits: nil, destination: nil, rotaryName: nil)
        XCTAssertNil(r.names)
        XCTAssertEqual(r.codes ?? [], ["Ref 1", "Ref 2"])

        // Separate Name and Ref
        r = Road(name: "Way Name", ref: "Ref 1", exits: nil, destination: nil, rotaryName: nil)
        XCTAssertEqual(r.names ?? [], ["Way Name"])
        XCTAssertEqual(r.codes ?? [], ["Ref 1"])
        r = Road(name: "Way Name 1; Way Name 2", ref: "Ref 1; Ref 2", exits: nil, destination: nil, rotaryName: nil)
        XCTAssertEqual(r.names ?? [], ["Way Name 1", "Way Name 2"])
        XCTAssertEqual(r.codes ?? [], ["Ref 1", "Ref 2"])
        r = Road(name: "Way Name 1;Way Name 2", ref: "Ref 1;Ref 2", exits: nil, destination: nil, rotaryName: nil)
        XCTAssertEqual(r.names ?? [], ["Way Name 1", "Way Name 2"])
        XCTAssertEqual(r.codes ?? [], ["Ref 1", "Ref 2"])

        // Ref duplicated in Name (Mapbox Directions API v5)
        r = Road(name: "Way Name (Ref)", ref: "Ref", exits: nil, destination: nil, rotaryName: nil)
        XCTAssertEqual(r.names ?? [], ["Way Name"])
        XCTAssertEqual(r.codes ?? [], ["Ref"])
        r = Road(
            name: "Way Name 1; Way Name 2 (Ref 1; Ref 2)",
            ref: "Ref 1; Ref 2",
            exits: nil,
            destination: nil,
            rotaryName: nil
        )
        XCTAssertEqual(r.names ?? [], ["Way Name 1", "Way Name 2"])
        XCTAssertEqual(r.codes ?? [], ["Ref 1", "Ref 2"])
        r = Road(name: "Ref 1; Ref 2", ref: "Ref 1; Ref 2", exits: nil, destination: nil, rotaryName: nil)
        XCTAssertNil(r.names)
        XCTAssertEqual(r.codes ?? [], ["Ref 1", "Ref 2"])
    }

    func testRotaryNames() {
        var r: Road

        r = Road(name: "", ref: nil, exits: nil, destination: nil, rotaryName: "Rotary Name")
        XCTAssertEqual(r.rotaryNames ?? [], ["Rotary Name"])
        r = Road(
            name: "",
            ref: nil,
            exits: nil,
            destination: nil,
            rotaryName: "Rotary Name 1;Rotary Name 2"
        )
        XCTAssertEqual(r.rotaryNames ?? [], ["Rotary Name 1", "Rotary Name 2"])
    }

    func testExitCodes() {
        var r: Road

        r = Road(name: "", ref: nil, exits: "123 A", destination: nil, rotaryName: nil)
        XCTAssertEqual(r.exitCodes ?? [], ["123 A"])
        r = Road(name: "", ref: nil, exits: "123A;123B", destination: nil, rotaryName: nil)
        XCTAssertEqual(r.exitCodes ?? [], ["123A", "123B"])
    }

    func testDestinations() {
        var r: Road

        // No ref
        r = Road(name: "", ref: nil, exits: nil, destination: "Destination", rotaryName: nil)
        XCTAssertEqual(r.destinations ?? [], ["Destination"])
        XCTAssertNil(r.destinationCodes)
        r = Road(name: "", ref: nil, exits: nil, destination: "Destination 1, Destination 2", rotaryName: nil)
        XCTAssertEqual(r.destinations ?? [], ["Destination 1", "Destination 2"])
        XCTAssertNil(r.destinationCodes)

        // With ref
        r = Road(name: "", ref: nil, exits: nil, destination: "Ref 1: Destination", rotaryName: nil)
        XCTAssertEqual(r.destinations ?? [], ["Destination"])
        XCTAssertEqual(r.destinationCodes ?? [], ["Ref 1"])
        r = Road(
            name: "",
            ref: nil,
            exits: nil,
            destination: "Ref 1, Ref 2: Destination 1, Destination 2, Destination 3",
            rotaryName: nil
        )
        XCTAssertEqual(r.destinations ?? [], ["Destination 1", "Destination 2", "Destination 3"])
        XCTAssertEqual(r.destinationCodes ?? [], ["Ref 1", "Ref 2"])
    }
}

class RouteStepTests: XCTestCase {
    func testDecoding() {
        // Derived from <https://api.mapbox.com/directions/v5/mapbox/driving-traffic/-122.22060192394258,37.853964632136226;-122.22001854348318,37.85415735273948?geometries=polyline&steps=true&overview=full&access_token=pk.feedcafedeadbeef>
        let stepJSON = [
            "driving_side": "right",
            "geometry": "ek`fFxc~hVIu@",
            "mode": "driving",
            "maneuver": [
                "bearing_after": 73,
                "bearing_before": 60,
                "location": [37.854109, -122.220291],
                "modifier": "slight right",
                "type": "fork",
                "instruction": "Keep right onto CA 24",
            ],
            "ref": "CA 24",
            "weight": 2.5,
            "duration": 2.55,
            "duration_typical": 2.369,
            "name": "Grove Shafter Freeway",
            "pronunciation": "ˈaɪˌfoʊ̯n ˈtɛn",
            "distance": 24.50001,
        ] as [String: Any?]

        let stepData = try! JSONSerialization.data(withJSONObject: stepJSON, options: [])
        var step: RouteStep?
        XCTAssertNoThrow(step = try JSONDecoder().decode(RouteStep.self, from: stepData))
        XCTAssertNotNil(step)

        if let step {
            XCTAssertEqual(step.drivingSide, .right)
            XCTAssertEqual(step.transportType, .automobile)
            XCTAssertEqual(step.shape?.coordinates.count, 2)
            XCTAssertEqual(step.shape?.coordinates.first?.latitude ?? 0, 37.854109, accuracy: 1e-5)
            XCTAssertEqual(step.shape?.coordinates.first?.longitude ?? 0, -122.220291, accuracy: 1e-5)
            XCTAssertEqual(step.shape?.coordinates.last?.latitude ?? 0, 37.854164, accuracy: 1e-5)
            XCTAssertEqual(step.shape?.coordinates.last?.longitude ?? 0, -122.220021, accuracy: 1e-5)
            XCTAssertEqual(step.finalHeading, 73)
            XCTAssertEqual(step.initialHeading, 60)
            XCTAssertEqual(step.maneuverLocation, LocationCoordinate2D(latitude: -122.220291, longitude: 37.854109))
            XCTAssertEqual(step.maneuverDirection, .slightRight)
            XCTAssertEqual(step.maneuverType, .reachFork)
            XCTAssertEqual(step.instructions, "Keep right onto CA 24")
            XCTAssertEqual(step.codes, ["CA 24"])
            XCTAssertEqual(step.expectedTravelTime, 2.55)
            XCTAssertEqual(step.typicalTravelTime, 2.369)
            XCTAssertEqual(step.names, ["Grove Shafter Freeway"])
            XCTAssertEqual(step.phoneticNames, ["ˈaɪˌfoʊ̯n ˈtɛn"])
            XCTAssertEqual(step.distance, 24.50001)
        }
    }

    func testCoding() {
        let options = RouteOptions(coordinates: [
            LocationCoordinate2D(latitude: 52.50881, longitude: 13.42467),
            LocationCoordinate2D(latitude: 52.506794, longitude: 13.42326),
        ])
        options.shapeFormat = .polyline

        var stepJSON = [
            "intersections": [
                [
                    "out": 1,
                    "location": [13.424671, 52.508812],
                    "bearings": [120, 210, 300],
                    "entry": [false, true, true],
                    "in": 0,
                    "lanes": [
                        [
                            "valid": true,
                            "active": true,
                            "valid_indication": "left",
                            "indications": ["left"],
                        ],
                        [
                            "valid": false,
                            "active": false,
                            "indications": ["straight"],
                        ],
                        [
                            "valid": false,
                            "active": false,
                            "indications": ["right"],
                        ],
                    ],
                ],
            ],
            "geometry": "asn_Ie_}pAdKxG",
            "maneuver": [
                "bearing_after": 202,
                "type": "turn",
                "modifier": "left",
                "bearing_before": 299,
                "location": [13.424671, 52.508812],
                "instruction": "Turn left onto Adalbertstraße",
            ],
            "duration": 59.1,
            "duration_typical": 45.0,
            "distance": 236.9,
            "driving_side": "right",
            "weight": 59.1,
            "name": "Adalbertstraße",
            "mode": "driving",
            "speedLimitSign": "vienna",
            "speedLimitUnit": "km/h",
        ] as [String: Any?]
        var stepData = try! JSONSerialization.data(withJSONObject: stepJSON, options: [])

        let decoder = JSONDecoder()
        decoder.userInfo[.options] = options
        decoder.userInfo[.includesForeignMembers] = true
        var step: RouteStep?
        XCTAssertNoThrow(step = try decoder.decode(RouteStep.self, from: stepData))
        XCTAssertNotNil(step)

        if let step {
            XCTAssertEqual(step.speedLimitSignStandard, SignStandard.viennaConvention)
            XCTAssertEqual(step.speedLimitUnit, UnitSpeed.kilometersPerHour)
        }

        let encoder = JSONEncoder()
        encoder.userInfo[.options] = options
        encoder.userInfo[.includesForeignMembers] = true
        var encodedStepData: Data?
        if let step {
            XCTAssertNoThrow(encodedStepData = try encoder.encode(step))
            XCTAssertNotNil(encodedStepData)

            if let encodedStepData {
                var encodedStepJSON: Any?
                XCTAssertNoThrow(encodedStepJSON = try JSONSerialization.jsonObject(with: encodedStepData, options: []))
                XCTAssertNotNil(encodedStepJSON)

                XCTAssert(JSONSerialization.objectsAreEqual(stepJSON, encodedStepJSON, approximate: true))
            }
        }

        options.shapeFormat = .polyline6
        stepJSON["geometry"] = "sg{ccB{`krXzxBbwAvB?"
        stepData = try! JSONSerialization.data(withJSONObject: stepJSON, options: [])
        XCTAssertNoThrow(step = try decoder.decode(RouteStep.self, from: stepData))
        XCTAssertNotNil(step)

        if let step {
            XCTAssertEqual(step.shape?.coordinates.count, 3)
            XCTAssertEqual(step.shape?.coordinates.first?.latitude ?? 0, 52.50881, accuracy: 1e-5)
            XCTAssertEqual(step.shape?.coordinates.first?.longitude ?? 0, 13.42467, accuracy: 1e-5)
            XCTAssertEqual(step.shape?.coordinates.last?.latitude ?? 0, 52.506794, accuracy: 1e-5)
            XCTAssertEqual(step.shape?.coordinates.last?.longitude ?? 0, 13.42326, accuracy: 1e-5)

            XCTAssertEqual(step.expectedTravelTime, 59.1)
            XCTAssertEqual(step.typicalTravelTime, 45.0)

            XCTAssertNoThrow(encodedStepData = try encoder.encode(step))
            XCTAssertNotNil(encodedStepData)

            if let encodedStepData {
                var encodedStepJSON: Any?
                XCTAssertNoThrow(encodedStepJSON = try JSONSerialization.jsonObject(with: encodedStepData, options: []))
                XCTAssertNotNil(encodedStepJSON)

                XCTAssert(JSONSerialization.objectsAreEqual(stepJSON, encodedStepJSON, approximate: true))
            }
        }
    }

    func testEncodingPronunciations() {
        let options = RouteOptions(coordinates: [
            LocationCoordinate2D(latitude: 0, longitude: 0),
            LocationCoordinate2D(latitude: 1, longitude: 1),
        ])
        let step = RouteStep(
            transportType: .automobile,
            maneuverLocation: LocationCoordinate2D(latitude: 0, longitude: 0),
            maneuverType: .turn,
            maneuverDirection: .left,
            instructions: "",
            initialHeading: 0,
            finalHeading: 0,
            drivingSide: .right,
            distance: 10,
            expectedTravelTime: 10,
            names: ["iPhone X", "iPhone XS"],
            phoneticNames: ["ˈaɪˌfoʊ̯n ˈtɛn", "ˈaɪˌfoʊ̯n ˈtɛnz"]
        )

        let encoder = JSONEncoder()
        encoder.userInfo[.options] = options
        var encodedStepData: Data?
        XCTAssertNoThrow(encodedStepData = try encoder.encode(step))
        XCTAssertNotNil(encodedStepData)

        if let encodedStepData {
            var encodedStepJSON: [String: Any?]?
            XCTAssertNoThrow(
                encodedStepJSON = try JSONSerialization
                    .jsonObject(with: encodedStepData, options: []) as? [String: Any?]
            )
            XCTAssertNotNil(encodedStepJSON)

            XCTAssertEqual(encodedStepJSON?["pronunciation"] as? String, "ˈaɪˌfoʊ̯n ˈtɛn; ˈaɪˌfoʊ̯n ˈtɛnz")
        }
    }

    func testRouteStepTypicalTravelTime() {
        let typicalTravelTime = 2.5

        let route = RouteStep(
            transportType: .automobile,
            maneuverLocation: LocationCoordinate2D(latitude: 0, longitude: 0),
            maneuverType: .turn,
            instructions: "",
            drivingSide: .left,
            distance: 2.0,
            expectedTravelTime: 2.0,
            typicalTravelTime: typicalTravelTime
        )

        XCTAssertEqual(route.typicalTravelTime, typicalTravelTime)
    }

    func testIncidentsCoding() {
        let path = Bundle.module.path(forResource: "incidents", ofType: "json")
        let filePath = URL(fileURLWithPath: path!)
        let data = try! Data(contentsOf: filePath)
        let options = RouteOptions(coordinates: [
            LocationCoordinate2D(latitude: 37.78, longitude: -122.42),
            LocationCoordinate2D(latitude: 38.91, longitude: -77.03),
        ])

        let decoder = JSONDecoder()
        decoder.userInfo[.options] = options
        decoder.userInfo[.credentials] = Credentials(accessToken: "foo", host: URL(string: "http://sample.website"))
        let result = try! decoder.decode(RouteResponse.self, from: data)

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
            guard let leg = newRoute?.legs.first else {
                XCTFail("No legs found"); return
            }

            XCTAssert(leg.incidents!.first!.kind == Incident.Kind.miscellaneous)
            XCTAssert(leg.incidents!.first!.impact == Incident.Impact.minor)
            XCTAssert(leg.incidents![0].lanesBlocked!.contains(.right))
            XCTAssert(leg.incidents![0].countryCodeAlpha3 == "DEU")
            XCTAssert(leg.incidents![0].countryCode == "DE")
            XCTAssert(leg.incidents![0].congestionLevel == 50)
            XCTAssert(leg.incidents![0].affectedRoadNames?.count == 2)
            XCTAssertNil(leg.incidents![1].lanesBlocked)
            XCTAssertTrue(leg.incidents![1].roadIsClosed!)
            XCTAssert(leg.incidents![2].lanesBlocked!.isEmpty)
            XCTAssert(leg.incidents![2].shapeIndexRange == 810..<900)
            XCTAssert(leg.incidents![2].numberOfBlockedLanes == 1)
            XCTAssertNil(leg.incidents![2].roadIsClosed)
            XCTAssert(leg.incidents!.first! == leg.incidents!.first!)

            XCTAssert(leg.steps.contains(where: { $0.exitIndex != nil }))
        }
    }
}
