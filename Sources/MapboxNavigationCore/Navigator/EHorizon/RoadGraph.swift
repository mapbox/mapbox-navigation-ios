import Foundation
import MapboxNavigationNative_Private
import Turf

/// ``RoadGraph`` provides methods to get edge shape (e.g. ``RoadGraph/Edge``) and metadata.
///
/// You do not create a ``RoadGraph`` object manually. Instead, use the ``RoadMatching/roadGraph`` from
/// ``ElectronicHorizonController/roadMatching``
///
///  - Note: The Mapbox Electronic Horizon feature of the Mapbox Navigation SDK is in public beta and is subject to
/// changes, including its pricing. Use of the feature is subject to the beta product restrictions in the Mapbox Terms
/// of Service. Mapbox reserves the right to eliminate any free tier or free evaluation offers at any time and require
/// customers to place an order to purchase the Mapbox Electronic Horizon feature, regardless of the level of use of the
/// feature.
public final class RoadGraph: Sendable {
    // MARK: Getting Edge Info

    /// Returns metadata about the edge with the given edge identifier.
    /// - Parameter edgeIdentifier: The identifier of the edge to query.
    /// - Returns: Metadata about the edge with the given edge identifier, or `nil` if the edge is not in the cache.
    public func edgeMetadata(edgeIdentifier: Edge.Identifier) -> Edge.Metadata? {
        native.getEdgeMetadata(forEdgeId: UInt64(edgeIdentifier)).map { Edge.Metadata($0) }
    }

    /// Returns a line string geometry corresponding to the given edge identifier.
    ///
    /// - Parameter edgeIdentifier: The identifier of the edge to query.
    /// - Returns: A line string corresponding to the given edge identifier, or `nil` if the edge is not in the cache.
    public func edgeShape(edgeIdentifier: Edge.Identifier) -> LineString? {
        native.getEdgeShape(forEdgeId: UInt64(edgeIdentifier)).map {
            LineString($0.map(\.value))
        }
    }

    /// Returns ``RoadGraph/Edge/ADASAttributes`` corresponding to the given edge identifier.
    /// - Note: For this method to work, ``ElectronicHorizonConfig/enableEnhancedDataAlongEH``
    /// flag should be enabled during config.
    ///
    /// - Parameter edgeIdentifier: The identifier of the edge to query.
    /// - Returns: ``Edge/ADASAttributes`` corresponding to the given edge identifier,
    /// or `nil` if the edge is not in the cache.
    public func adasAttributes(edgeIdentifier: Edge.Identifier) -> Edge.ADASAttributes? {
        native.getAdasAttributes(forEdgeId: UInt64(edgeIdentifier)).map {
            Edge.ADASAttributes($0, edgeIdentifier: edgeIdentifier)
        }
    }

    // MARK: Retrieving the Shape of an Object

    /// Returns a line string geometry corresponding to the given path.
    ///
    /// - Parameter path: The path of the geometry.
    /// - Returns: A line string corresponding to the given path, or `nil` if any of path edges are not in the cache.
    public func shape(of path: Path) -> LineString? {
        native.getPathShape(for: GraphPath(path)).map {
            LineString($0.map(\.value))
        }
    }

    /// Returns a point corresponding to the given position.
    ///
    /// - Parameter position: The position of the point.
    /// - Returns: A point corresponding to the given position, or `nil` if the edge is not in the cache.
    public func shape(of position: Position) -> Point? {
        native.getPositionCoordinate(for: GraphPosition(position)).map {
            Point($0.value)
        }
    }

    init(_ native: GraphAccessor) {
        self.native = native
    }

    private let native: GraphAccessor
}

extension GraphAccessor: @unchecked Sendable {}
