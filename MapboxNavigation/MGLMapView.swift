import Foundation
import Mapbox
import MapboxDirections
import MapboxCoreNavigation

/**
 An extension on `MGLMapView` that allows for toggling traffic on a map style that contains a [Mapbox Traffic source](https://www.mapbox.com/vector-tiles/mapbox-traffic-v1/).
 */
extension MGLMapView {
    /**
     Returns a set of source identifiers for tilesets that are or include the Mapbox Incidents source.
     */
    func sourceIdentifiers(forTileSetIdentifier tileSetIdentifier: String) -> Set<String> {
        guard let style = style else {
            return []
        }
        return Set(style.sources.compactMap {
            $0 as? MGLVectorTileSource
        }.filter {
            $0.configurationURL?.host?.components(separatedBy: ",").contains(tileSetIdentifier) ?? false
        }.map {
            $0.identifier
        })
    }
    
    /**
     Returns a Boolean value indicating whether data from the given tile set layer is currently visible in the map view’s style.
     
     - parameter tileSetIdentifier: Identifier of the tile set in the form `user.tileset`.
     - parameter layerIdentifier: Identifier of the layer in the tile set; in other words, a source layer identifier. Not to be confused with a style layer.
     */
    func showsTileSet(withIdentifier tileSetIdentifier: String, layerIdentifier: String) -> Bool {
        guard let style = style else {
            return false
        }
        
        let incidentsSourceIdentifiers = sourceIdentifiers(forTileSetIdentifier: tileSetIdentifier)
        for layer in style.layers {
            if let layer = layer as? MGLVectorStyleLayer, let sourceIdentifier = layer.sourceIdentifier {
                if incidentsSourceIdentifiers.contains(sourceIdentifier) && layer.sourceLayerIdentifier == layerIdentifier {
                    return layer.isVisible
                }
            }
        }
        return false
    }
    
    /**
     Shows or hides data from the given tile set layer.
     
     - parameter tileSetIdentifier: Identifier of the tile set in the form `user.tileset`.
     - parameter layerIdentifier: Identifier of the layer in the tile set; in other words, a source layer identifier. Not to be confused with a style layer.
     */
    func setShowsTileSet(_ isVisible: Bool, withIdentifier tileSetIdentifier: String, layerIdentifier: String) {
        guard let style = style else {
            return
        }
        
        let incidentsSourceIdentifiers = sourceIdentifiers(forTileSetIdentifier: tileSetIdentifier)
        for layer in style.layers {
            if let layer = layer as? MGLVectorStyleLayer, let sourceIdentifier = layer.sourceIdentifier {
                if incidentsSourceIdentifiers.contains(sourceIdentifier) && layer.sourceLayerIdentifier == layerIdentifier {
                    layer.isVisible = isVisible
                }
            }
        }
    }

    /**
     A Boolean value indicating whether traffic congestion lines are visible in the map view’s style.
     */
    public var showsTraffic: Bool {
        get {
            return showsTileSet(withIdentifier: "mapbox.mapbox-traffic-v1", layerIdentifier: "traffic")
        }
        set {
            setShowsTileSet(newValue, withIdentifier: "mapbox.mapbox-traffic-v1", layerIdentifier: "traffic")
        }
    }
    
    /**
     A Boolean value indicating whether incidents, such as road closures and detours, are visible in the map view’s style.
     */
    public var showsIncidents: Bool {
        get {
            return showsTileSet(withIdentifier: "mapbox.mapbox-incidents-v1", layerIdentifier: "closures")
        }
        set {
            setShowsTileSet(newValue, withIdentifier: "mapbox.mapbox-incidents-v1", layerIdentifier: "closures")
        }
    }
}
