import CoreLocation
import Foundation
@preconcurrency import MapboxNavigationNative

public struct RoadObjectAhead: Equatable, Sendable {
    public var roadObject: RoadObject
    public var distance: CLLocationDistance?

    public init(roadObject: RoadObject, distance: CLLocationDistance? = nil) {
        self.roadObject = roadObject
        self.distance = distance
    }
}

/// Describes the object on the road.
/// There are two sources of road objects: active route and the electronic horizon.
public struct RoadObject: Equatable, Sendable {
    /// Identifier of the road object. If we get the same objects (e.g. ``RoadObject/Kind/tunnel(_:)``) from the
    /// electronic horizon and the active route, they will not have the same IDs.
    public let identifier: RoadObject.Identifier

    ///  Length of the object, `nil` if the object is point-like.
    public let length: CLLocationDistance?

    ///  Location of the road object.
    public let location: RoadObject.Location

    ///  Kind of the road object with metadata.
    public let kind: RoadObject.Kind

    ///  `true` if an object is added by user, `false` if it comes from Mapbox service.
    public let isUserDefined: Bool

    ///  Indicates whether the road object is located in an urban area.
    ///  This property is set to `nil` if the road object comes from a call to the
    /// ``RoadObjectStore/roadObject(identifier:)`` method and ``RoadObject/location`` is set to
    /// ``RoadObject/Location/point(position:)``.
    public let isUrban: Bool?

    let native: MapboxNavigationNative.RoadObject?

    ///  Initializes a new `RoadObject` object.
    public init(
        identifier: RoadObject.Identifier,
        length: CLLocationDistance?,
        location: RoadObject.Location,
        kind: RoadObject.Kind,
        isUrban: Bool?
    ) {
        self.identifier = identifier
        self.length = length
        self.location = location
        self.kind = kind
        self.isUserDefined = true
        self.isUrban = isUrban
        self.native = nil
    }

    /// Initializes a new ``RoadObject`` object.
    init(
        identifier: RoadObject.Identifier,
        length: CLLocationDistance?,
        location: RoadObject.Location,
        kind: RoadObject.Kind
    ) {
        self.init(identifier: identifier, length: length, location: location, kind: kind, isUrban: nil)
    }

    public init(_ native: MapboxNavigationNative.RoadObject) {
        self.identifier = native.id
        self.length = native.length?.doubleValue
        self.location = RoadObject.Location(native.location)
        self.kind = RoadObject.Kind(type: native.type, metadata: native.metadata)
        self.isUserDefined = native.provider == .custom
        self.isUrban = native.isUrban?.boolValue
        self.native = native
    }
}
