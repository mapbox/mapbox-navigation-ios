import Foundation
import Turf
import MapboxNavigationNative

/**
 `RoadGraph` provides methods to get edge shape (e.g. `RoadGraph.Edge`) and metadata.
 
 You do not create a `RoadGraph` object manually. Instead, observe the `Notification.Name.electronicHorizonDidUpdatePosition` notification to obtain edge identifiers and get more details about the edges using the `RouteController.roadGraph` or `PassiveLocationManager.roadGraph` property.
 
 - note: The Mapbox Electronic Horizon feature of the Mapbox Navigation SDK is in public beta and is subject to changes, including its pricing. Use of the feature is subject to the beta product restrictions in the Mapbox Terms of Service. Mapbox reserves the right to eliminate any free tier or free evaluation offers at any time and require customers to place an order to purchase the Mapbox Electronic Horizon feature, regardless of the level of use of the feature.
 */
public final class RoadGraph {

    // MARK: Getting Edge Info
    
    /**
     Returns metadata about the edge with the given edge identifier.
     
     - returns: Metadata about the edge with the given edge identifier, or `nil` if the edge is not in the cache.
     */
    public func edgeMetadata(edgeIdentifier: Edge.Identifier) -> Edge.Metadata? {
        if let edgeMetadata = native.getEdgeMetadata(forEdgeId: UInt64(edgeIdentifier)) {
            return Edge.Metadata(edgeMetadata)
        }
        return nil
    }

    /**
     Returns a line string geometry corresponding to the given edge identifier.
     
     - returns: A line string corresponding to the given edge identifier, or `nil` if the edge is not in the cache.
     */
    public func edgeShape(edgeIdentifier: Edge.Identifier) -> LineString? {
        guard let locations = native.getEdgeShape(forEdgeId: UInt64(edgeIdentifier)) else {
            return nil
        }
        return LineString(locations.map { $0.coordinate })
    }
    
    // MARK: Retrieving the Shape of an Object
    
    /**
     Returns a line string geometry corresponding to the given path.
     
     - returns: A line string corresponding to the given path, or `nil` if any of path edges are not in the cache.
     */
    public func shape(of path: Path) -> LineString? {
        guard let locations = native.getPathShape(for: GraphPath(path)) else {
            return nil
        }
        return LineString(locations.map { $0.coordinate })
    }
    
    /**
     Returns a point corresponding to the given position.
     
     - returns: A point corresponding to the given position, or `nil` if the edge is not in the cache.
     */
    public func shape(of position: Position) -> Point? {
        guard let location = native.getPositionCoordinate(for: GraphPosition(position)) else {
            return nil
        }
        return Point(location.coordinate)
    }

    init(_ native: GraphAccessor) {
        self.native = native
    }

    private let native: GraphAccessor
}
