import Foundation
import Mapbox
import MapboxDirections
import MapboxCoreNavigation

/**
 An extension on `MGLMapView` that allows for toggling traffic on a map style that contains a [Mapbox Traffic source](https://www.mapbox.com/vector-tiles/mapbox-traffic-v1/).
 */
extension MGLMapView {

    /**
     Toggle traffic on a map style that contains a Mapbox Traffic source.
     */
    public var showsTraffic: Bool {
        get {
            if let style = style {
                for layer in style.layers {
                    if let l = layer as? MGLForegroundStyleLayer {
                        if l.sourceIdentifier == "mapbox://mapbox.mapbox-traffic-v1" {
                            return l.isVisible
                        }
                    }
                }
            }
            return false
        }
        set {
            if let style = style {
                for layer in style.layers {
                    if let layer = layer as? MGLForegroundStyleLayer {
                        if layer.sourceIdentifier == "mapbox://mapbox.mapbox-traffic-v1" {
                            layer.isVisible = newValue
                        }
                    }
                }
            }
        }
    }
}
