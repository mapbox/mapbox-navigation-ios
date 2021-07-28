import Foundation
import CoreLocation
import MapboxNavigationNative

/**
 * Contains information about distance to the road object of a concrete
 * type/shape (gantry, polygon, line, point etc.).
 */
public enum DistancedRoadObject {
    /**
     The information about distance to the road object represented as a point.
     - parameter identifier: Road object identifier.
     - parameter type: Road object type.
     - parameter distance: Distance to the point object, measured in meters.
     */
    case point(identifier: RoadObjectIdentifier, type: RoadObjectType, distance: CLLocationDistance)
    
    /**
     The information about distance to the road object represented as a gantry.
     - parameter identifier: Road object identifier.
     - parameter type: Road object type.
     - parameter distance: Distance to the gantry object.
     */
    case gantry(identifier: RoadObjectIdentifier, type: RoadObjectType, distance: CLLocationDistance)
    
    /**
     The information about distance to the road object represented as a polygon.
     - parameter identifier: Road object identifier.
     - parameter type: Road object type.
     - parameter distanceToNearestEntry: Distance measured in meters to the nearest entry.
     - parameter distanceToNearestExit: Distance measured in meters to nearest exit.
     - parameter isInside: Boolean to indicate whether we're currently "inside" the object.
     */
    case polygon(identifier: RoadObjectIdentifier,
                 type: RoadObjectType,
                 distanceToNearestEntry: CLLocationDistance,
                 distanceToNearestExit: CLLocationDistance,
                 isInside: Bool)

    /**
     The information about distance to the road object represented as a subgraph.
     - parameter identifier: Road object identifier.
     - parameter type: Road object type.
     - parameter distanceToNearestEntry: Distance measured in meters to the nearest entry.
     - parameter distanceToNearestExit: Distance measured in meters to the nearest exit.
     - parameter isInside: Boolean that indicates whether we're currently "inside" the object.
     */
    case subgraph(identifier: RoadObjectIdentifier,
                  type: RoadObjectType,
                  distanceToNearestEntry: CLLocationDistance,
                  distanceToNearestExit: CLLocationDistance,
                  isInside: Bool)
    
    /**
     The information about distance to the road object represented as a line.
     - parameter identifier: Road object identifier.
     - parameter type: Road object type.
     - parameter distanceToEntry: Distance from the current position to entry point measured in meters along the road graph. This value is 0 if already "within" the object.
     - parameter distanceToExit" Distance from the current position to the most likely exit point measured in meters along the road graph.
     - parameter distanceToEnd: Distance from the current position to the most distance exit point measured in meters along the road graph.
     - parameter isEntryFromStart: Boolean that indicates whether we enter the road object from its start. This value is `false` if already "within" the object.
     - parameter length: Length of the road object measured in meters.
     */
    case line(identifier: RoadObjectIdentifier,
              type: RoadObjectType,
              distanceToEntry: CLLocationDistance,
              distanceToExit: CLLocationDistance,
              distanceToEnd: CLLocationDistance,
              isEntryFromStart: Bool,
              length: CLLocationDistance)

    /** Road object identifier */
    public var identifier: RoadObjectIdentifier {
        switch self {
        case .point(let identifier, _, _),
             .gantry(let identifier, _, _),
             .polygon(let identifier, _, _, _, _),
             .subgraph(let identifier, _, _, _, _),
             .line(let identifier, _, _, _, _, _, _):
            return identifier
        }
    }

    /** Road object type */
    public var type: RoadObjectType {
        switch self {
        case .point(_, let type, _),
             .gantry(_, let type, _),
             .polygon(_, let type, _, _, _),
             .subgraph(_, let type, _, _, _),
             .line(_, let type, _, _, _, _, _):
            return type
        }
    }

    init(_ native: MapboxNavigationNative.RoadObjectDistance) {
        if native.distanceInfo.isPointDistanceInfo() {
            let info = native.distanceInfo.getPointDistanceInfo()
            self = .point(identifier: native.roadObjectId,
                          type: RoadObjectType(native.type),
                          distance: info.distance)
        } else if native.distanceInfo.isGantryDistanceInfo() {
            let info = native.distanceInfo.getGantryDistanceInfo()
            self = .gantry(identifier: native.roadObjectId,
                           type: RoadObjectType(native.type),
                           distance: info.distance)
        } else if native.distanceInfo.isPolygonDistanceInfo() {
            let info = native.distanceInfo.getPolygonDistanceInfo()
            self = .polygon(identifier: native.roadObjectId,
                            type: RoadObjectType(native.type),
                            distanceToNearestEntry: info.entrances.first?.distance ?? -1.0,
                            distanceToNearestExit: info.exits.first?.distance ?? -1.0,
                            isInside: info.isInside)
        } else if native.distanceInfo.isSubGraphDistanceInfo() {
            let info = native.distanceInfo.getSubGraphDistanceInfo()
            self = .subgraph(identifier: native.roadObjectId,
                             type: RoadObjectType(native.type),
                             distanceToNearestEntry: info.entrances.first?.distance ?? -1.0,
                             distanceToNearestExit: info.exits.first?.distance ?? -1.0,
                             isInside: info.isInside)
        } else if native.distanceInfo.isLineDistanceInfo() {
            let info = native.distanceInfo.getLineDistanceInfo()
            self = .line(identifier: native.roadObjectId,
                         type: RoadObjectType(native.type),
                         distanceToEntry: info.distanceToEntry,
                         distanceToExit: info.distanceToExit,
                         distanceToEnd: info.distanceToEnd,
                         isEntryFromStart: info.isEntryFromStart,
                         length: info.length)
        } else {
            preconditionFailure("DistancedRoadObject can't be constructed. Unknown type.")
        }
    }
}
