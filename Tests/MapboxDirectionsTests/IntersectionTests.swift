@testable import MapboxDirections
import Turf
import XCTest

class IntersectionTests: XCTestCase {
    func testCoding() {
        let intersectionsJSON: [[String: Any?]] = [
            [
                "out": 0,
                "in": -1,
                "entry": [true],
                "bearings": [80],
                "location": [13.426579, 52.508068],
                "classes": ["toll", "restricted"],
                "mapbox_streets_v8": [
                    "class": "street_limited",
                ],
                "toll_collection": [
                    "type": "toll_booth",
                    "name": "test toll booth",
                ],
                "railway_crossing": true,
                "traffic_signal": true,
                "stop_sign": false,
                "yield_sign": false,
                "ic": ["name": "IC test"],
                "jct": ["name": "JCT test"],
            ],
            [
                "out": 1,
                "in": 2,
                "entry": [false, true, true],
                "bearings": [30, 120, 300],
                "location": [13.426688, 52.508022],
            ],
            [
                "lanes": [
                    [
                        "valid": true,
                        "active": false,
                        "valid_indication": "straight",
                        "indications": ["straight"],
                    ],
                    [
                        "valid": true,
                        "active": true,
                        "valid_indication": "straight",
                        "indications": ["right", "straight"],
                    ],
                ],
                "out": 0,
                "in": 2,
                "entry": [true, true, false],
                "bearings": [45, 135, 255],
                "location": [-84.503956, 39.102483],
            ],
        ]
        let intersectionsData = try! JSONSerialization.data(withJSONObject: intersectionsJSON, options: [])
        var intersections: [Intersection]?
        XCTAssertNoThrow(intersections = try JSONDecoder().decode([Intersection].self, from: intersectionsData))
        XCTAssertEqual(intersections?.count, 3)

        if let intersection = intersections?.first {
            XCTAssertEqual(intersection.outletRoadClasses, [.toll, .restricted])
            XCTAssertEqual(intersection.headings, [80.0])
            XCTAssertEqual(intersection.location, LocationCoordinate2D(latitude: 52.508068, longitude: 13.426579))
            XCTAssertEqual(intersection.outletMapboxStreetsRoadClass, MapboxStreetsRoadClass.streetLimited)
            XCTAssertEqual(intersection.railroadCrossing, true)
            XCTAssertEqual(intersection.trafficSignal, true)
            XCTAssertEqual(intersection.stopSign, false)
            XCTAssertEqual(intersection.yieldSign, false)
        }

        intersections = [
            Intersection(
                location: LocationCoordinate2D(latitude: 52.508068, longitude: 13.426579),
                headings: [79.5],
                approachIndex: -1,
                outletIndex: 0,
                outletIndexes: IndexSet([0]),
                approachLanes: nil,
                usableApproachLanes: nil,
                preferredApproachLanes: nil,
                laneValidIndications: nil,
                outletRoadClasses: [.toll, .restricted],
                tollCollection: TollCollection(type: .booth, name: "test toll booth"),
                tunnelName: nil,
                restStop: nil,
                isUrban: nil,
                outletMapboxStreetsRoadClass: .streetLimited,
                railroadCrossing: true,
                trafficSignal: true,
                stopSign: false,
                yieldSign: false,
                interchange: Interchange(name: "IC test"),
                junction: Junction(name: "JCT test")
            ),
            Intersection(
                location: LocationCoordinate2D(latitude: 52.508022, longitude: 13.426688),
                headings: [30.0, 120.0, 300.0],
                approachIndex: 2,
                outletIndex: 1,
                outletIndexes: IndexSet([1, 2]),
                approachLanes: nil,
                usableApproachLanes: nil,
                preferredApproachLanes: nil,
                laneValidIndications: nil,
                outletRoadClasses: nil,
                tollCollection: nil,
                tunnelName: nil,
                restStop: nil,
                isUrban: nil
            ),
            Intersection(
                location: LocationCoordinate2D(latitude: 39.102483, longitude: -84.503956),
                headings: [45, 135, 255],
                approachIndex: 2,
                outletIndex: 0,
                outletIndexes: IndexSet([0, 1]),
                approachLanes: [.straightAhead, [.straightAhead, .right]],
                usableApproachLanes: IndexSet([0, 1]),
                preferredApproachLanes: IndexSet([1]),
                laneValidIndications: [.straightAhead, .straightAhead],
                outletRoadClasses: nil,
                tollCollection: nil,
                tunnelName: nil,
                restStop: nil,
                isUrban: nil
            ),
        ]

        let encoder = JSONEncoder()
        var encodedData: Data?
        XCTAssertNoThrow(encodedData = try encoder.encode(intersections))
        XCTAssertNotNil(encodedData)

        if let encodedData {
            var encodedIntersectionsJSON: [[String: Any?]]?
            XCTAssertNoThrow(encodedIntersectionsJSON = try JSONSerialization.jsonObject(
                with: encodedData,
                options: []
            ) as? [[String: Any?]])
            XCTAssertNotNil(encodedIntersectionsJSON)

            XCTAssert(JSONSerialization.objectsAreEqual(intersectionsJSON, encodedIntersectionsJSON, approximate: true))
        }
    }

