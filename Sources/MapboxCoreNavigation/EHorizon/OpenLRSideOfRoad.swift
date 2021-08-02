import Foundation
import MapboxNavigationNative

/**
 * Describes the relationship between the road object and the road.
 * The road object can be on the right side of the road, on the left side of the road, on both
 * sides of the road or directly on the road.
 */
public enum OpenLRSideOfRoad {
    
    /**
     The relationship between the road object and the road is unknown.
     */
    case unknown
    /**
     The road object is on the right side of the road.
     */
    case right
    /**
     The road object is on the left side of the road.
     */
    case left
    /**
     The road object is on both sides of the road or directly on the road.
     */
    case both

    init(_ native: MapboxNavigationNative.OpenLRSideOfRoad) {
        switch native {
        case .onRoadOrUnknown:
            self = .unknown
        case .right:
            self = .right
        case .left:
            self = .left
        case .both:
            self = .both
        @unknown default:
            fatalError("Unknown OpenLRSideOfRoad value.")
        }
    }
}
