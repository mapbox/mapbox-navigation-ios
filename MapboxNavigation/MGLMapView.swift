import Foundation
import Mapbox
import MapboxDirections
import MapboxCoreNavigation

extension UIColor {
    /**
     Initializes a color object using the given opacity and HSL (HSV) color space component values.
     */
    convenience init(hue: CGFloat, saturation: CGFloat, value: CGFloat, alpha: CGFloat) {
        let brightness = (2 * value + saturation * (1 - abs(2 * value - 1))) / 2
        let hsbSaturation = 2 * (brightness - value) / brightness
        self.init(hue: hue, saturation: hsbSaturation, brightness: brightness, alpha: alpha)
    }
}

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
     Adds layers to the style that indicate incidents, such as road closures and detours.
     */
    func addIncidentsLayers() {
        guard let style = style else {
            return
        }
        
        let incidentsSources = sourceIdentifiers(forTileSetIdentifier: "mapbox.mapbox-incidents-v1")
        guard incidentsSources.isEmpty else {
            return
        }
        
        let incidentsSource = MGLVectorTileSource(identifier: "incidents", configurationURL: URL(string: "mapbox://mapbox.mapbox-incidents-v1")!)
        style.addSource(incidentsSource)
        
        let streetsSourceIdentifiers = sourceIdentifiers(forTileSetIdentifier: "mapbox.mapbox-streets-v7")
        var topmostRoadLayer: MGLLineStyleLayer?
        for layer in style.layers.reversed() {
            if let layer = layer as? MGLLineStyleLayer, let sourceIdentifier = layer.sourceIdentifier {
                if streetsSourceIdentifiers.contains(sourceIdentifier) && layer.sourceLayerIdentifier == "road" {
                    topmostRoadLayer = layer
                    break
                }
            }
        }
        
        let closureLineLayer = MGLLineStyleLayer(identifier: "incident-closure-lines", source: incidentsSource)
        closureLineLayer.sourceLayerIdentifier = "closures"
        closureLineLayer.minimumZoomLevel = 8
        closureLineLayer.predicate = NSPredicate(format: "$geometryType = 'LineString' AND type = 'full'")
        closureLineLayer.lineJoin = NSExpression(forConstantValue: "round")
        closureLineLayer.lineRoundLimit = NSExpression(forConstantValue: 1.5)
        closureLineLayer.lineColor = NSExpression(forConstantValue: UIColor(red: 0xf2/255.0, green: 0xf6/255.0, blue: 0xfa/255.0, alpha: 1))
        closureLineLayer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'exponential', 1.5, %@)", [5: 1, 18: 7])
        if let topmostRoadLayer = topmostRoadLayer {
            style.insertLayer(closureLineLayer, above: topmostRoadLayer)
        } else {
            style.addLayer(closureLineLayer)
        }
        
        let closureHighlightLineLayer = MGLLineStyleLayer(identifier: "incident-closure-line-highlights", source: incidentsSource)
        closureHighlightLineLayer.sourceLayerIdentifier = "closures"
        closureHighlightLineLayer.minimumZoomLevel = 8
        closureHighlightLineLayer.predicate = NSPredicate(format: "$geometryType = 'LineString' AND type = 'full'")
        closureHighlightLineLayer.lineJoin = NSExpression(forConstantValue: "round")
        closureHighlightLineLayer.lineRoundLimit = NSExpression(forConstantValue: 1.5)
        closureHighlightLineLayer.lineColor = NSExpression(forConstantValue: UIColor(hue: 210/360.0, saturation: 0.2, value: 0.24, alpha: 1))
        closureHighlightLineLayer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'exponential', 1.5, %@)", [5: 0.6, 18: 4.2])
        closureHighlightLineLayer.lineOffset = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'exponential', 1.5, %@)", [12: 1, 18: 10])
        closureHighlightLineLayer.lineDashPattern = NSExpression(format: "mgl_step:from:stops:($zoomLevel, {1, 0}, %@)", [14: NSExpression(format: "{1, 1}")])
        style.insertLayer(closureHighlightLineLayer, above: closureLineLayer)
        
        let incidentEndpointImage = Bundle.mapboxNavigation.image(named: "road-closure-red-icon")!
        style.setImage(incidentEndpointImage, forName: "road-closure-red-icon")
        
        let incidentEndLayer = MGLSymbolStyleLayer(identifier: "incident-endpoints", source: incidentsSource)
        incidentEndLayer.sourceLayerIdentifier = "closures"
        incidentEndLayer.minimumZoomLevel = 8
        incidentEndLayer.predicate = NSPredicate(format: "$geometryType IN {'LineString', 'Point'} AND type = 'endpoint:full'")
        incidentEndLayer.iconImageName = NSExpression(forConstantValue: "road-closure-red-icon")
        incidentEndLayer.iconScale = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'exponential', 1.5, %@)", [5: 0.15, 18: 0.6])
        incidentEndLayer.iconAllowsOverlap = NSExpression(forConstantValue: true)
        style.insertLayer(incidentEndLayer, above: closureHighlightLineLayer)
        
        let incidentStartLayer = MGLSymbolStyleLayer(identifier: "incident-startpoints", source: incidentsSource)
        incidentStartLayer.sourceLayerIdentifier = "closures"
        incidentStartLayer.minimumZoomLevel = 8
        incidentStartLayer.predicate = NSPredicate(format: "$geometryType IN {'LineString', 'Point'} AND type = 'startpoint:full'")
        incidentStartLayer.iconImageName = NSExpression(forConstantValue: "road-closure-red-icon")
        incidentStartLayer.iconScale = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'exponential', 1.5, %@)", [5: 0.15, 18: 0.6])
        incidentStartLayer.iconAllowsOverlap = NSExpression(forConstantValue: true)
        style.insertLayer(incidentStartLayer, above: incidentEndLayer)
    }
    
    /**
     A Boolean value indicating whether incidents, such as road closures and detours, are visible in the map view’s style.
     */
    public var showsIncidents: Bool {
        get {
            return showsTileSet(withIdentifier: "mapbox.mapbox-incidents-v1", layerIdentifier: "closures")
        }
        set {
            addIncidentsLayers()
            setShowsTileSet(newValue, withIdentifier: "mapbox.mapbox-incidents-v1", layerIdentifier: "closures")
        }
    }
}
