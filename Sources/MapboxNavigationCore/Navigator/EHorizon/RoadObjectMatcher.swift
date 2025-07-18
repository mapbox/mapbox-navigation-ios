import Foundation
import MapboxCommon_Private
import MapboxNavigationNative_Private
import Turf

/// Provides methods for road object matching.
///
/// Matching results are delivered asynchronously via a delegate.
/// In case of error (if there are no tiles in the cache, decoding failed, etc.) the object won't be matched.
/// Use the ``RoadMatching/roadObjectMatcher`` from ``ElectronicHorizonController/roadMatching``  to access the
/// currently active road object matcher.
///
/// - Note: The Mapbox Electronic Horizon feature of the Mapbox Navigation SDK is in public beta and is subject to
/// changes, including its pricing. Use of the feature is subject to the beta product restrictions in the Mapbox Terms
/// of Service. Mapbox reserves the right to eliminate any free tier or free evaluation offers at any time and require
/// customers to place an order to purchase the Mapbox Electronic Horizon feature, regardless of the level of use of the
/// feature.
public final class RoadObjectMatcher: @unchecked Sendable {
    // MARK: Matching Objects

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
        let openLR = MatchableOpenLr(
            openlr: OpenLR(base64Encoded: location, standard: standard),
            id: reference
        )
        native.matchOpenLRs(for: [openLR], options: MatchingOptions(
            useOnlyPreloadedTiles: false,
            allowPartialMatching: false,
            partialPolylineDistanceCalculationStrategy: .onlyMatched
        ))
    }

    /// Matches given polyline to the graph.
    /// Polyline should define a valid path on the graph, i.e. it should be possible to drive this path according to
    /// traffic rules.
    /// - Parameters:
    ///   - polyline: Polyline representing the object.
    ///   - identifier: Unique identifier of the object.
    public func match(polyline: LineString, identifier: RoadObject.Identifier) {
        let polyline = MatchableGeometry(id: identifier, coordinates: polyline.coordinates.map(Coordinate2D.init))
        native.matchPolylines(
            forPolylines: [polyline],
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
        let polygone = MatchableGeometry(
            id: identifier,
            coordinates: polygon.outerRing.coordinates.map(Coordinate2D.init)
        )
        native.matchPolygons(forPolygons: [polygone], options: MatchingOptions(
            useOnlyPreloadedTiles: false,
            allowPartialMatching: false,
            partialPolylineDistanceCalculationStrategy: .onlyMatched
        ))
    }

    /// Matches given gantry (i.e. polyline orthogonal to the road) to the graph.
    /// "Matching" here means we try to find all intersections of the gantry with the road graph and track distances to
    /// those intersections as distance to the gantry.
    /// - Parameters:
    ///   - gantry: Gantry representing the object.
    ///   - identifier: Unique identifier of the object.
    public func match(gantry: MultiPoint, identifier: RoadObject.Identifier) {
        let gantry = MatchableGeometry(id: identifier, coordinates: gantry.coordinates.map(Coordinate2D.init))
        native.matchGantries(
            forGantries: [gantry],
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

        let matchablePoint = MatchablePoint(id: identifier, coordinate: point, heading: trueHeading)
        native.matchPoints(
            for: [matchablePoint],
            options: MatchingOptions(
                useOnlyPreloadedTiles: false,
                allowPartialMatching: false,
                partialPolylineDistanceCalculationStrategy: .onlyMatched
            )
        )
    }

    /// Cancel road object matching.
    /// - Parameter identifier: Identifier for which matching should be canceled.
    public func cancel(identifier: RoadObject.Identifier) {
        native.cancel(forIds: [identifier])
    }

    // MARK: Observing Matching Results

    /// Road object matcher delegate.
    public weak var delegate: RoadObjectMatcherDelegate? {
        didSet {
            if delegate != nil {
                internalRoadObjectMatcherListener.delegate = delegate
            } else {
                internalRoadObjectMatcherListener.delegate = nil
            }
            updateListener()
        }
    }

    private func updateListener() {
        if delegate != nil {
            native.setListenerFor(internalRoadObjectMatcherListener)
        } else {
            native.setListenerFor(nil)
        }
    }

    var native: MapboxNavigationNative_Private.RoadObjectMatcher {
        didSet {
            updateListener()
        }
    }

    /// Object, which subscribes to events being sent from the ``RoadObjectMatcherListener``, and passes them to the
    /// ``RoadObjectMatcherDelegate``.
    var internalRoadObjectMatcherListener: InternalRoadObjectMatcherListener!

    init(_ native: MapboxNavigationNative_Private.RoadObjectMatcher) {
        self.native = native

        self.internalRoadObjectMatcherListener = InternalRoadObjectMatcherListener(roadObjectMatcher: self)
    }

    deinit {
        internalRoadObjectMatcherListener.delegate = nil
        native.setListenerFor(nil)
    }
}

extension MapboxNavigationNative_Private.RoadObjectMatcherError: Error, @unchecked Sendable {}

extension CLLocation {
    convenience init(coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

// Since `MBXExpected` cannot be exposed publicly `InternalRoadObjectMatcherListener` works as an
// intermediary by subscribing to the events from the `RoadObjectMatcherListener`, and passing them
// to the `RoadObjectMatcherDelegate`.
class InternalRoadObjectMatcherListener: RoadObjectMatcherListener {
    weak var roadObjectMatcher: RoadObjectMatcher?

    weak var delegate: RoadObjectMatcherDelegate?

    init(roadObjectMatcher: RoadObjectMatcher) {
        self.roadObjectMatcher = roadObjectMatcher
    }

    public func onRoadObjectMatched(
        forRoadObject roadObject: Expected<
            MapboxNavigationNative_Private.RoadObject,
            MapboxNavigationNative_Private.RoadObjectMatcherError
        >
    ) {
        guard let roadObjectMatcher else { return }

        let result = Result<
            MapboxNavigationNative_Private.RoadObject,
            MapboxNavigationNative_Private.RoadObjectMatcherError
        >(expected: roadObject)
        switch result {
        case .success(let roadObject):
            delegate?.roadObjectMatcher(roadObjectMatcher, didMatch: RoadObject(roadObject))
        case .failure(let error):
            delegate?.roadObjectMatcher(roadObjectMatcher, didFailToMatchWith: RoadObjectMatcherError(error))
        }
    }

    func onMatchingCancelled(forId id: String) {
        guard let roadObjectMatcher else { return }
        delegate?.roadObjectMatcher(roadObjectMatcher, didCancelMatchingFor: id)
    }
}
