import Foundation
import MapboxNavigationNative
import Turf
@_implementationOnly import MapboxCommon_Private

/**
 Provides methods for road object matching.

 Matching results are delivered asynchronously via a delegate.
 In case of error (if there are no tiles in the cache, decoding failed, etc.) the object won't be matched.
 */
final public class RoadObjectMatcher {

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
    
    /**
     Object, which subscribes to events being sent from the `RoadObjectMatcherListener`, and passes them
     to the `RoadObjectMatcherDelegate`.
     */
    var internalRoadObjectMatcherListener: InternalRoadObjectMatcherListener!

    /**
     Matches given OpenLR object to the graph.

     - parameter location: OpenLR location of the road object, encoded in a base64 string.
     - parameter standard: Standard used to encode OpenLR location.
     - parameter identifier: Unique identifier of the object.
     */
    public func matchOpenLR(location: String, standard: OpenLRStandard, identifier: RoadObjectIdentifier) {
        native.matchOpenLR(forBase64Encoded: location, standard: MapboxNavigationNative.OpenLRStandard(standard), id: identifier)
    }

    /**
     Matches given polyline to the graph.
     Polyline should define a valid path on the graph,
     i.e. it should be possible to drive this path according to traffic rules.

     - parameter polyline: Polyline representing the object.
     - parameter identifier: Unique identifier of the object.
     */
    public func match(polyline: LineString, identifier: RoadObjectIdentifier) {
        native.matchPolyline(forPolyline: polyline.coordinates.map(CLLocation.init), id: identifier)
    }

    /**
     Matches a given polygon to the graph.
     "Matching" here means we try to find all intersections of the polygon with the road graph
     and track distances to those intersections as distance to the polygon.

     - parameter polygon: Polygon representing the object.
     - parameter identifier: Unique identifier of the object.
     */
    public func match(polygon: Polygon, identifier: RoadObjectIdentifier) {
        native.matchPolygon(forPolygon: polygon.outerRing.coordinates.map(CLLocation.init), id: identifier)
    }

    /**
     Matches given gantry (i.e. polyline orthogonal to the road) to the graph.
     "Matching" here means we try to find all intersections of the gantry with the road graph
     and track distances to those intersections as distance to the gantry.

     - parameter gantry: Gantry representing the object.
     - parameter identifier: Unique identifier of the object.
     */
    public func match(gantry: MultiPoint, identifier: RoadObjectIdentifier) {
        native.matchGantry(forGantry: gantry.coordinates.map(CLLocation.init), id: identifier)
    }

    /**
     Matches given point to road graph.

     - parameter point: Point representing the object.
     - parameter identifier: Unique identifier of the object.
     */
    public func match(point: CLLocationCoordinate2D, identifier: RoadObjectIdentifier) {
        native.matchPoint(forPoint: point, id: identifier)
    }

    /**
     Cancel road object matching.

     - parameter identifier: Identifier for which matching should be canceled.
     */
    public func cancel(identifier: RoadObjectIdentifier) {
        native.cancel(forId: identifier)
    }

    init(_ native: MapboxNavigationNative.RoadObjectMatcher) {
        self.native = native
        
        internalRoadObjectMatcherListener = InternalRoadObjectMatcherListener(roadObjectMatcher: self)
    }

    deinit {
        internalRoadObjectMatcherListener.delegate = nil
        native.setListenerFor(nil)
    }

    private func updateListener() {
        if delegate != nil {
            native.setListenerFor(internalRoadObjectMatcherListener)
        } else {
            native.setListenerFor(nil)
        }
    }
    
    var native: MapboxNavigationNative.RoadObjectMatcher {
        didSet {
            updateListener()
        }
    }
}

extension MapboxNavigationNative.RoadObjectMatcherError: Error {}

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
    
    public func onRoadObjectMatched(forRoadObject roadObject: Expected<AnyObject, AnyObject>) {
        guard let roadObjectMatcher = roadObjectMatcher else { return }
        
        let result = Result<MapboxNavigationNative.RoadObject,
                            MapboxNavigationNative.RoadObjectMatcherError>(expected: roadObject)
        switch result {
        case .success(let roadObject):
            delegate?.roadObjectMatcher(roadObjectMatcher, didMatch: RoadObject(roadObject))
        case .failure(let error):
            delegate?.roadObjectMatcher(roadObjectMatcher, didFailToMatchWith: RoadObjectMatcherError(error))
        }
    }
}
