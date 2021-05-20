import Foundation
import CoreLocation
import MapboxNavigationNative

/**
 * Describes the object on the road.
 * There are two sources of road objects: active route and the electronic horizon.
 */
public struct RoadObject {

    /**
     * Identifier of the road object. If we get the same objects (e.g. `RoadObjectType.tunnel`) from the
     * electronic horizon and the active route, they will not have the same IDs.
     */
    public let identifier: RoadObjectIdentifier

    /** Length of the object, `nil` if the object is point-like. */
    public let length: CLLocationDistance?

    /** Location of the road object. */
    public let location: RoadObjectLocation

    /** Type of the road object with metadata. */
    public let type: RoadObjectType

    /** `true` if an object is added by user, `false` if it comes from Mapbox service. */
    public let isUserDefined: Bool

    let native: MapboxNavigationNative.RoadObject?

    /**
     Initializes a new `RoadObject` object.
     */
    public init(identifier: RoadObjectIdentifier, length: CLLocationDistance?, location: RoadObjectLocation, type: RoadObjectType) {
        self.identifier = identifier
        self.length = length
        self.location = location
        self.type = type
        isUserDefined = true
        native = nil
    }

    init(_ native: MapboxNavigationNative.RoadObject) {
        identifier = native.id
        length = native.length?.doubleValue
        location = RoadObjectLocation(native.location)
        type = RoadObjectType(type: native.type, metadata: native.metadata)
        isUserDefined = native.provider == .custom
        self.native = native
    }
}
