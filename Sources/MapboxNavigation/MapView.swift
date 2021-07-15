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
     Returns a list of tile set identifiers for specific `sourceIdentifier`.
     
     - parameter sourceIdentifier: Identifier of the source, which will be searched for in current style of the `MapView`.
     - returns: List of tile set identifiers.
     */
    func tileSetIdentifiers(_ sourceIdentifier: String) -> [String] {
        if let properties = try? mapboxMap.style.sourceProperties(for: sourceIdentifier),
           let url = properties["url"] as? String,
           let configurationURL = URL(string: url),
           configurationURL.scheme == "mapbox",
           let tileSetIdentifiers = configurationURL.host?.components(separatedBy: ",") {
            return tileSetIdentifiers
        }
        
        return []
    }
    
    /**
     Returns a list of identifiers of the tile sets that make up specific source type.
     
     This array contains multiple entries for a composited source. This property is empty for non-Mapbox-hosted tile sets and sources with type other than `vector`.
     
     - parameter sourceIdentifier: Identifier of the source.
     - parameter sourceType: Type of the source (e.g. `vector`).
     - returns: List of tile set identifiers.
     */
    func tileSetIdentifiers(_ sourceIdentifier: String, sourceType: String) -> [String] {
        if sourceType == "vector" {
            return tileSetIdentifiers(sourceIdentifier)
        }
        
        return []
    }
    
    /**
     Returns a set of source identifiers for tilesets that are or include the Mapbox Incidents source.
     
     - parameter tileSetIdentifier: Identifier of the tile set in the form `user.tileset`.
     - returns: Set of source identifiers.
     */
    func sourceIdentifiers(_ tileSetIdentifier: String) -> Set<String> {
        return Set(mapboxMap.style.allSourceIdentifiers.filter {
            $0.type.rawValue == "vector"
        }.filter {
            tileSetIdentifiers($0.id).contains(tileSetIdentifier)
        }.map {
            $0.id
        })
    }
    
    /**
     Returns a Boolean value indicating whether data from the given tile set layer is currently visible in the map view’s style.
     
     - parameter tileSetIdentifier: Identifier of the tile set in the form `user.tileset`.
     - parameter layerIdentifier: Identifier of the layer in the tile set; in other words, a source layer identifier. Not to be confused with a style layer.
     */
    func showsTileSet(withIdentifier tileSetIdentifier: String, layerIdentifier: String) -> Bool {
        let sourceIdentifiers = self.sourceIdentifiers(tileSetIdentifier)
        
        for mapViewLayerIdentifier in mapboxMap.style.allLayerIdentifiers.map({ $0.id }) {
            guard let sourceIdentifier = mapboxMap.style.layerProperty(for: mapViewLayerIdentifier,
                                                                       property: "source") as? String,
                  let sourceLayerIdentifier = mapboxMap.style.layerProperty(for: mapViewLayerIdentifier,
                                                                            property: "source-layer") as? String else { return false }
            
            if sourceIdentifiers.contains(sourceIdentifier) && sourceLayerIdentifier == layerIdentifier {
                let visibility = mapboxMap.style.layerProperty(for: mapViewLayerIdentifier, property: "visibility") as? String
                
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
        let sourceIdentifiers = self.sourceIdentifiers(tileSetIdentifier)
        
        for mapViewLayerIdentifier in mapboxMap.style.allLayerIdentifiers.map({ $0.id }) {
            guard let sourceIdentifier = mapboxMap.style.layerProperty(for: mapViewLayerIdentifier,
                                                                       property: "source") as? String,
                  let sourceLayerIdentifier = mapboxMap.style.layerProperty(for: mapViewLayerIdentifier,
                                                                            property: "source-layer") as? String else { return }
            
            if sourceIdentifiers.contains(sourceIdentifier) && sourceLayerIdentifier == layerIdentifier {
                let properties = [
                    "visibility": isVisible ? "visible" : "none"
                ]
                try? mapboxMap.style.setLayerProperties(for: mapViewLayerIdentifier, properties: properties)
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
        let sources = mapboxMap.style.allSourceIdentifiers.filter {
            return sourceTypes.contains($0.type.rawValue)
        }
        
        var datasets = [String]()
        for source in sources {
            // Ignore composite (https://docs.mapbox.com/studio-manual/reference/styles/#source-compositing)
            // and non-mapbox sources.
            if let properties = try? mapboxMap.style.sourceProperties(for: source.id),
               let urlContent = properties["url"] as? String,
               let url = URL(string: urlContent),
               url.scheme == "mapbox",
               let dataset = url.host {
                datasets.append(dataset)
            }
        }
        
        return datasets
    }

    var mainRouteLineParentLayerIdentifier: String? {
        var parentLayer: String? = nil
        let identifiers = [
            NavigationMapView.LayerIdentifier.arrowLayer,
            NavigationMapView.LayerIdentifier.arrowSymbolLayer,
            NavigationMapView.LayerIdentifier.arrowSymbolCasingLayer,
            NavigationMapView.LayerIdentifier.arrowStrokeLayer,
            NavigationMapView.LayerIdentifier.waypointCircleLayer,
            NavigationMapView.LayerIdentifier.buildingExtrusionLayer
        ]
        
        for layer in mapboxMap.style.allLayerIdentifiers.reversed() {
            if !(layer.type.rawValue == "symbol") && !identifiers.contains(layer.id) {
                let sourceLayer = mapboxMap.style.layerProperty(for: layer.id, property: "source-layer") as? String
                
                if let sourceLayer = sourceLayer,
                   sourceLayer.isEmpty {
                    continue
                }
                
                parentLayer = layer.id
                break
            }
        }
        
        return parentLayer
    }
    
    /**
     Method, which returns list of source identifiers, which contain streets tile set.
     */
    func streetsSources() -> [SourceInfo] {
        return mapboxMap.style.allSourceIdentifiers.filter {
            let identifiers = tileSetIdentifiers($0.id, sourceType: $0.type.rawValue)
            return VectorSource.isMapboxStreets(identifiers)
        }
    }
}
