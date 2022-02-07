import CoreLocation
import Foundation
import MapboxMaps
import MapboxDirections
import MapboxCoreNavigation


private let trafficTileSetIdentifiers = Set([
    "mapbox.mapbox-traffic-v1",
    "mapbox.mapbox-traffic-v2-beta"
])

private let incidentsTileSetIdentifiers = Set([
    "mapbox.mapbox-incidents-v1",
    "mapbox.mapbox-incidents-v2-beta"
])

/**
 An extension on `MapView` that allows for toggling traffic on a map style that contains a [Mapbox Traffic source](https://docs.mapbox.com/vector-tiles/mapbox-traffic-v1/).
 */
extension MapView {
    
    /**
     Returns a set of tile set identifiers for specific `sourceIdentifier`.
     
     - parameter sourceIdentifier: Identifier of the source, which will be searched for in current style of the `MapView`.
     - returns: Set of tile set identifiers.
     */
    func tileSetIdentifiers(_ sourceIdentifier: String) -> Set<String> {
        if let properties = try? mapboxMap.style.sourceProperties(for: sourceIdentifier),
           let url = properties["url"] as? String,
           let configurationURL = URL(string: url),
           configurationURL.scheme == "mapbox",
           let tileSetIdentifiers = configurationURL.host?.components(separatedBy: ",") {
            return Set(tileSetIdentifiers)
        }
        
        return Set()
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
            return Array(tileSetIdentifiers(sourceIdentifier))
        }
        
        return []
    }
    
    /**
     Returns a set of source identifiers for tilesets that are or include the given source.
     
     - parameter tileSetIdentifier: Identifier of the tile set in the form `user.tileset`.
     - returns: Set of source identifiers.
     */
    func sourceIdentifiers(_ tileSetIdentifiers: Set<String>) -> Set<String> {
        return Set(mapboxMap.style.allSourceIdentifiers.filter {
            $0.type.rawValue == "vector"
        }.filter {
            !self.tileSetIdentifiers($0.id).isDisjoint(with: tileSetIdentifiers)
        }.map {
            $0.id
        })
    }
    
    /**
     Returns a Boolean value indicating whether data from the given tile set layers is currently all visible in the map view’s style.
     
     - parameter tileSetIdentifiers: Identifiers of the tile sets in the form `user.tileset`.
     - parameter layerIdentifier: Identifier of the layer in the tile set; in other words, a source layer identifier. Not to be confused with a style layer.
     */
    public func showsTileSet(with tileSetIdentifiers: Set<String>, layerIdentifier: String) -> Bool {
        let sourceIdentifiers = self.sourceIdentifiers(tileSetIdentifiers)
        var foundTileSets = false
        
        for mapViewLayerIdentifier in mapboxMap.style.allLayerIdentifiers.map({ $0.id }) {
            guard let sourceIdentifier = mapboxMap.style.layerProperty(for: mapViewLayerIdentifier,
                                                                       property: "source").value as? String,
                  let sourceLayerIdentifier = mapboxMap.style.layerProperty(for: mapViewLayerIdentifier,
                                                                            property: "source-layer").value as? String else { return false }
            
            if sourceIdentifiers.contains(sourceIdentifier) && sourceLayerIdentifier == layerIdentifier {
                foundTileSets = true
                let visibility = mapboxMap.style.layerProperty(for: mapViewLayerIdentifier, property: "visibility").value as? String
                if visibility != "visible" {
                    return false
                }
            }
        }
        
        return foundTileSets
    }
    
    /**
     Shows or hides data from the given tile set layers.
     
     - parameter isVisible: Parameter, which controls whether layer should be visible or not.
     - parameter tileSetIdentifiers: Identifiers of the tile sets in the form `user.tileset`.
     - parameter layerIdentifier: Identifier of the layer in the tile set; in other words, a source layer identifier. Not to be confused with a style layer.
     */
    public func setShowsTileSet(_ isVisible: Bool, with tileSetIdentifiers: Set<String>, layerIdentifier: String) {
        let sourceIdentifiers = self.sourceIdentifiers(tileSetIdentifiers)
        
        for mapViewLayerIdentifier in mapboxMap.style.allLayerIdentifiers.map({ $0.id }) {
            guard let sourceIdentifier = mapboxMap.style.layerProperty(for: mapViewLayerIdentifier,
                                                                       property: "source").value as? String,
                  let sourceLayerIdentifier = mapboxMap.style.layerProperty(for: mapViewLayerIdentifier,
                                                                            property: "source-layer").value as? String else { return }
            
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
            return showsTileSet(with: trafficTileSetIdentifiers, layerIdentifier: "traffic")
        }
        set {
            setShowsTileSet(newValue, with: trafficTileSetIdentifiers, layerIdentifier: "traffic")
        }
    }
    
    /**
     A Boolean value indicating whether incidents, such as road closures and detours, are visible in the map view’s style.
     */
    public var showsIncidents: Bool {
        get {
            return showsTileSet(with: incidentsTileSetIdentifiers, layerIdentifier: "closures")
        }
        set {
            setShowsTileSet(newValue, with: incidentsTileSetIdentifiers, layerIdentifier: "closures")
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
                let sourceLayer = mapboxMap.style.layerProperty(for: layer.id, property: "source-layer").value as? String
                
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
    
    /**
     Attempts to localize road labels into the local language and other labels into the given locale.
     */
    func localizeLabels(into locale: Locale) {
        guard !ResourceOptionsManager.hasChinaBaseURL,
              let mapboxStreetsSource = streetsSources().first else { return }
        
        let streetsSourceTilesetIdentifiers = tileSetIdentifiers(mapboxStreetsSource.id)
        let roadLabelSourceLayerIdentifier = streetsSourceTilesetIdentifiers.compactMap { VectorSource.roadLabelLayerIdentifiersByTileSetIdentifier[$0]
        }.first
        
        let style = mapboxMap.style
        let localizableLayerIdentifiers = style.allLayerIdentifiers.lazy
            .filter { $0.type == .symbol }
            // We only know how to localize layers backed by the Mapbox Streets source.
            .filter { style.layerProperty(for: $0.id, property: "source").value as? String == mapboxStreetsSource.id }
            // Road labels should match road signage, so they should not be localized.
            // TODO: Actively delocalize road labels into the “name” property: https://github.com/mapbox/mapbox-maps-ios/issues/653
            .filter { style.layerProperty(for: $0.id, property: "source-layer").value as? String != roadLabelSourceLayerIdentifier }
            .map { $0.id }
        try? style.localizeLabels(into: locale, forLayerIds: Array(localizableLayerIdentifiers))
    }
}
