import Foundation
import MapboxNavigationNative

/**
 An electronic horizon is a probable path (or paths) of a vehicle within the routing graph. This structure contains metadata about the underlying edges of the graph for a certain distance in front of the vehicle, thus extending the user’s perspective beyond the “visible” horizon as the vehicle’s position and trajectory change.

 During active turn-by-turn navigation, the user-selected route and its metadata influence the path of the electronic horizon determined by `RouteController`. During passive navigation (free-driving), no route is actively selected, so `PassiveLocationDataSource` will determine the most probable path from the vehicle’s current location. You can receive notifications about changes in the current state of the electronic horizon by observing the `Notification.Name.electronicHorizonDidUpdatePosition`, `Notification.Name.electronicHorizonDidEnterRoadObject`, and `Notification.Name.electronicHorizonDidExitRoadObject` notifications.

 The road network ahead of the user is represented as a tree of edges. Each intersection has outlet edges. In turn, each edge has a probability of transition to another edge, as well as details about the road segment that the edge traverses. You can use these details to influence application behavior based on predicted upcoming conditions.
 */
public struct ElectronicHorizon {

    /// The starting edge leading to the upcoming probable paths.
    public let start: Edge

    init(_ native: MapboxNavigationNative.ElectronicHorizon) {
        self.start = Edge(native.start)
    }
}
