import Foundation

extension NavigationMapView {
    
    static let identifier = Bundle.mapboxNavigation.bundleIdentifier ?? ""
    
    struct LayerIdentifier {
        static let arrowLayer = "\(identifier)_arrowLayer"
        static let arrowStrokeLayer = "\(identifier)_arrowStrokeLayer"
        static let arrowSymbolLayer = "\(identifier)_arrowSymbolLayer"
        static let arrowSymbolCasingLayer = "\(identifier)_arrowSymbolCasingLayer"
        static let voiceInstructionLabelLayer = "\(identifier)_voiceInstructionLabelLayer"
        static let voiceInstructionCircleLayer = "\(identifier)_voiceInstructionCircleLayer"
        static let waypointCircleLayer = "\(identifier)_waypointCircleLayer"
        static let waypointSymbolLayer = "\(identifier)_waypointSymbolLayer"
        static let buildingExtrusionLayer = "\(identifier)_buildingExtrusionLayer"
        static let routeDurationAnnotationsLayer: String = "\(identifier)_routeDurationAnnotationsLayer"
    }
    
    struct SourceIdentifier {
        static let arrowSource = "\(identifier)_arrowSource"
        static let arrowStrokeSource = "\(identifier)_arrowStrokeSource"
        static let arrowSymbolSource = "\(identifier)_arrowSymbolSource"
        static let voiceInstructionSource = "\(identifier)_instructionSource"
        static let waypointSource = "\(identifier)_waypointSource"
        static let routeDurationAnnotationsSource: String = "\(identifier)_routeDurationAnnotationsSource"
    }
    
    struct ImageIdentifier {
        static let arrowImage = "triangle-tip-navigation"
    }
    
    struct AnnotationIdentifier {
        static let finalDestinationAnnotation = "\(identifier)_finalDestinationAnnotation"
    }
}
