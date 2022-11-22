import XCTest
import MapboxMaps
@testable import MapboxNavigation
import TestHelper

class MapViewTests: TestCase {
    func testMapViewTileSetAndSourceIdentifiers() {
        let resourceOptions = ResourceOptions(accessToken: "")
        let mapInitOptions = MapInitOptions(resourceOptions: resourceOptions)
        let mapView = MapView(frame: UIScreen.main.bounds, mapInitOptions: mapInitOptions)
        
        let styleJSONObject: [String: Any] = [
            "version": 8,
            "center": [
                -122.385563, 37.763330
            ],
            "zoom": 15,
            "sources": [
                "composite": [
                    "url": "mapbox://mapbox.mapbox-streets-v8,mapbox.mapbox-terrain-v2",
                    "type": "vector"
                ],
                "custom": [
                    "url": "http://api.example.com/tilejson.json",
                    "type": "raster"
                ]
            ],
            "layers": []
        ]
        
        let styleJSON: String = ValueConverter.toJson(forValue: styleJSONObject)
        XCTAssertFalse(styleJSON.isEmpty, "ValueConverter should create valid JSON string.")
        
        let mapLoadingErrorExpectation = expectation(description: "Map loading error expectation")
        mapLoadingErrorExpectation.assertForOverFulfill = false
        
        mapView.mapboxMap.onNext(event: .mapLoadingError, handler: { event in
            mapLoadingErrorExpectation.fulfill()
        })
        
        mapView.mapboxMap.loadStyleJSON(styleJSON)
        
        wait(for: [mapLoadingErrorExpectation], timeout: 1.0)
        
        let tileSetIdentifiers = mapView.tileSetIdentifiers("composite")
        
        let expectedTileSetIdentifiers = Set([
            "mapbox.mapbox-streets-v8",
            "mapbox.mapbox-terrain-v2"
        ])
        
        XCTAssertEqual(tileSetIdentifiers.count,
                       expectedTileSetIdentifiers.count,
                       "There should be two tile set identifier.")
        XCTAssertEqual(tileSetIdentifiers,
                       expectedTileSetIdentifiers,
                       "Tile set identifiers are not equal.")
        
        let filteredTileSetIdentifiers = mapView.tileSetIdentifiers("custom", sourceType: "raster")
        XCTAssertEqual(filteredTileSetIdentifiers.count,
                       0,
                       "Tile set identifiers array should be empty.")
        
        // Verify whether `MapView.sourceIdentifiers(_:)` returns only source identifiers for
        // Mapbox tile set identifiers.
        let mapboxSourceIdentifiers = mapView.sourceIdentifiers(Set(["mapbox.mapbox-terrain-v2"]))
        XCTAssertEqual(mapboxSourceIdentifiers.count,
                       1,
                       "There should be only one source identifier.")
        XCTAssertEqual(mapboxSourceIdentifiers.first,
                       "composite",
                       "Source identifiers are not equal.")
    }
    
    func testMapViewShowsTrafficAndIncidents() {
        let resourceOptions = ResourceOptions(accessToken: "")
        let mapInitOptions = MapInitOptions(resourceOptions: resourceOptions)
        let mapView = MapView(frame: UIScreen.main.bounds, mapInitOptions: mapInitOptions)
        
        let styleJSONObject: [String: Any] = [
            "version": 8,
            "center": [
                -122.385563, 37.763330
            ],
            "zoom": 15,
            "sources": [
                "mapbox-traffic": [
                    "url": "mapbox://mapbox.mapbox-traffic-v1",
                    "type": "vector"
                ]
            ],
            "layers": [
                [
                    "id": "traffic",
                    "type": "line",
                    "source": "mapbox-traffic",
                    "source-layer": "traffic"
                ]
            ]
        ]
        
        let styleJSON: String = ValueConverter.toJson(forValue: styleJSONObject)
        XCTAssertFalse(styleJSON.isEmpty, "ValueConverter should create valid JSON string.")
        
        let mapLoadingErrorExpectation = expectation(description: "Map loading error expectation")
        mapLoadingErrorExpectation.assertForOverFulfill = false
        
        mapView.mapboxMap.onNext(event: .mapLoadingError, handler: { event in
            mapLoadingErrorExpectation.fulfill()
        })
        
        mapView.mapboxMap.loadStyleJSON(styleJSON)
        
        wait(for: [mapLoadingErrorExpectation], timeout: 10.0)
        
        XCTAssertEqual(mapView.mapboxMap.style.allSourceIdentifiers.count,
                       1,
                       "There should be one source.")
        
        XCTAssertEqual(mapView.mapboxMap.style.allLayerIdentifiers.count,
                       1,
                       "There should be one layer.")
        
        // It is expected that `showsTraffic` will be set to `false` after changing its visibility.
        XCTAssertTrue(mapView.showsTraffic, "Traffic should be shown by default.")
        mapView.showsTraffic = false
        XCTAssertFalse(mapView.showsTraffic, "Traffic should not be shown after change.")
        
        // Since there is no incidents layer `showsIncidents` modification will have no effect.
        XCTAssertFalse(mapView.showsIncidents, "Incidents should not be shown by default.")
        mapView.showsIncidents = false
        XCTAssertFalse(mapView.showsIncidents, "Incidents should not be shown after change.")
    }
    
