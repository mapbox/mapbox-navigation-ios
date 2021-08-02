import Foundation
import MapboxNavigationNative

/**
 * Describes the relationship between the road object and the direction of a
 * referenced line. The road object may be directed in the same direction as the line, against
 * that direction, both directions, or the direction of the road object might be unknown.
 */
public enum OpenLROrientation {
    /**
     The relationship between the road object and the direction of the referenced line is unknown.
     */
    case unknown
    /**
     The road object is directed in the same direction as the referenced line.
     */
    case alongLine
    /**
     The road object is directed against the direction of the referenced line.
     */
    case againstLine
    /**
     The road object is directed in both directions.
     */
    case both

    init(_ native: MapboxNavigationNative.OpenLROrientation) {
        switch native {
        case .noOrientationOrUnknown:
            self = .unknown
        case .withLineDirection:
            self = .alongLine
        case .againstLineDirection:
            self = .againstLine
        case .both:
            self = .both
        @unknown default:
            fatalError("Unknown OpenLROrientation type.")
        }
    }
}
