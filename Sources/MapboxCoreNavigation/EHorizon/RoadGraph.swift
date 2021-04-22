import Foundation
import Turf
import MapboxNavigationNative

/**
 `RoadGraph` provides methods to get edge shape (e.g. `ElectronicHorizonEdge`) and metadata.
 
 You do not create a `RoadGraph` object manually. Instead, observe the `Notification.Name.electronicHorizonDidUpdatePosition` notification to obtain edge identifiers and get more details about the edges using the `RouteController.roadGraph` or `PassiveLocationDataSource.roadGraph` property.
 */
public final class RoadGraph {

    /**
     Returns metadata about the edge with the given edge identifier.
     
     - returns: Metadata about the edge with the given edge identifier, or `nil` if the edge is inaccessible.
     */
    public func edgeMetadata(edgeIdentifier: ElectronicHorizonEdge.Identifier) -> ElectronicHorizonEdge.Metadata? {
        if let edgeMetadata = native.getEdgeMetadata(forEdgeId: UInt64(edgeIdentifier)) {
            return ElectronicHorizon.Edge.Metadata(edgeMetadata)
        }
        return nil
    }

    /**
     Returns a line string geometry corresponding to the given edge identifier.
     
     - returns: A line string corresponding to the given edge identifier, or `nil` if the edge is inaccessible.
     */
    public func edgeShape(edgeIdentifier: ElectronicHorizonEdge.Identifier) -> LineString? {
        guard let locations = native.getEdgeShape(forEdgeId: UInt64(edgeIdentifier)) else {
            return nil
        }
        return LineString(locations.map { $0.coordinate })
    }

    init(_ native: GraphAccessor) {
        self.native = native
    }

    private let native: GraphAccessor
}
