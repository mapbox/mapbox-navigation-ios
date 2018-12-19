import Foundation
import Mapbox

extension MGLVectorTileSource {
    /**
     The identifiers of the tile sets that make up this source.
     
     This array contains multiple entries for a composited source. This property is set to `nil` for non-Mapbox-hosted tile sets.
     */
    var tileSetIdentifiers: [String]? {
        guard let configurationURL = configurationURL, configurationURL.scheme == "mapbox" else {
            return nil
        }
        return configurationURL.host!.components(separatedBy: ",")
    }
    
    /**
     A Boolean value indicating whether the tile source is a supported version of the Mapbox Streets source.
     */
    var isMapboxStreets: Bool {
        let tileSetIdentifiers = self.tileSetIdentifiers
        return tileSetIdentifiers?.contains("mapbox.mapbox-streets-v8") ?? false ||
            tileSetIdentifiers?.contains("mapbox.mapbox-streets-v7") ?? false
    }
    
    /**
     A dictionary associating known tile set identifiers with identifiers of source layers that contain road names.
     */
    static var roadLabelLayerIdentifiersByTileSetIdentifier = [
        "mapbox.mapbox-streets-v8": "road",
        "mapbox.mapbox-streets-v7": "road_label",
    ]
    
    /**
     The identifier of a layer in this source that contains road names.
     */
    var roadLabelLayerIdentifier: String? {
        return tileSetIdentifiers?.compactMap { MGLVectorTileSource.roadLabelLayerIdentifiersByTileSetIdentifier[$0] }.first
    }
}
