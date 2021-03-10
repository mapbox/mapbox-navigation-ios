import Foundation
import MapboxDirections
import MapboxNavigationNative

extension MapboxStreetsRoadClass {
    init(_ native: FunctionalRoadClass) {
        switch native {
        case .motorway:
            self = .motorway
        case .trunk:
            self = .trunk
        case .primary:
            self = .primary
        case .secondary:
            self = .secondary
        case .tertiary:
            self = .tertiary
        case .unclassified, .residential:
            // Mapbox Streets conflates unclassified and residential roads, because generally speaking they are distinguished only by their abutters; neither is “higher” than the other in priority.
            self = .street
        case .serviceOther:
            self = .service
        }
    }
}
