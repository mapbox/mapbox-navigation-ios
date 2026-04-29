import Foundation
@testable import MapboxDirections
import Turf
import XCTest

class RouteTests: XCTestCase {
    func testCoding() {
        // https://api.mapbox.com/directions/v5/mapbox/driving-traffic/-105.08198579860195%2C39.73843005470756;-104.954255,39.662569?overview=false&access_token=…
        let routeJSON: [String: Any?] = [
            "legs": [
                [
                    "summary": "West 6th Avenue Freeway, South University Boulevard",
                    "weight": 2346.3,
                    "duration": 1083.4,
                    "duration_typical": 1483.262,
                    "steps": [],
                    "distance": 17036.8,
                ],
            ],
            "weight_name": "routability",
            "weight": 1346.3,
            "duration": 1083.4,
            "duration_typical": 1483.262,
            "distance": 17036.8,
            "toll_costs": [
                [
                    "currency": "JPY",
                    "payment_methods": [
                        "etc": [
                            "standard": 1200,
                            "middle": 1400,
                        ],
                        "cash": [
                            "standard": 1250,
                        ],
                    ],
                ],
                [
                    "currency": "USD",
                    "payment_methods": [
                        "etc": [
                            "standard": 120,
                        ],
                        "cash": [
                            "standard": 125,
                        ],
                    ],
                ],
            ],
        ]
        let routeData = try! JSONSerialization.data(withJSONObject: routeJSON, options: [])

        let options = RouteOptions(coordinates: [
            LocationCoordinate2D(latitude: 39.73843005470756, longitude: -105.08198579860195),
            LocationCoordinate2D(latitude: 39.662569, longitude: -104.954255),
        ], profileIdentifier: .automobileAvoidingTraffic)
        options.routeShapeResolution = .none

        let decoder = JSONDecoder()
        var route: Route?
        XCTAssertThrowsError(route = try decoder.decode(Route.self, from: routeData))
        decoder.userInfo[.options] = options
        decoder.userInfo[.includesForeignMembers] = true
        XCTAssertNoThrow(route = try decoder.decode(Route.self, from: routeData))

        var expectedLeg = RouteLeg(
            steps: [],
            name: "West 6th Avenue Freeway, South University Boulevard",
            distance: 17036.8,
            expectedTravelTime: 1083.4,
            typicalTravelTime: 1483.262,
            profileIdentifier: .automobileAvoidingTraffic
        )
        expectedLeg.source = options.waypoints[0]
        expectedLeg.destination = options.waypoints[1]
        let expectedTollPrices = [
            TollPrice(
                currencyCode: "JPY",
                paymentMethod: .electronicTollCollection,
                category: .standard,
                amount: 1200
            ),
            TollPrice(
                currencyCode: "JPY",
                paymentMethod: .electronicTollCollection,
                category: .middle,
                amount: 1400
            ),
            TollPrice(
                currencyCode: "JPY",
                paymentMethod: .cash,
                category: .standard,
                amount: 1250
            ),
            TollPrice(
                currencyCode: "USD",
                paymentMethod: .electronicTollCollection,
                category: .standard,
                amount: 120
            ),
            TollPrice(
                currencyCode: "USD",
                paymentMethod: .cash,
                category: .standard,
                amount: 125
            ),
        ]
        var expectedRoute = Route(
            legs: [expectedLeg],
            shape: nil,
            distance: 17036.8,
            expectedTravelTime: 1083.4,
            typicalTravelTime: 1483.262
        )
        expectedRoute.tollPrices = expectedTollPrices
        XCTAssertEqual(route, expectedRoute)

        if let route {
            let encoder = JSONEncoder()
            encoder.userInfo[.options] = options
            encoder.userInfo[.includesForeignMembers] = true
            var encodedRouteData: Data?
            XCTAssertNoThrow(encodedRouteData = try encoder.encode(route))
            XCTAssertNotNil(encodedRouteData)

            if let encodedRouteData {
                var encodedRouteJSON: [String: Any?]?
                XCTAssertNoThrow(encodedRouteJSON = try JSONSerialization.jsonObject(
                    with: encodedRouteData,
                    options: []
                ) as? [String: Any?])
                XCTAssertNotNil(encodedRouteJSON)

                // Remove keys not found in the original API response.
                encodedRouteJSON?.removeValue(forKey: "source")
                encodedRouteJSON?.removeValue(forKey: "destination")
                encodedRouteJSON?.removeValue(forKey: "profileIdentifier")
                if var encodedLegJSON = encodedRouteJSON?["legs"] as? [[String: Any?]] {
                    encodedLegJSON[0].removeValue(forKey: "source")
                    encodedLegJSON[0].removeValue(forKey: "destination")
                    encodedLegJSON[0].removeValue(forKey: "profileIdentifier")
                    encodedRouteJSON?["legs"] = encodedLegJSON
                }

                XCTAssert(JSONSerialization.objectsAreEqual(routeJSON, encodedRouteJSON, approximate: true))
            }
        }
    }

    func testNullVoiceLocaleRoundtrip() {
        // Given

        // Request for the route
        // Key arguments:
        // - voice_instructions=true - makes the API to include "voiceLocale" in the response
        // - language=he - one of the unsupported languages by the API, which makes API to return `nil` for
        // "voiceLocale"
        // https://api.mapbox.com/directions/v5/mapbox/driving-traffic/-105.081986,39.73843;-104.954255,39.662569?overview=false&language=he&voice_instructions=true&access_token=...

        let routeJSON: [String: Any?] = [
            "legs": [
                [
                    "summary": "",
                    "weight": 1132.7,
                    "duration": 890.3,
                    "steps": [],
                    "distance": 17037.1,
                ],
            ],
            "weight_name": "routability",
            "weight": 1132.7,
            "duration": 890.3,
            "distance": 17037.1,
            "voiceLocale": nil,
        ]

        let options = RouteOptions(coordinates: [
            LocationCoordinate2D(latitude: 39.73843, longitude: -105.081986),
            LocationCoordinate2D(latitude: 39.662569, longitude: -104.954255),
        ])

        options.locale = Locale(identifier: "he")
        options.includesSpokenInstructions = true

        // When - JSON response is decoded into Route object (trip to)

        let decoder = JSONDecoder()
        decoder.userInfo[.options] = options

        guard
            let routeData = try? JSONSerialization.data(withJSONObject: routeJSON),
            let route = try? decoder.decode(Route.self, from: routeData)
        else {
            XCTFail("Response JSON can't be decoded as Route")
            return
        }

        // Then - speechLocale is decoded as nil

        XCTAssertNil(route.speechLocale)

        // When - The route is encoded to JSON (trip from)

        guard
            let jsonData = try? JSONEncoder().encode(route),
            let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any?]
        else {
            XCTFail("Route can't be encoded into JSON")
            return
        }

        // Then - voiceLocale key is present and its value is nil
        // swift-corelibs-foundation’s implementation of JSONSerialization uses NSNull to represent a JSON null value.
        XCTAssertTrue(json.contains { key, value in key == "voiceLocale" && (value == nil || value is NSNull) })
    }

    func testRouteTypicalTravelTime() {
        let typicalTravelTime = 2.5
        let route = Route(
            legs: [],
            shape: nil,
            distance: 2.0,
            expectedTravelTime: 3.0,
            typicalTravelTime: typicalTravelTime
        )
        XCTAssertEqual(route.typicalTravelTime, typicalTravelTime)
    }
}
