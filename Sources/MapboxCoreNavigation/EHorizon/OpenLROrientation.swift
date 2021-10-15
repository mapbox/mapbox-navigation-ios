import Foundation
import MapboxNavigationNative

/**
 * Describes the relationship between the road object and the direction of a
 * referenced line. The road object may be directed in the same direction as the line, against
 * that direction, both directions, or the direction of the road object might be unknown.
 *
 * - note: The Mapbox Electronic Horizon feature of the Mapbox Navigation SDK is in public beta and is subject to changes, including its pricing. Use of the feature is subject to the beta product restrictions in the Mapbox Terms of Service. Mapbox reserves the right to eliminate any free tier or free evaluation offers at any time and require customers to place an order to purchase the Mapbox Electronic Horizon feature, regardless of the level of use of the feature.
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
