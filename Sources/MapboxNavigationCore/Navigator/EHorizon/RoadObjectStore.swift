import Foundation
import MapboxCommon_Private
import MapboxNavigationNative_Private
import Turf

extension RoadObject {
    /// Identifies a road object in an electronic horizon. A road object represents a notable transition point along a
    /// road, such as a toll booth or tunnel entrance. A road object is similar to a ``RouteAlert`` but is more closely
    /// associated with the routing graph managed by the ``RoadGraph`` class.
    ///
    ///  Use a ``RoadObjectStore`` object to get more information about a road object with a given identifier or get the
    /// locations of road objects along ``RoadGraph/Edge``s.
    public typealias Identifier = String
}

/// Stores and provides access to metadata about road objects.
///
/// You do not create a ``RoadObjectStore`` object manually. Instead, use the ``RoadMatching/roadObjectStore`` from
/// ``ElectronicHorizonController/roadMatching``  to access the currently active road object store.
///
/// - Note: The Mapbox Electronic Horizon feature of the Mapbox Navigation SDK is in public beta and is subject to
/// changes, including its pricing. Use of the feature is subject to the beta product restrictions in the Mapbox Terms
/// of Service. Mapbox reserves the right to eliminate any free tier or free evaluation offers at any time and require
/// customers to place an order to purchase the Mapbox Electronic Horizon feature, regardless of the level of use of the
/// feature.
public final class RoadObjectStore: @unchecked Sendable {
    /// The road object store’s delegate.
    public weak var delegate: RoadObjectStoreDelegate? {
        didSet {
            updateObserver()
        }
    }

    // MARK: Getting Road Objects Data

    /// - Parameter edgeIdentifier: The identifier of the edge to query.
    /// - Returns: Returns mapping `road object identifier ->` ``RoadObject/EdgeLocation`` for all road objects which
    /// are lying on the edge with given identifier.
    public func roadObjectEdgeLocations(
        edgeIdentifier: RoadGraph.Edge
            .Identifier
    ) -> [RoadObject.Identifier: RoadObject.EdgeLocation] {
        let objects = native.getForEdgeId(UInt64(edgeIdentifier))
        return objects.mapValues(RoadObject.EdgeLocation.init)
    }

    /// Since road objects can be removed/added in background we should always check return value for `nil`, even if we
    /// know that we have object with such identifier based on previous calls.
    /// - Parameter roadObjectIdentifier: The identifier of the road object to query.
    /// - Returns: Road object with given identifier, if such object cannot be found returns `nil`.
    public func roadObject(identifier roadObjectIdentifier: RoadObject.Identifier) -> RoadObject? {
        if let roadObject = native.getRoadObject(forId: roadObjectIdentifier) {
            return RoadObject(roadObject)
        }
        return nil
    }

    /// Returns the list of road object ids which are (partially) belong to `edgeIds`.
    /// - Parameter edgeIdentifiers: The list of edge ids.
    /// - Returns: The list of road object ids which are (partially) belong to `edgeIds`.
    public func roadObjectIdentifiers(edgeIdentifiers: [RoadGraph.Edge.Identifier]) -> [RoadObject.Identifier] {
        return native.getRoadObjectIdsByEdgeIds(forEdgeIds: edgeIdentifiers.map(NSNumber.init))
    }

    // MARK: Managing Custom Road Objects

    /// Matches given OpenLR object to the graph.
    /// - Parameters:
    ///   - location: OpenLR location of the road object, encoded in a base64 string.
    ///   - identifier: Unique identifier of the object.
    public func matchOpenLR(location: String, identifier: OpenLRIdentifier) {
        let standard = MapboxNavigationNative_Private.Standard(identifier: identifier)
        let reference: RoadObject.Identifier = switch identifier {
        case .tomTom(let ref):
            ref
        case .tpeg(let ref):
            ref
        }

        let openlr = OpenLR(base64Encoded: location, standard: standard)
        native.addCustomRoadObject(
            for: UnmatchedRoadObject(
                id: reference,
                geometry: UnmatchedRoadObjectGeometry.fromOpenLR(openlr),
                geometryKind: UnmatchedRoadObjectGeometryKind.openLR,
                heading: nil
            ),
            options: MatchingOptions(
                useOnlyPreloadedTiles: false,
                allowPartialMatching: false,
                partialPolylineDistanceCalculationStrategy: .onlyMatched
            )
        )
    }

    /// Matches given polyline to the graph.
    /// Polyline should define a valid path on the graph, i.e. it should be possible to drive this path according to
    /// traffic rules.
    /// - Parameters:
    ///   - polyline: Polyline representing the object.
    ///   - identifier: Unique identifier of the object.
    public func match(polyline: LineString, identifier: RoadObject.Identifier) {
        native.addCustomRoadObject(
            for: UnmatchedRoadObject(
                id: identifier,
                geometry: UnmatchedRoadObjectGeometry
                    .fromNSArray(polyline.coordinates.map(Coordinate2D.init)),
                geometryKind: UnmatchedRoadObjectGeometryKind.polyline,
                heading: nil
            ),
            options: MatchingOptions(
                useOnlyPreloadedTiles: false,
                allowPartialMatching: false,
                partialPolylineDistanceCalculationStrategy: .onlyMatched
            )
        )
    }

