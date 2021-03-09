import Foundation
import MapboxNavigationNative

public struct RoadName {
    /**
     The name of the road.
     
     If you display a name to the user, you may need to abbreviate common words like “East” or “Boulevard” to ensure that it fits in the allotted space.
     
     This property is set for large roundabouts that have their own names but not for smaller, unnamed roundabouts.
     */
    public let name: String?
    
    /**
     Any route reference code assigned to the road.
     
     A route reference code commonly consists of an alphabetic network code, a space or hyphen, and a route number. You should not assume that the network code is globally unique: for example, a network code of “NH” may indicate a “National Highway” or “New Hampshire”. Moreover, a route number may not even uniquely identify a route within a given network.
     
     If a highway ramp is part of a numbered route, its reference code is contained in this property. Otherwise, this property does not contain the route reference code of the adjoining road that appears on guide signage.
     */
    public let code: String?

    init(_ native: MapboxNavigationNative.RoadName) {
        if native.isShielded {
            name = native.name
            code = nil
        } else {
            name = nil
            code = native.name
        }
    }
}
