import Foundation
import MapboxNavigationNative

/**
 DistanceInfo is an internal data of OpenLRLineLocation.
 It's not intended to be read or set from the outside.
 */
public struct DistanceInfo {

    public let distance: Double

    public let length: Double

    init(_ native: DistanceInfo) {
        self.distance = native.distance
        self.length = native.length
    }
}
