import Foundation
import MapboxNavigationNative

/**
 `GraphAccessor` provides methods to get edge shape (e.g. [EHorizonEdge]) and metadata.
 */
public final class GraphAccessor {
    /**
     Returns Graph Edge meta-information for the given GraphId of the edge.
     If edge with given edgeIdentifier is not accessible, returns `nil`
     */
    public func getEdgeMetadata(for edgeIdentifier: UInt) -> EHorizonEdgeMetadata? {
        if let edgeMetadata = try! native.getEdgeMetadata(forEdgeId: UInt64(edgeIdentifier)) {
            return EHorizonEdgeMetadata(edgeMetadata)
        }
        return nil
    }

    /**
     Returns Graph Edge geometry for the given GraphId of the edge.
     If edge with given edgeIdentifier is not accessible, returns `nil`
     */
    public func getEdgeShape(for edgeIdentifier: UInt) -> [CLLocation]? {
        return try! native.getEdgeShape(forEdgeId: UInt64(edgeIdentifier))
    }

    init(_ native: MapboxNavigationNative.GraphAccessor) {
        self.native = native
    }

    private let native: MapboxNavigationNative.GraphAccessor
}