    func testLocalizingLabels() {
        let resourceOptions = ResourceOptions(accessToken: "")
        let mapInitOptions = MapInitOptions(resourceOptions: resourceOptions)
        let mapView = MapView(frame: UIScreen.main.bounds, mapInitOptions: mapInitOptions)
        
        let styleJSONObject: [String: Any] = [
            "version": 8,
            "center": [
                -122.385563, 37.763330
            ],
            "zoom": 15,
            "sources": [
                "composite": [
                    "url": "mapbox://mapbox.mapbox-streets-v8,mapbox.mapbox-terrain-v2",
                    "type": "vector",
                ]
            ],
            "layers": [
                [
                    "id": "road-labels",
                    "type": "symbol",
                    "source": "composite",
                    "source-layer": "road",
                    "layout": [
                        "text-field": ["coalesce", ["get", "name_en"], ["get", "name"]],
                    ],
                ],
                [
                    "id": "place-labels",
                    "type": "symbol",
                    "source": "composite",
                    "source-layer": "place",
                    "layout": [
                        "text-field": ["coalesce", ["get", "name_en"], ["get", "name"]],
                    ],
                ],
            ],
        ]
        
        let styleJSON: String = ValueConverter.toJson(forValue: styleJSONObject)
        XCTAssertFalse(styleJSON.isEmpty, "ValueConverter should create valid JSON string.")
        
        let mapLoadingErrorExpectation = expectation(description: "Map loading error expectation")
        mapLoadingErrorExpectation.assertForOverFulfill = false
        
        mapView.mapboxMap.onNext(event: .mapLoadingError, handler: { event in
            mapLoadingErrorExpectation.fulfill()
        })
        
        mapView.mapboxMap.loadStyleJSON(styleJSON)
        
        wait(for: [mapLoadingErrorExpectation], timeout: 10.0)
        
        let style = mapView.mapboxMap.style
        XCTAssertEqual(style.allSourceIdentifiers.count, 1)
        XCTAssertEqual(style.allLayerIdentifiers.count, 2)
        
        func textFieldExpression(layerIdentifier: String) -> Exp? {
            let expressionArray = style.layerProperty(for: layerIdentifier, property: "text-field").value
            
            var expressionData: Data? = nil
            XCTAssertNoThrow(expressionData = try JSONSerialization.data(withJSONObject: expressionArray, options: []))
            guard expressionData != nil else { return nil }
            
            var expression: Exp? = nil
            XCTAssertNoThrow(expression = try JSONDecoder().decode(Exp.self, from: expressionData!))
            return expression
        }
        
        XCTAssertEqual(textFieldExpression(layerIdentifier: "road-labels"),
                       Exp(.format) {
                        Exp(.coalesce) { Exp(.get) { "name_en" }; Exp(.get) { "name" } }
                        FormatOptions()
                       },
                       "Road labels should be in English by default.")
        XCTAssertEqual(textFieldExpression(layerIdentifier: "place-labels"),
                       Exp(.format) {
                        Exp(.coalesce) { Exp(.get) { "name_en" }; Exp(.get) { "name" } }
                        FormatOptions()
                       },
                       "Place labels should be in English by default.")
        
        func assert(roadLabelProperty: String, placeLabelProperty: String) {
            // TODO: Unlocalize road labels: https://github.com/mapbox/mapbox-maps-ios/issues/653
            XCTAssertEqual(textFieldExpression(layerIdentifier: "road-labels"),
                           Exp(.format) {
                            Exp(.coalesce) { Exp(.get) { roadLabelProperty }; Exp(.get) { "name" } }
                            FormatOptions()
                           },
                           "Road labels should remain in English after localization.")
            
            XCTAssertEqual(textFieldExpression(layerIdentifier: "place-labels"),
                           Exp(.format) {
                            Exp(.coalesce) { Exp(.get) { placeLabelProperty }; Exp(.get) { "name" } }
                            FormatOptions()
                           },
                           "Place labels should be localized after localization.")
        }
        
        mapView.localizeLabels(into: Locale(identifier: "en"))
        assert(roadLabelProperty: "name_en", placeLabelProperty: "name_en")
        
        mapView.localizeLabels(into: Locale(identifier: "es"))
        assert(roadLabelProperty: "name_en", placeLabelProperty: "name_es")
        
        mapView.localizeLabels(into: Locale(identifier: "zh-Hant-TW"))
        assert(roadLabelProperty: "name_en", placeLabelProperty: "name_zh-Hant")
        
        // Simplified Chinese is broken: https://github.com/mapbox/mapbox-maps-ios/issues/652
        mapView.localizeLabels(into: Locale(identifier: "zh-Hans-CN"))
        assert(roadLabelProperty: "name_en", placeLabelProperty: "name_zh-Hans")
        
        XCTAssertNoThrow(mapView.localizeLabels(into: Locale(identifier: "tlh")))
    }
    
