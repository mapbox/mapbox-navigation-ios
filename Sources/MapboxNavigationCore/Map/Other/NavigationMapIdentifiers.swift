import Foundation

extension NavigationMapView {
    static let identifier = "com.mapbox.navigation.core"

    @MainActor
    enum LayerIdentifier {
        static let puck2DLayer: String = "puck"
        static let puck3DLayer: String = "puck-model-layer"
        static let poiLabelLayer: String = "poi-label"
        static let transitLabelLayer: String = "transit-label"
        static let airportLabelLayer: String = "airport-label"

        static var clickablePoiLabels: [String] {
            [
                LayerIdentifier.poiLabelLayer,
                LayerIdentifier.transitLabelLayer,
                LayerIdentifier.airportLabelLayer,
            ]
        }
    }

    enum ImageIdentifier {
        static let markerImage = "default_marker"
        static let midpointMarkerImage = "midpoint_marker"
        static let trafficSignal = "traffic_signal"
        static let railroadCrossing = "railroad_crossing"
        static let yieldSign = "yield_sign"
        static let stopSign = "stop_sign"
        static let searchAnnotationImage = "search_annotation"
        static let selectedSearchAnnotationImage = "search_annotation_selected"
    }

    enum ModelKeyIdentifier {
        static let modelSouce = "puck-model"
    }
}
