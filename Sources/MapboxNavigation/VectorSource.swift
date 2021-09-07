import Foundation
import MapboxMaps


extension VectorSource {
    /// A dictionary associating known tile set identifiers with identifiers of source layers that contain road names.
    static let roadLabelLayerIdentifiersByTileSetIdentifier = [
        "mapbox.mapbox-streets-v8": "road",
        "mapbox.mapbox-streets-v7": "road_label",
    ]
    
    /**
     Method, which returns a boolean value indicating whether the tile source is a supported version of the Mapbox Streets source.
     */
    static func isMapboxStreets(_ identifiers: [String]) -> Bool {
        return identifiers.contains("mapbox.mapbox-streets-v8") || identifiers.contains("mapbox.mapbox-streets-v7")
    }
}
