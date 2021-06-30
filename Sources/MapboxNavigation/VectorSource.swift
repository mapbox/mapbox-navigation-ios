
import Foundation
import MapboxMaps


extension VectorSource {
    /**
     Method, which returns a boolean value indicating whether the tile source is a supported version of the Mapbox Streets source.
     */
    static func isMapboxStreets(_ identifiers: [String]) -> Bool {
        return identifiers.contains("mapbox.mapbox-streets-v8") || identifiers.contains("mapbox.mapbox-streets-v7")
    }
}