    /// Matches a given polygon to the graph.
    /// "Matching" here means we try to find all intersections of the polygon with the road graph and track distances to
    /// those intersections as distance to the polygon.
    /// - Parameters:
    ///   -  polygon: Polygon representing the object.
    ///   -  identifier: Unique identifier of the object.
    public func match(polygon: Polygon, identifier: RoadObject.Identifier) {
        native.addCustomRoadObject(
            for: UnmatchedRoadObject(
                id: identifier,
                geometry: UnmatchedRoadObjectGeometry
                    .fromNSArray(polygon.outerRing.coordinates.map(Coordinate2D.init)),
                geometryKind: UnmatchedRoadObjectGeometryKind.polygon,
                heading: nil
            ),
            options: MatchingOptions(
                useOnlyPreloadedTiles: false,
                allowPartialMatching: false,
                partialPolylineDistanceCalculationStrategy: .onlyMatched
            )
        )
    }

    /// Matches given gantry (i.e. polyline orthogonal to the road) to the graph.
    /// "Matching" here means we try to find all intersections of the gantry with the road graph and track distances to
    /// those intersections as distance to the gantry.
    /// - Parameters:
    ///   - gantry: Gantry representing the object.
    ///   - identifier: Unique identifier of the object.
    public func match(gantry: MultiPoint, identifier: RoadObject.Identifier) {
        native.addCustomRoadObject(
            for: UnmatchedRoadObject(
                id: identifier,
                geometry: UnmatchedRoadObjectGeometry
                    .fromNSArray(gantry.coordinates.map(Coordinate2D.init)),
                geometryKind: UnmatchedRoadObjectGeometryKind.gantry,
                heading: nil
            ),
            options: MatchingOptions(
                useOnlyPreloadedTiles: false,
                allowPartialMatching: false,
                partialPolylineDistanceCalculationStrategy: .onlyMatched
            )
        )
    }

    /// Matches given point to road graph.
    /// - Parameters:
    ///   - point: Point representing the object.
    ///   - identifier: Unique identifier of the object.
    ///   - heading: Heading of the provided point, which is going to be matched.
    public func match(point: CLLocationCoordinate2D, identifier: RoadObject.Identifier, heading: CLHeading? = nil) {
        var trueHeading: NSNumber?
        if let heading, heading.trueHeading >= 0.0 {
            trueHeading = NSNumber(value: heading.trueHeading)
        }

        native.addCustomRoadObject(
            for: UnmatchedRoadObject(
                id: identifier,
                geometry: UnmatchedRoadObjectGeometry.fromCLLocationCoordinate2D(point),
                geometryKind: UnmatchedRoadObjectGeometryKind.point,
                heading: trueHeading
            ),
            options: MatchingOptions(
                useOnlyPreloadedTiles: false,
                allowPartialMatching: false,
                partialPolylineDistanceCalculationStrategy: .onlyMatched
            )
        )
    }

    /// Removes road object and stops tracking it in the electronic horizon.
    /// - Parameter identifier: Identifier of the road object that should be removed.
    public func removeUserDefinedRoadObject(identifier: RoadObject.Identifier) {
        native.removeCustomRoadObject(forId: identifier)
    }

    /// Removes all user-defined road objects from the store and stops tracking them in the electronic horizon.
    public func removeAllUserDefinedRoadObjects() {
        native.removeAllCustomRoadObjects()
    }

    init(_ native: MapboxNavigationNative_Private.RoadObjectsStore) {
        self.native = native
    }

    deinit {
        if native.hasObservers() {
            native.removeObserver(for: self)
        }
    }

    var native: MapboxNavigationNative_Private.RoadObjectsStore {
        didSet {
            updateObserver()
        }
    }

    private func updateObserver() {
        if delegate != nil {
            native.addObserver(for: self)
        } else {
            if native.hasObservers() {
                native.removeObserver(for: self)
            }
        }
    }
}

extension RoadObjectStore: RoadObjectsStoreObserver {
    public func onRoadObjectAdded(forId id: String) {
        delegate?.didAddRoadObject(identifier: id)
    }

    public func onRoadObjectUpdated(forId id: String) {
        delegate?.didUpdateRoadObject(identifier: id)
    }

    public func onRoadObjectRemoved(forId id: String) {
        delegate?.didRemoveRoadObject(identifier: id)
    }

    public func onCustomRoadObjectMatched(forId id: String) {
        delegate?.didMatchCustomRoadObject(identifier: id)
    }

    public func onCustomRoadObjectAddingCancelled(forId id: String) {
        delegate?.didCancelCustomRoadObjectAdding(identifier: id)
    }

    public func onCustomRoadObjectMatchingFailed(forId id: String) {
        delegate?.didFailCustomRoadObjectMatching(identifier: id)
    }
}
