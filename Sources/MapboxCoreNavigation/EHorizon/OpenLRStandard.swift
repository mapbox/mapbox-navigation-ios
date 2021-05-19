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
}

extension MapboxNavigationNative.OpenLRStandard {
    init(_ standard: OpenLRStandard) {
        switch standard {
        case .tomTom:
            self = .tomTom
        case .tpeg:
            self = .TPEG
        }
    }
}
