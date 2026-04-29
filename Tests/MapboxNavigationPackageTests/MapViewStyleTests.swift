import MapboxMaps
@testable import MapboxNavigationCore
import TestHelper
import XCTest

class MapViewStyleTests: TestCase {
    func testMapViewStyleSourcesAndLayersRemoval() {
        let mapView = MapView(frame: UIScreen.main.bounds)
        guard let mapboxMap = mapView.mapboxMap else {
            XCTFail("Should have non-nil mapboxMap")
            return
        }

        XCTAssertTrue(mapboxMap.allLayerIdentifiers.isEmpty, "There should be no layers in MapView")
        XCTAssertTrue(mapboxMap.allSourceIdentifiers.isEmpty, "There should be no sources in MapView")

        let sourceIdentifier = "source_identifier"
        var source = GeoJSONSource(id: sourceIdentifier)
        let coordinates = [
            CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0),
        ]
        source.data = .geometry(.lineString(.init(coordinates)))
        XCTAssertNoThrow(try mapboxMap.addSource(source))

        let layerIdentifier = "layer_identifier"
        let layer = LineLayer(id: layerIdentifier, source: sourceIdentifier)
        XCTAssertNoThrow(try mapboxMap.addLayer(layer, layerPosition: nil))

        XCTAssertEqual(mapboxMap.allLayerIdentifiers.count, 1)
        XCTAssertEqual(mapboxMap.allSourceIdentifiers.count, 1)

        XCTAssertNoThrow(try mapboxMap.removeLayer(withId: layerIdentifier))
        XCTAssertNoThrow(try mapboxMap.removeSource(withId: sourceIdentifier))

        XCTAssertTrue(mapboxMap.allLayerIdentifiers.isEmpty)
        XCTAssertTrue(mapboxMap.allSourceIdentifiers.isEmpty)
    }
}
