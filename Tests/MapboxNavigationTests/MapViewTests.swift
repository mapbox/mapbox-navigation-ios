import XCTest
import MapboxMaps
@testable import MapboxNavigation

class MapViewTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
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
        
        mapView.mapboxMap.onNext(.mapLoadingError, handler: { event in
            mapLoadingErrorExpectation.fulfill()
        })
        
        mapView.mapboxMap.loadStyleJSON(styleJSON)
        
        wait(for: [mapLoadingErrorExpectation], timeout: 1.0)
        
        let tileSetIdentifiers = mapView.tileSetIdentifiers("composite")
        
        let expectedTileSetIdentifiers = [
            "mapbox.mapbox-streets-v8",
            "mapbox.mapbox-terrain-v2"
        ]
        
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
        let mapboxSourceIdentifiers = mapView.sourceIdentifiers("mapbox.mapbox-terrain-v2")
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
        
        mapView.mapboxMap.onNext(.mapLoadingError, handler: { event in
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
}
