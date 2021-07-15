import XCTest
import TestHelper
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
            "version": 1,
            "center": [
                37.763330, -122.385563
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
        
        let mapLoadingErrorExpectation = expectation(description: "Style loaded expectation")
        
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
}
