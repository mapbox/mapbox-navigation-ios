import Foundation
import MapboxNavigationNative

/** Identifies a road object according to one of two OpenLR standards. */
public enum OpenLRIdentifier {

    /**
     [TomTom OpenLR](http://www.openlr.org/).

     Supported references: line location, point along line, polygon.
     */
    case tomTom(reference: RoadObjectIdentifier)

    /**
     TPEG OpenLR.

     Only line locations are supported.
     */
    case tpeg(reference: RoadObjectIdentifier)
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
