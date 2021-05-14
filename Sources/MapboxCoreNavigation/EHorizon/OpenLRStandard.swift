import Foundation
import MapboxNavigationNative

/** Standard of OpenLR */
public enum OpenLRStandard {

    /**
     [TomTom OpenLR](http://www.openlr.org/).

     Supported references: line location, point along line, polygon.
     */
    case tomTom

    /**
     TPEG OpenLR.

     Only line locations are supported.
     */
    case tpeg

    var native: MapboxNavigationNative.OpenLRStandard {
        switch self {
        case .tomTom:
            return .tomTom
        case .tpeg:
            return .TPEG
        }
    }
}
