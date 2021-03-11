import Foundation
import MapboxNavigationNative

/**
 A human-readable name or route reference code that identifies a road.
 */
public enum RoadName {
    /**
     A road name.
     
     If you display a name to the user, you may need to abbreviate common words like “East” or “Boulevard” to ensure that it fits in the allotted space.
     */
    case name(_ name: String)
    
    /**
     A route reference code assigned to a road.
     
     A route reference code commonly consists of an alphabetic network code, a space or hyphen, and a route number. You should not assume that the network code is globally unique: for example, a network code of “NH” may indicate a “National Highway” or “New Hampshire”. Moreover, a route number may not even uniquely identify a route within a given network.
     */
    case code(_ code: String)

    init(_ native: MapboxNavigationNative.RoadName) {
        if native.isShielded {
            self = .code(native.name)
        } else {
            self = .name(native.name)
        }
    }
}
