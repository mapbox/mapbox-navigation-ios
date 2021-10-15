import Foundation
import MapboxNavigationNative

/**
 A human-readable name or route reference code that identifies a road.
 
 - note: The Mapbox Electronic Horizon feature of the Mapbox Navigation SDK is in public beta and is subject to changes, including its pricing. Use of the feature is subject to the beta product restrictions in the Mapbox Terms of Service. Mapbox reserves the right to eliminate any free tier or free evaluation offers at any time and require customers to place an order to purchase the Mapbox Electronic Horizon feature, regardless of the level of use of the feature.
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
