import XCTest
import MapboxMaps
@testable import MapboxNavigation
import TestHelper

class MapViewStyleTests: TestCase {
    func testMapViewStyleSourcesAndLayersRemoval() {
        let resourceOptions = ResourceOptions(accessToken: "")
        let mapInitOptions = MapInitOptions(resourceOptions: resourceOptions)
        let mapView = MapView(frame: UIScreen.main.bounds, mapInitOptions: mapInitOptions)
        let style = mapView.mapboxMap.style
        
        XCTAssertEqual(style.allLayerIdentifiers.count,
                       0,
                       "There should be no layers in MapView's style.")
        
        XCTAssertEqual(style.allSourceIdentifiers.count,
                       0,
                       "There should be no sources in MapView's style.")
        
        var source = GeoJSONSource()
        let coordinates = [
            CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        ]
        source.data = .geometry(.lineString(.init(coordinates)))
        let sourceIdentifier = "source_identifier"
        XCTAssertNoThrow(try style.addSource(source, id: sourceIdentifier))
        
        let layerIdentifier = "layer_identifier"
        var layer = LineLayer(id: layerIdentifier)
        layer.source = sourceIdentifier
        XCTAssertNoThrow(try style.addLayer(layer, layerPosition: nil))
        
        XCTAssertEqual(style.allLayerIdentifiers.count,
                       1,
                       "There should be one layer in MapView's style.")
        
        XCTAssertEqual(style.allSourceIdentifiers.count,
                       1,
                       "There should be one source in MapView's style.")
        
        let layerIdentifiers: Set<String> = [
            layerIdentifier
        ]
        style.removeLayers(layerIdentifiers)
        
        let sourceIdentifiers: Set<String> = [
            sourceIdentifier
        ]
        style.removeSources(sourceIdentifiers)
        
        XCTAssertEqual(style.allLayerIdentifiers.count,
                       0,
                       "There should be no layers in MapView's style.")
        
        XCTAssertEqual(style.allSourceIdentifiers.count,
                       0,
                       "There should be no sources in MapView's style.")
    }
}
