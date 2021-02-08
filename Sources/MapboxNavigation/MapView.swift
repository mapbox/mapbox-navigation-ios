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
        do {
            return Set(try __map.getStyleSources().compactMap {
                $0
            }.filter {
                $0.type == "vector"
            }.map {
                $0.id
            })
        } catch {
            NSLog("Failed to retrieve source identifiers. Error: \(error.localizedDescription).")
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
        
        do {
            for layer in try __map.getStyleLayers() {
                guard let sourceIdentifier = try __map.getStyleLayerProperty(forLayerId: layer.id, property: "source").value as? String,
                      let sourceLayerIdentifier = try __map.getStyleLayerProperty(forLayerId: layer.id, property: "source-layer").value as? String else { return false }
                
                if incidentsSourceIdentifiers.contains(sourceIdentifier) && sourceLayerIdentifier == layerIdentifier {
                    let visibility = try __map.getStyleLayerProperty(forLayerId: layer.id, property: "visibility").value as? String
                    
                    return visibility == "visible"
                }
            }
        } catch {
            NSLog("Error occured while retrieving layers. Error: \(error.localizedDescription).")
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
        
        do {
            for layer in try __map.getStyleLayers() {
                guard let sourceIdentifier = try __map.getStyleLayerProperty(forLayerId: layer.id, property: "source").value as? String,
                      let sourceLayerIdentifier = try __map.getStyleLayerProperty(forLayerId: layer.id, property: "source-layer").value as? String else { return }
                
                if incidentsSourceIdentifiers.contains(sourceIdentifier) && sourceLayerIdentifier == layerIdentifier {
                    try __map.setStyleLayerPropertiesForLayerId(layer.id, properties: [
                        "visibility": isVisible ? "visible" : "none"
                    ])
                }
            }
        } catch {
            NSLog("Error occured while retrieving layers. Error: \(error.localizedDescription).")
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
    
    // TODO: Consider replacing after Maps SDK provides the ability to convert zoom to altitude and vice versa.
    var altitude: CLLocationDistance? {
        guard let latitude = locationManager.latestLocation?.coordinate.latitude else { return nil }
        return AltitudeForZoomLevel(Double(cameraView.zoom), cameraView.pitch, latitude, bounds.size)
    }
}
