import XCTest
@testable import MapboxNavigation

class MGLVectorTileSourceTests: XCTestCase {
    func testMapboxStreets() {
        let v8 = MGLVectorTileSource(identifier: "com.mapbox.MapboxStreets", configurationURL: URL(string: "mapbox://mapbox.mapbox-streets-v8,mapbox.mapbox-terrain-v1")!)
        XCTAssertTrue(v8.isMapboxStreets)
        XCTAssertEqual(v8.tileSetIdentifiers, ["mapbox.mapbox-streets-v8", "mapbox.mapbox-terrain-v1"])
        XCTAssertEqual(v8.roadLabelLayerIdentifier, "road")
        
        let v7 = MGLVectorTileSource(identifier: "com.mapbox.MapboxStreets", configurationURL: URL(string: "mapbox://mapbox.mapbox-terrain-v1,mapbox.mapbox-streets-v7")!)
        XCTAssertTrue(v7.isMapboxStreets)
        XCTAssertEqual(v7.tileSetIdentifiers, ["mapbox.mapbox-terrain-v1", "mapbox.mapbox-streets-v7"])
        XCTAssertEqual(v7.roadLabelLayerIdentifier, "road_label")
        
        let v6 = MGLVectorTileSource(identifier: "com.mapbox.MapboxStreets", configurationURL: URL(string: "mapbox://mapbox.mapbox-streets-v6")!)
        XCTAssertFalse(v6.isMapboxStreets)
        XCTAssertEqual(v6.tileSetIdentifiers, ["mapbox.mapbox-streets-v6"])
        XCTAssertNil(v6.roadLabelLayerIdentifier)
    }
}