    func testPreferredMapboxStreetsLocale() {
        // https://github.com/mapbox/mapbox-maps-ios/issues/653
        XCTAssertNil(VectorSource.preferredMapboxStreetsLocale(for: Locale(identifier: "mul")),
                     "Local language not yet implemented.")
        
        XCTAssertEqual(VectorSource.preferredMapboxStreetsLocale(for: Locale(identifier: "es")),
                       Locale(identifier: "es"),
                       "Exact match should be supported.")
        
        XCTAssertEqual(VectorSource.preferredMapboxStreetsLocale(for: Locale(identifier: "en-US")),
                       Locale(identifier: "en"),
                       "Extraneous region codes should be removed.")
        XCTAssertEqual(VectorSource.preferredMapboxStreetsLocale(for: Locale(identifier: "en-Latn")),
                       Locale(identifier: "en"),
                       "Extraneous script codes should be removed.")
        
        XCTAssertEqual(VectorSource.preferredMapboxStreetsLocale(for: Locale(identifier: "zh-Hans-CN")),
                       Locale(identifier: "zh-Hans"),
                       "Extraneous region codes should be removed.")
        XCTAssertEqual(VectorSource.preferredMapboxStreetsLocale(for: Locale(identifier: "zh-Hant-HK")),
                       Locale(identifier: "zh-Hant"),
                       "Extraneous region codes should be removed.")
        
        XCTAssertNil(VectorSource.preferredMapboxStreetsLocale(for: Locale(identifier: "frm")),
                     "Middle French not supported despite sharing prefix with French.")
        XCTAssertNil(VectorSource.preferredMapboxStreetsLocale(for: Locale(identifier: "tlh")),
                     "Klingon not yet implemented. 🖖")
    }

    func testCreateTilesetDescriptor() {
        let resourceOptions = ResourceOptions(accessToken: "")
        let mapInitOptions = MapInitOptions(resourceOptions: resourceOptions)
        let mapView = MapView(frame: UIScreen.main.bounds, mapInitOptions: mapInitOptions)

        let tilesetDescriptor = mapView.tilesetDescriptor(zoomRange: 3...10)
        XCTAssertNotNil(tilesetDescriptor)

        mapView.mapboxMap.style.uri = StyleURI(rawValue: "https://url")
        XCTAssertNil(mapView.tilesetDescriptor(zoomRange: 3...10), "Should ignore non mapbox sources")
    }
}
