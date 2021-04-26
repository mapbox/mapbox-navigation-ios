import CoreLocation
import Foundation
import MapboxMaps
import MapboxDirections
import MapboxCoreNavigation

/**
 An extension on `MapView` that allows for toggling traffic on a map style that contains a [Mapbox Traffic source](https://docs.mapbox.com/vector-tiles/mapbox-traffic-v1/).
 */
extension MapView {
    /**
     Returns a set of source identifiers for tilesets that are or include the Mapbox Incidents source.
     */
    func sourceIdentifiers(_ tileSetIdentifier: String) -> Set<String> {
        return Set(mapboxMap.__map.getStyleSources().compactMap {
            $0
        }.filter {
            $0.type == "vector"
        }.map {
            $0.id
        })
    }
    
    /**
     Method, which returns identifiers of the tile sets that make up specific source.
     
     This array contains multiple entries for a composited source. This property is empty for non-Mapbox-hosted tile sets and sources with type other than `vector`.
     */
    func tileSetIdentifiers(_ sourceIdentifier: String, sourceType: String) -> [String] {
//        do {
//            if sourceType == "vector",
//               let properties = try __map.getStyleSourceProperties(forSourceId: sourceIdentifier).value as? Dictionary<String, Any>,
//               let url = properties["url"] as? String,
//               let configurationURL = URL(string: url),
//               configurationURL.scheme == "mapbox",
//               let tileSetIdentifiers = configurationURL.host?.components(separatedBy: ",") {
//                return tileSetIdentifiers
//            }
//        } catch {
//            NSLog("Failed to get source properties with error: \(error.localizedDescription).")
        if sourceType == "vector",
           let properties = mapboxMap.__map.getStyleSourceProperties(forSourceId: sourceIdentifier).value as? Dictionary<String, Any>,
           let url = properties["url"] as? String,
           let configurationURL = URL(string: url),
           configurationURL.scheme == "mapbox",
           let tileSetIdentifiers = configurationURL.host?.components(separatedBy: ",") {
            return tileSetIdentifiers
        }
        
        return []
    }
    
    /**
     Returns a Boolean value indicating whether data from the given tile set layer is currently visible in the map view’s style.
     
     - parameter tileSetIdentifier: Identifier of the tile set in the form `user.tileset`.
     - parameter layerIdentifier: Identifier of the layer in the tile set; in other words, a source layer identifier. Not to be confused with a style layer.
     */
    func showsTileSet(withIdentifier tileSetIdentifier: String, layerIdentifier: String) -> Bool {
        let incidentsSourceIdentifiers = sourceIdentifiers(tileSetIdentifier)
        
        for layer in mapboxMap.__map.getStyleLayers() {
            guard let sourceIdentifier = mapboxMap.__map.getStyleLayerProperty(forLayerId: layer.id, property: "source").value as? String,
                  let sourceLayerIdentifier = mapboxMap.__map.getStyleLayerProperty(forLayerId: layer.id, property: "source-layer").value as? String else { return false }
            
            if incidentsSourceIdentifiers.contains(sourceIdentifier) && sourceLayerIdentifier == layerIdentifier {
                let visibility = mapboxMap.__map.getStyleLayerProperty(forLayerId: layer.id, property: "visibility").value as? String
                
                return visibility == "visible"
            }
        }
        
        return false
    }
    
    /**
     Shows or hides data from the given tile set layer.
     
     - parameter isVisible: Parameter, which controls whether layer should be visible or not.
     - parameter tileSetIdentifier: Identifier of the tile set in the form `user.tileset`.
     - parameter layerIdentifier: Identifier of the layer in the tile set; in other words, a source layer identifier. Not to be confused with a style layer.
     */
    func setShowsTileSet(_ isVisible: Bool, withIdentifier tileSetIdentifier: String, layerIdentifier: String) {
        let incidentsSourceIdentifiers = sourceIdentifiers(tileSetIdentifier)
        
        for layer in mapboxMap.__map.getStyleLayers() {
            guard let sourceIdentifier = mapboxMap.__map.getStyleLayerProperty(forLayerId: layer.id, property: "source").value as? String,
                  let sourceLayerIdentifier = mapboxMap.__map.getStyleLayerProperty(forLayerId: layer.id, property: "source-layer").value as? String else { return }
            
            if incidentsSourceIdentifiers.contains(sourceIdentifier) && sourceLayerIdentifier == layerIdentifier {
                mapboxMap.__map.setStyleLayerPropertiesForLayerId(layer.id, properties: [
                    "visibility": isVisible ? "visible" : "none"
                ])
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
    
    /**
     Returns a list of style source datasets (e.g. `mapbox.mapbox-streets-v8`), based on provided
     selected style source types.
     
     - parameter sourceTypes: List of `MapView` source types (e.g. `vector`).
     */
    func styleSourceDatasets(_ sourceTypes: [String]) -> [String] {
        let sources = mapboxMap.__map.getStyleSources().filter {
            return sourceTypes.contains($0.type)
        }
        
        var datasets = [String]()
        for source in sources {
            let properties = mapboxMap.__map.getStyleSourceProperties(forSourceId: source.id)
            
            // Ignore composite (https://docs.mapbox.com/studio-manual/reference/styles/#source-compositing)
            // and non-mapbox sources.
            if let contents = properties.value as? [String: AnyObject],
               let urlContent = contents["url"] as? String,
               let url = URL(string: urlContent),
               url.scheme == "mapbox",
               let dataset = url.host {
                datasets.append(dataset)
            }
        }
        
        return datasets
    }
    
    /**
     Method, which returns list of source identifiers, which contain streets tile set.
     */
    func streetsSources() -> [StyleObjectInfo] {
        return mapboxMap.__map.getStyleSources().compactMap {
            $0
        }.filter {
            let identifiers = tileSetIdentifiers($0.id, sourceType: $0.type)
            return VectorSource.isMapboxStreets(identifiers)
        }
    }
}
