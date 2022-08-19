import Foundation
import CoreLocation
import MapboxNavigationNative

/**
 * Describes the object on the road.
 * There are two sources of road objects: active route and the electronic horizon.
 */
public struct RoadObject {

    /**
     * Identifier of the road object. If we get the same objects (e.g. `RoadObject.ObjectType.tunnel`) from the
     * electronic horizon and the active route, they will not have the same IDs.
     */
    public let identifier: RoadObject.Identifier

    /** Length of the object, `nil` if the object is point-like. */
    public let length: CLLocationDistance?

    /** Location of the road object. */
    public let location: RoadObject.Location

    /** Kind of the road object with metadata. */
    public let kind: RoadObject.Kind

    /** `true` if an object is added by user, `false` if it comes from Mapbox service. */
    public let isUserDefined: Bool
    
    /**
    Indicates whether the road object is located in an urban area.
    This property is set to `nil` if the road object comes from a call to the `RoadObjectStore.roadObject(identifier:)` method and `location` is set to `RoadObject.Location.point(_:)`.
    */
    public let isUrban: Bool?

    let native: MapboxNavigationNative.RoadObject?

    /**
     Initializes a new `RoadObject` object.
     */
    public init(identifier: RoadObject.Identifier,
                length: CLLocationDistance?,
                location: RoadObject.Location,
                kind: RoadObject.Kind,
                isUrban: Bool?) {
        self.identifier = identifier
        self.length = length
        self.location = location
        self.kind = kind
        isUserDefined = true
        self.isUrban = isUrban
        native = nil
    }
    
    /**
     Initializes a new `RoadObject` object.
     */
    init(identifier: RoadObject.Identifier,
                     length: CLLocationDistance?,
                     location: RoadObject.Location,
                     kind: RoadObject.Kind) {
        self.init(identifier: identifier, length: length, location: location, kind: kind, isUrban: nil)
    }

    init(_ native: MapboxNavigationNative.RoadObject) {
        identifier = native.id
        length = native.length?.doubleValue
        location = RoadObject.Location(native.location)
        kind = RoadObject.Kind(type: native.type, metadata: native.metadata)
        isUserDefined = native.provider == .custom
        isUrban = native.isUrban?.boolValue
        self.native = native
    }
}
