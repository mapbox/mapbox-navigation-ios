import Foundation
import MapboxNavigationNative

/**
 An Electronic Horizon is a probable path (or paths) of a vehicle within the road graph which is
 used to surface metadata about the underlying edges of the graph for a certain distance in front
 of the vehicle thus extending the user's perspective beyond the “visible” horizon.

 Mapbox Electronic Horizon correlates the vehicle’s location to the road graph and broadcasts
 updates to the Electronic Horizon as the vehicle’s position and trajectory change.

 In Active Guidance state, the user-selected route and its metadata are used as the path for the
 Electronic Horizon. In a Free Drive state there is no active route selected, Mapbox Electronic
 Horizon will determine the most probable path from the vehicle’s current location.
 For both states Active Guidance and Free Drive, the Electronic Horizon and its metadata are
 exposed via the same interface as described below.

 We represent the road network ahead of us as a tree of edges. Each intersection has outbound
 edges and each edge has probability of transition to another edge as well as metadata which
 can be used to implement sophisticated features on top of it.
 */
public class ElectronicHorizon {

    /// The start edge from which EHorizon tree structure can be navigated
    public let start: Edge

    init(_ native: MapboxNavigationNative.ElectronicHorizon) {
        self.start = Edge(native.start)
    }
}
