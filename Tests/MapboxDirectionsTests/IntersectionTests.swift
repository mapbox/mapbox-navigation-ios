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
                headings: [80.0],
                approachIndex: -1,
                outletIndex: 0,
                outletIndexes: IndexSet([0]),
                approachLanes: nil,
                usableApproachLanes: nil,
                preferredApproachLanes: nil,
                usableLaneIndication: nil,
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
                usableLaneIndication: nil,
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
                usableLaneIndication: .straightAhead,
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
}
