import Foundation
import MapboxNavigationNative

/** Identifies a road object according to one of two OpenLR standards.
 
 - note: The Mapbox Electronic Horizon feature of the Mapbox Navigation SDK is in public beta and is subject to changes, including its pricing. Use of the feature is subject to the beta product restrictions in the Mapbox Terms of Service. Mapbox reserves the right to eliminate any free tier or free evaluation offers at any time and require customers to place an order to purchase the Mapbox Electronic Horizon feature, regardless of the level of use of the feature.
 */
public enum OpenLRIdentifier {

    /**
     [TomTom OpenLR](http://www.openlr.org/).

     Supported references: line location, point along line, polygon.
     */
    case tomTom(reference: RoadObject.Identifier)

    /**
     TPEG OpenLR.

     Only line locations are supported.
     */
    case tpeg(reference: RoadObject.Identifier)
}

extension MapboxNavigationNative.OpenLRStandard {
    init(identifier: OpenLRIdentifier) {
        switch identifier {
        case .tomTom(_):
            self = .tomTom
        case .tpeg(_):
            self = .TPEG
        }
    }
}
