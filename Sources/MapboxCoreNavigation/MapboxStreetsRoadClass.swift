import Foundation
import MapboxDirections
import MapboxNavigationNative

extension MapboxStreetsRoadClass {
    /// Returns a Boolean value indicating whether the road class is for a highway entrance or exit ramp (slip road).
    public var isRamp: Bool {
        return self == .motorwayLink || self == .trunkLink || self == .primaryLink || self == .secondaryLink
    }
    
    init(_ native: FunctionalRoadClass, isRamp: Bool) {
        switch native {
        case .motorway:
            self = isRamp ? .motorwayLink : .motorway
        case .trunk:
            self = isRamp ? .trunkLink : .trunk
        case .primary:
            self = isRamp ? .primaryLink : .primary
        case .secondary:
            self = isRamp ? .secondaryLink : .secondary
        case .tertiary:
            self = isRamp ? .tertiaryLink : .tertiary
        case .unclassified, .residential:
            // Mapbox Streets conflates unclassified and residential roads, because generally speaking they are distinguished only by their abutters; neither is “higher” than the other in priority.
            self = .street
        case .serviceOther:
            self = .service
        @unknown default:
            fatalError("Unknown FunctionalRoadClass value.")
        }
    }
}