    func testJunctionDecoding() throws {
        let routeData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.module.path(
            forResource: "intersections",
            ofType: "json"
        )!))
        let routeOptions = RouteOptions(coordinates: [
            LocationCoordinate2D(latitude: 37.78, longitude: -122.42),
            LocationCoordinate2D(latitude: 38.91, longitude: -77.03),
        ])

        let decoder = JSONDecoder()
        decoder.userInfo[.options] = routeOptions
        decoder.userInfo[.credentials] = Credentials(
            accessToken: "access_token",
            host: URL(string: "http://test_host.com")
        )

        let routeResponse = try decoder.decode(RouteResponse.self, from: routeData)
        guard let steps = routeResponse.routes?.first?.legs.first?.steps,
              steps.count > 1,
              let intersections = steps[1].intersections
        else {
            XCTFail("Should have intersections.")
            return
        }
        XCTAssertEqual(intersections.first?.junction?.name, "JCT NAME")
        XCTAssertEqual(intersections.first?.interchange?.name, "IC NAME")
    }

    // MARK: - Differing `valid_indication`s across the lanes of one intersection

    /// A lane of the intersection built by ``intersectionJSONWithLanes(_:)``. A `nil` field omits the
    /// corresponding key from the lane object altogether.
    private struct LaneJSON {
        var indications: [String]? = ["straight"]
        var validIndication: String?
        var isValid: Bool? = true
        var isActive: Bool? = false
    }

    /// Builds a single-intersection JSON array with the given lanes. Every property other than the lanes is
    /// fixed, so this is only useful to tests that exercise lane decoding.
    private func intersectionJSONWithLanes(_ lanes: [LaneJSON]) -> [String: Any] {
        [
            "lanes": lanes.map { lane -> [String: Any] in
                var laneJSON: [String: Any] = [:]
                if let indications = lane.indications {
                    laneJSON["indications"] = indications
                }
                if let isValid = lane.isValid {
                    laneJSON["valid"] = isValid
                }
                if let isActive = lane.isActive {
                    laneJSON["active"] = isActive
                }
                if let validIndication = lane.validIndication {
                    laneJSON["valid_indication"] = validIndication
                }
                return laneJSON
            },
            "out": 0,
            "in": 1,
            "entry": [true, false],
            "bearings": [0, 180],
            "location": [-84.503956, 39.102483],
        ]
    }

    private func decodeIntersectionWithLanes(_ lanes: [LaneJSON]) throws -> Intersection {
        let data = try JSONSerialization.data(withJSONObject: [intersectionJSONWithLanes(lanes)], options: [])
        return try JSONDecoder().decode([Intersection].self, from: data)[0]
    }

    /// An intersection whose lanes have differing `valid_indication`s, for example one lane "straight" and
    /// another "slight right", must decode without throwing. This is spec-compliant data per the Directions
    /// API lane object documentation, not malformed data:
    /// https://docs.mapbox.com/api/navigation/directions/#lane-object
    func testDifferingValidIndicationsDoNotThrow() {
        let lanes = [
            LaneJSON(indications: ["straight"], validIndication: "straight", isValid: true, isActive: false),
            LaneJSON(
                indications: ["right", "slight right"],
                validIndication: "slight right",
                isValid: true,
                isActive: true
            ),
        ]
        XCTAssertNoThrow(try decodeIntersectionWithLanes(lanes))
    }

    /// Each lane keeps its own `valid_indication`, in lane order, instead of the intersection collapsing them
    /// to a single value.
    func testLaneValidIndicationsArePerLane() throws {
        let lanes = [
            LaneJSON(indications: ["straight"], validIndication: "straight", isValid: true, isActive: false),
            LaneJSON(
                indications: ["right", "slight right"],
                validIndication: "slight right",
                isValid: true,
                isActive: true
            ),
        ]
        let intersection = try decodeIntersectionWithLanes(lanes)
        XCTAssertEqual(intersection.laneValidIndications, [.straightAhead, .slightRight])
        XCTAssertEqual(intersection.approachLanes, [.straightAhead, [.right, .slightRight]])
        XCTAssertEqual(intersection.usableApproachLanes, IndexSet([0, 1]))
        XCTAssertEqual(intersection.preferredApproachLanes, IndexSet([1]))
    }

    /// A lane that is not usable typically has no `valid_indication` of its own, but it still occupies an entry
    /// in `laneValidIndications`, so the array stays parallel to `approachLanes`.
    func testLaneValidIndicationsAreParallelToApproachLanes() throws {
        let lanes = [
            LaneJSON(indications: ["left"], validIndication: nil, isValid: false, isActive: false),
            LaneJSON(indications: ["straight"], validIndication: "straight", isValid: true, isActive: true),
            LaneJSON(indications: ["right"], validIndication: nil, isValid: false, isActive: false),
        ]
        let intersection = try decodeIntersectionWithLanes(lanes)
        XCTAssertEqual(intersection.laneValidIndications, [nil, .straightAhead, nil])
        XCTAssertEqual(intersection.laneValidIndications?.count, intersection.approachLanes?.count)
    }

    /// The uniform case, where every lane agrees, keeps producing the values it did before per-lane indications
    /// were introduced.
    @available(*, deprecated)
    func testUniformValidIndicationsAreUnchanged() throws {
        let lanes = [
            LaneJSON(indications: ["straight"], validIndication: "straight", isValid: true, isActive: false),
            LaneJSON(indications: ["right", "straight"], validIndication: "straight", isValid: true, isActive: true),
        ]
        let intersection = try decodeIntersectionWithLanes(lanes)
        XCTAssertEqual(intersection.laneValidIndications, [.straightAhead, .straightAhead])
        XCTAssertEqual(intersection.usableLaneIndication, .straightAhead)
    }

    /// When the lanes disagree, the deprecated single-value property resolves to the preferred lane's
    /// indication, so existing consumers keep getting a value that is meaningful for the route.
    @available(*, deprecated)
    func testDeprecatedUsableLaneIndicationPrefersPreferredLane() throws {
        let lanes = [
            LaneJSON(indications: ["straight"], validIndication: "straight", isValid: true, isActive: false),
            LaneJSON(
                indications: ["right", "slight right"],
                validIndication: "slight right",
                isValid: true,
                isActive: true
            ),
        ]
        let intersection = try decodeIntersectionWithLanes(lanes)
        XCTAssertEqual(intersection.usableLaneIndication, .slightRight)
    }

    /// With no preferred lane, the deprecated single-value property falls back to a usable lane's indication.
    @available(*, deprecated)
    func testDeprecatedUsableLaneIndicationFallsBackToUsableLane() throws {
        let lanes = [
            LaneJSON(indications: ["straight"], validIndication: "straight", isValid: false, isActive: false),
            LaneJSON(
                indications: ["right", "slight right"],
                validIndication: "slight right",
                isValid: true,
                isActive: false
            ),
        ]
        let intersection = try decodeIntersectionWithLanes(lanes)
        XCTAssertEqual(intersection.laneValidIndications, [.straightAhead, .slightRight])
        XCTAssertEqual(intersection.usableLaneIndication, .slightRight)
    }

    /// With neither a preferred nor a usable lane — data the Directions API is not expected to return, but
    /// which the SDK must still resolve deterministically — the deprecated single-value property falls back to
    /// the first lane's indication. Every lane's own indication remains available.
    @available(*, deprecated)
    func testDeprecatedUsableLaneIndicationFallsBackToFirstLane() throws {
        let lanes = [
            LaneJSON(indications: ["straight"], validIndication: "straight", isValid: false, isActive: false),
            LaneJSON(
                indications: ["right", "slight right"],
                validIndication: "slight right",
                isValid: false,
                isActive: false
            ),
        ]
        let intersection = try decodeIntersectionWithLanes(lanes)
        XCTAssertEqual(intersection.laneValidIndications, [.straightAhead, .slightRight])
        XCTAssertEqual(intersection.usableLaneIndication, .straightAhead)
    }

    /// An empty `valid_indication` is a value the SDK cannot act on, so it decodes to
    /// ``ManeuverDirection/undefined`` — distinct from `nil`, which means the field was absent — and must not
    /// fail the decoding of the intersection.
    @available(*, deprecated)
    func testEmptyValidIndicationDecodesAsUndefined() throws {
        let lanes = [
            LaneJSON(indications: ["straight"], validIndication: "", isValid: true, isActive: false),
            LaneJSON(indications: ["right", "straight"], validIndication: "straight", isValid: true, isActive: true),
        ]
        let intersection = try decodeIntersectionWithLanes(lanes)
        XCTAssertEqual(intersection.laneValidIndications, [.undefined, .straightAhead])
        XCTAssertEqual(intersection.usableLaneIndication, .straightAhead)
    }

    /// An intersection where every lane has an empty `valid_indication` — the payload that caused the
    /// incident — still decodes.
    @available(*, deprecated)
    func testAllEmptyValidIndicationsDecodeAsUndefined() throws {
        let lanes = [
            LaneJSON(indications: ["straight"], validIndication: "", isValid: true, isActive: false),
            LaneJSON(indications: ["right", "straight"], validIndication: "", isValid: true, isActive: true),
        ]
        let intersection = try decodeIntersectionWithLanes(lanes)
        XCTAssertEqual(intersection.laneValidIndications, [.undefined, .undefined])
        XCTAssertEqual(intersection.usableLaneIndication, .undefined)
    }

    /// An intersection where no lane has a `valid_indication` still decodes, with a `nil` entry per lane.
    @available(*, deprecated)
    func testMissingValidIndicationsDecodeAsNoIndications() throws {
        let lanes = [
            LaneJSON(indications: ["straight"], validIndication: nil, isValid: true, isActive: false),
            LaneJSON(indications: ["right", "straight"], validIndication: nil, isValid: true, isActive: true),
        ]
        let intersection = try decodeIntersectionWithLanes(lanes)
        XCTAssertEqual(intersection.laneValidIndications, [nil, nil])
        XCTAssertNil(intersection.usableLaneIndication)
    }

    /// An unrecognized, non-empty `valid_indication` decodes to ``ManeuverDirection/undefined`` as well,
    /// rather than failing the route.
    func testUnrecognizedValidIndication() throws {
        let intersection = try decodeIntersectionWithLanes([
            LaneJSON(indications: ["straight"], validIndication: "sideways", isValid: true, isActive: true),
        ])
        XCTAssertEqual(intersection.laneValidIndications, [.undefined])
    }

    /// The optional `active` field may be missing, in which case no lane is preferred.
    func testMissingActiveKeyDecodes() throws {
        let lanes = [
            LaneJSON(indications: ["straight"], validIndication: "straight", isValid: true, isActive: nil),
        ]
        let intersection = try decodeIntersectionWithLanes(lanes)
        XCTAssertEqual(intersection.preferredApproachLanes, IndexSet())
        XCTAssertEqual(intersection.usableApproachLanes, IndexSet([0]))
        XCTAssertEqual(intersection.laneValidIndications, [.straightAhead])
    }

    /// The `valid` and `indications` fields are required by the Directions API, so a lane object missing either
    /// of them is malformed and does throw.
    func testMissingRequiredLaneKeysThrow() {
        XCTAssertThrowsError(try decodeIntersectionWithLanes([
            LaneJSON(indications: ["straight"], validIndication: "straight", isValid: nil, isActive: false),
        ]))
        XCTAssertThrowsError(try decodeIntersectionWithLanes([
            LaneJSON(indications: nil, validIndication: "straight", isValid: true, isActive: false),
        ]))
    }

    /// Differing per-lane indications survive a round trip through encoding.
    func testDifferingValidIndicationsRoundTrip() throws {
        let lanes = [
            LaneJSON(indications: ["straight"], validIndication: "straight", isValid: true, isActive: false),
            LaneJSON(
                indications: ["right", "slight right"],
                validIndication: "slight right",
                isValid: true,
                isActive: true
            ),
        ]
        let intersection = try decodeIntersectionWithLanes(lanes)

        let encodedData = try JSONEncoder().encode([intersection])
        let roundTripped = try JSONDecoder().decode([Intersection].self, from: encodedData)

        XCTAssertEqual(roundTripped.first?.laneValidIndications, [.straightAhead, .slightRight])
        XCTAssertEqual(roundTripped.first, intersection)
    }

    /// An `Intersection` constructed with the deprecated initializer has no per-lane indications, so encoding
    /// keeps broadcasting its single indication to every usable lane that can take it.
    @available(*, deprecated)
    func testDeprecatedInitializerBroadcastsSingleIndicationWhenEncoding() throws {
        let intersection = Intersection(
            location: LocationCoordinate2D(latitude: 39.102483, longitude: -84.503956),
            headings: [45, 135, 255],
            approachIndex: 2,
            outletIndex: 0,
            outletIndexes: IndexSet([0, 1]),
            approachLanes: [.straightAhead, [.straightAhead, .right], .right],
            usableApproachLanes: IndexSet([0, 1]),
            preferredApproachLanes: IndexSet([1]),
            usableLaneIndication: .straightAhead
        )
        XCTAssertNil(intersection.laneValidIndications)
        XCTAssertEqual(intersection.usableLaneIndication, .straightAhead)

        let encodedData = try JSONEncoder().encode([intersection])
        let roundTripped = try JSONDecoder().decode([Intersection].self, from: encodedData)
        XCTAssertEqual(roundTripped.first?.laneValidIndications, [.straightAhead, .straightAhead, nil])
        XCTAssertEqual(roundTripped.first?.usableLaneIndication, .straightAhead)
    }

    /// A full route response containing an intersection whose lanes disagree decodes successfully, not just an
    /// isolated `Intersection`.
    @available(*, deprecated)
    func testDifferingValidIndicationsInRouteResponse() throws {
        let routeData = try Data(contentsOf: URL(fileURLWithPath: Bundle.module.path(
            forResource: "intersections",
            ofType: "json"
        )!))
        var json = try JSONSerialization.jsonObject(with: routeData) as! [String: Any]
        var routes = json["routes"] as! [[String: Any]]
        var legs = routes[0]["legs"] as! [[String: Any]]
        var steps = legs[0]["steps"] as! [[String: Any]]
        var intersections = steps[6]["intersections"] as! [[String: Any]]
        intersections[0]["lanes"] = [
            ["valid": true, "active": false, "valid_indication": "left", "indications": ["left"]],
            ["valid": true, "active": true, "valid_indication": "straight", "indications": ["straight", "left"]],
            ["valid": false, "active": false, "indications": ["right"]],
        ]
        steps[6]["intersections"] = intersections
        legs[0]["steps"] = steps
        routes[0]["legs"] = legs
        json["routes"] = routes
        let mutatedData = try JSONSerialization.data(withJSONObject: json)

        let routeOptions = RouteOptions(coordinates: [
            LocationCoordinate2D(latitude: 37.78, longitude: -122.42),
            LocationCoordinate2D(latitude: 38.91, longitude: -77.03),
        ])

        let decoder = JSONDecoder()
        decoder.userInfo[.options] = routeOptions
        decoder.userInfo[.credentials] = Credentials(
            accessToken: "access_token",
            host: URL(string: "http://test_host.com")
        )

        var routeResponse: RouteResponse?
        XCTAssertNoThrow(routeResponse = try decoder.decode(RouteResponse.self, from: mutatedData))

        guard let steps = routeResponse?.routes?.first?.legs.first?.steps,
              steps.count > 6,
              let intersection = steps[6].intersections?.first
        else {
            XCTFail("Should have decoded the edited intersection.")
            return
        }
        XCTAssertEqual(intersection.laneValidIndications, [.left, .straightAhead, nil])
        XCTAssertEqual(intersection.usableLaneIndication, .straightAhead)
    }
}
