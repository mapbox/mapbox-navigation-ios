#if canImport(CoreLocation)
import CoreLocation
#endif
import Turf

/// A ``Waypoint`` object indicates a location along a route. It may be the route’s origin or destination, or it may be
/// another location that the route visits. A waypoint object indicates the location’s geographic location along with
/// other optional information, such as a name or the user’s direction approaching the waypoint. You create a
/// ``RouteOptions`` object using waypoint objects and also receive waypoint objects in the completion handler of the
/// `Directions.calculate(_:completionHandler:)` method.
public struct Waypoint: Codable, ForeignMemberContainer, Equatable, Sendable {
    public var foreignMembers: JSONObject = [:]

    private enum CodingKeys: String, CodingKey, CaseIterable {
        case coordinate = "location"
        case coordinateAccuracy
        case targetCoordinate
        case heading
        case headingAccuracy
        case separatesLegs
        case name
        case allowsArrivingOnOppositeSide
        case snappedDistance = "distance"
        case layer
    }

    // MARK: Creating a Waypoint

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.coordinate = try container.decode(LocationCoordinate2DCodable.self, forKey: .coordinate).decodedCoordinates

        self.coordinateAccuracy = try container.decodeIfPresent(LocationAccuracy.self, forKey: .coordinateAccuracy)

        self.targetCoordinate = try container.decodeIfPresent(
            LocationCoordinate2DCodable.self,
            forKey: .targetCoordinate
        )?.decodedCoordinates

        self.heading = try container.decodeIfPresent(LocationDirection.self, forKey: .heading)

        self.headingAccuracy = try container.decodeIfPresent(LocationDirection.self, forKey: .headingAccuracy)

        if let separates = try container.decodeIfPresent(Bool.self, forKey: .separatesLegs) {
            self.separatesLegs = separates
        }

        if let allows = try container.decodeIfPresent(Bool.self, forKey: .allowsArrivingOnOppositeSide) {
            self.allowsArrivingOnOppositeSide = allows
        }

        if let name = try container.decodeIfPresent(String.self, forKey: .name),
           !name.isEmpty
        {
            self.name = name
        } else {
            self.name = nil
        }

        self.snappedDistance = try container.decodeIfPresent(LocationDistance.self, forKey: .snappedDistance)

        self.layer = try container.decodeIfPresent(Int.self, forKey: .layer)

        try decodeForeignMembers(notKeyedBy: CodingKeys.self, with: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(LocationCoordinate2DCodable(coordinate), forKey: .coordinate)
        try container.encodeIfPresent(coordinateAccuracy, forKey: .coordinateAccuracy)
        let targetCoordinateCodable = targetCoordinate != nil ? LocationCoordinate2DCodable(targetCoordinate!) : nil
        try container.encodeIfPresent(targetCoordinateCodable, forKey: .targetCoordinate)
        try container.encodeIfPresent(heading, forKey: .heading)
        try container.encodeIfPresent(headingAccuracy, forKey: .headingAccuracy)
        try container.encodeIfPresent(separatesLegs, forKey: .separatesLegs)
        try container.encodeIfPresent(allowsArrivingOnOppositeSide, forKey: .allowsArrivingOnOppositeSide)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(snappedDistance, forKey: .snappedDistance)
        try container.encodeIfPresent(layer, forKey: .layer)

        try encodeForeignMembers(notKeyedBy: CodingKeys.self, to: encoder)
    }

    /// Initializes a new waypoint object with the given geographic coordinate and an optional accuracy and name.
    /// - Parameters:
    ///   - coordinate: The geographic coordinate of the waypoint.
    ///   - coordinateAccuracy: The maximum distance away from the waypoint that the route may come and still be
    /// considered viable. This argument is measured in meters. A negative value means the route may be an indefinite
    /// number of meters away from the route and still be considered viable.
    ///    It is recommended that the value of this argument be greater than the `horizontalAccuracy` property of a
    /// `CLLocation` object obtained from a `CLLocationManager` object. There is a high likelihood that the user may be
    /// located some distance away from a navigable road, for instance if the user is currently on a driveway or inside
    /// a building.
    ///   - name: The name of the waypoint. This argument does not affect the route but may help you to distinguish one
    /// waypoint from another.
    public init(coordinate: LocationCoordinate2D, coordinateAccuracy: LocationAccuracy? = nil, name: String? = nil) {
        self.coordinate = coordinate
        self.coordinateAccuracy = coordinateAccuracy
        self.name = name
    }

#if canImport(CoreLocation)
#if os(tvOS) || os(watchOS)
    /// Initializes a new waypoint object with the given `CLLocation` object and an optional heading value and name.
    ///
    /// - Note: This initializer is intended for `CLLocation` objects created using the
    /// `CLLocation(latitude:longitude:)` initializer. If you intend to use a `CLLocation` object obtained from a
    /// `CLLocationManager` object, consider increasing the `horizontalAccuracy` or set it to a negative value to avoid
    /// overfitting, since the ``Waypoint`` class’s `coordinateAccuracy` property represents the maximum allowed
    /// deviation
    /// from the waypoint. There is a high likelihood that the user may be located some distance away from a navigable
    /// road, for instance if the user is currently on a driveway or inside a building.
    /// - Parameters:
    ///   - location: A `CLLocation` object representing the waypoint’s location. This initializer respects the
    /// `CLLocation` class’s `coordinate` and `horizontalAccuracy` properties, converting them into the `coordinate` and
    /// `coordinateAccuracy` properties, respectively.
    ///   - heading: A `LocationDirection` value representing the direction from which the route must approach the
    /// waypoint in order to be considered viable. This value is stored in the `headingAccuracy` property.
    ///   - name: The name of the waypoint. This argument does not affect the route but may help you to distinguish one
    /// waypoint from another.
    public init(location: CLLocation, heading: LocationDirection? = nil, name: String? = nil) {
        self.coordinate = location.coordinate
        self.coordinateAccuracy = location.horizontalAccuracy
        if let heading, heading >= 0 {
            self.heading = heading
        }
        self.name = name
    }
#else
    /// Initializes a new waypoint object with the given `CLLocation` object and an optional `CLHeading` object and
    /// name.
    ///
    /// - Note: This initializer is intended for `CLLocation` objects created using the
    /// `CLLocation(latitude:longitude:)` initializer. If you intend to use a `CLLocation` object obtained from a
    /// `CLLocationManager` object, consider increasing the `horizontalAccuracy` or set it to a negative value to avoid
    /// overfitting, since the ``Waypoint`` class’s ``Waypoint/coordinateAccuracy`` property represents the maximum
    /// allowed deviation from the waypoint. There is a high likelihood that the user may be located some distance away
    /// from a navigable road, for instance if the user is currently on a driveway of inside a building.
    /// - Parameters:
    ///   - location: A `CLLocation` object representing the waypoint’s location. This initializer respects the
    /// `CLLocation` class’s `coordinate` and `horizontalAccuracy` properties, converting them into the `coordinate` and
    /// `coordinateAccuracy` properties, respectively.
    ///   - heading: A `CLHeading` object representing the direction from which the route must approach the waypoint in
    /// order to be considered viable. This initializer respects the `CLHeading` class’s `trueHeading` property or
    /// `magneticHeading` property, converting it into the `headingAccuracy` property.
    ///   - name: The name of the waypoint. This argument does not affect the route but may help you to distinguish one
    /// waypoint from another.
    public init(location: CLLocation, heading: CLHeading? = nil, name: String? = nil) {
        self.coordinate = location.coordinate
        self.coordinateAccuracy = location.horizontalAccuracy
        if let heading {
            self.heading = heading.trueHeading >= 0 ? heading.trueHeading : heading.magneticHeading
        }
        self.name = name
    }
#endif
#endif

    // MARK: Positioning the Waypoint

    /// The geographic coordinate of the waypoint.
    public let coordinate: LocationCoordinate2D

    /// The radius of uncertainty for the waypoint, measured in meters.
    ///
    /// For a route to be considered viable, it must enter this waypoint’s circle of uncertainty. The ``coordinate``
    /// property identifies the center of the circle, while this property indicates the circle’s radius. If the value of
    /// this property is negative, a route is considered viable regardless of whether it enters this waypoint’s circle
    /// of uncertainty, subject to an undefined maximum distance.
    ///
    /// By default, the value of this property is `nil`.
    public var coordinateAccuracy: LocationAccuracy?

    /// The geographic coordinate of the waypoint’s target.
    ///
    /// The waypoint’s target affects arrival instructions without affecting the route’s shape. For example, a delivery
    /// or ride hailing application may specify a waypoint target that represents a drop-off location. The target
    /// determines whether the arrival visual and spoken instructions indicate that the destination is “on the left” or
    /// “on the right”.
    ///
    /// By default, this property is set to `nil`, meaning the waypoint has no target. This property is ignored on the
    /// first waypoint of a ``RouteOptions`` object, on any waypoint of a ``MatchOptions`` object, or on any waypoint of
    /// a ``RouteOptions`` object if ``DirectionsOptions/includesSteps`` is set to `false`.
    ///
    /// This property corresponds to the
    /// [`waypoint_targets`](https://docs.mapbox.com/api/navigation/#retrieve-directions) query parameter in the Mapbox
    /// Directions and Map Matching APIs.
    public var targetCoordinate: LocationCoordinate2D?

    /// A Boolean value indicating whether the waypoint may be snapped to a closed road in the resulting
    /// ``RouteResponse``.
    ///
    /// If `true`, the waypoint may be snapped to a road segment that is closed due to a live traffic closure. This
    /// property is `false` by default. This property corresponds to the [`snapping_include_closures`](https://docs.mapbox.com/api/navigation/directions/#optional-parameters-for-the-mapboxdriving-traffic-profile)
    /// query parameter in the Mapbox Directions API.
    public var allowsSnappingToClosedRoad: Bool = false

    /// A Boolean value indicating whether the waypoint may be snapped to a statically (long-term) closed road in the
    /// resulting ``RouteResponse``.
    ///
    /// If `true`, the waypoint may be snapped to a road segment statically closed, that is long-term (for example, road
    /// under construction). This property is `false` by default. This property corresponds to the [`snapping_include_static_closures`](https://docs.mapbox.com/api/navigation/directions/#optional-parameters-for-the-mapboxdriving-traffic-profile)
    /// query parameter in the Mapbox Directions API.
    public var allowsSnappingToStaticallyClosedRoad: Bool = false

    /// The straight-line distance from the coordinate specified in the query to the location it was snapped to in the
    /// resulting ``RouteResponse``.
    ///
    /// By default, this property is set to `nil`, meaning the waypoint has no snapped distance.
    public var snappedDistance: LocationDistance?

    /// The [layer](https://wiki.openstreetmap.org/wiki/Key:layer) of road that the waypoint is positioned which is used
    /// to filter the road segment that the waypoint will be placed on in Z-order. It is useful for avoiding ambiguity
    /// in the case of multi-level roads (such as a tunnel under a road).
    ///
    /// This property corresponds to the
    /// [`layers`](https://docs.mapbox.com/api/navigation/directions/#optional-parameters) query parameter in the Mapbox
    /// Directions API. If a matching layer is not found, the Mapbox Directions API will choose a suitable layer
    /// according to the other  provided ``DirectionsOptions`` and ``Waypoint`` properties.
    ///
    /// By default, this property is set to `nil`, meaning the route from the ``Waypoint`` will not be influenced by a
    /// layer of road.
    public var layer: Int?

    // MARK: Getting the Direction of Approach

    /// The direction from which a route must approach this waypoint in order to be considered viable.
    ///
    /// This property is measured in degrees clockwise from true north. A value of 0 degrees means due north, 90 degrees
    /// means due east, 180 degrees means due south, and so on. If the value of this property is negative, a route is
    /// considered viable regardless of the direction from which it approaches this waypoint.
    ///
    /// If this waypoint is the first waypoint (the source waypoint), the route must start out by heading in the
    /// direction specified by this property. You should always set the ``headingAccuracy`` property in conjunction with
    /// this property. If the ``headingAccuracy`` property is set to `nil`, this property is ignored.
    ///
    /// For driving directions, this property can be useful for avoiding a route that begins by going in the direction
    /// opposite the current direction of travel. For example, if you know the user is moving eastwardly and the first
    /// waypoint is the user’s current location, specifying a heading of 90 degrees and a heading accuracy of 90 degrees
    /// for the first waypoint avoids a route that begins with a “head west” instruction.
    ///
    /// You should be certain that the user is in motion before specifying a heading and heading accuracy; otherwise,
    /// you may be unnecessarily filtering out the best route. For example, suppose the user is sitting in a car parked
    /// in a driveway, facing due north, with the garage in front and the street to the rear. In that case, specifying a
    /// heading of 0 degrees and a heading accuracy of 90 degrees may result in a route that begins on the back alley
    /// or, worse, no route at all. For this reason, it is recommended that you only specify a heading and heading
    /// accuracy when automatically recalculating directions due to the user deviating from the route.
    ///
    /// By default, the value of this property is `nil`, meaning that a route is considered viable regardless of the
    /// direction of approach.
    public var heading: LocationDirection? = nil

    /// The maximum amount, in degrees, by which a route’s approach to a waypoint may differ from ``heading`` in either
    /// direction in order to be considered viable.
    ///
    /// A value of 0 degrees means that the approach must match the specified ``heading`` exactly – an unlikely
    /// scenario. A value of 180 degrees or more means that the approach may be as much as 180 degrees in either
    /// direction from the specified ``heading``, effectively allowing a candidate route to approach the waypoint from
    /// any direction.
    ///
    /// If you set the ``heading`` property, you should set this property to a value such as 90 degrees, to avoid
    /// filtering out routes whose approaches differ only slightly from the specified `heading`. Otherwise, if the
    /// ``heading`` property is set to a negative value, this property is ignored.
    ///
    /// By default, the value of this property is `nil`, meaning that a route is considered viable regardless of the
    /// direction of approach.
    public var headingAccuracy: LocationDirection? = nil

    var headingDescription: String {
        guard let heading, heading >= 0,
              let accuracy = headingAccuracy, accuracy >= 0
        else {
            return ""
        }

        return "\(heading.truncatingRemainder(dividingBy: 360)),\(min(accuracy, 180))"
    }

    /// A Boolean value indicating whether arriving on opposite side is allowed.
    ///
    /// This property has no effect if ``DirectionsOptions/includesSteps`` is set to `false`.
    /// This property corresponds to the
    /// [`approaches`](https://www.mapbox.com/api-documentation/navigation/#retrieve-directions) query parameter in the
    /// Mapbox Directions and Map Matching APIs.
    public var allowsArrivingOnOppositeSide = true

    // MARK: Identifying the Waypoint

    /// The name of the waypoint.
    ///
    /// This property does not affect the route, but the name is included in the arrival instruction, to help the user
    /// distinguish between multiple destinations. The name can also help you distinguish one waypoint from another in
    /// the array of waypoints passed into the completion handler of the `Directions.calculate(_:completionHandler:)`
    /// method.
    public var name: String?

    // MARK: Separating the Routes Into Legs

    /// A Boolean value indicating whether the waypoint is significant enough to appear in the resulting routes as a
    /// waypoint separating two legs, along with corresponding guidance instructions.
    ///
    /// By default, this property is set to `true`, which means that each resulting route will include a leg that ends
    /// by arriving at the waypoint as ``RouteLeg/destination`` and a subsequent leg that begins by departing from the
    /// waypoint as ``RouteLeg/source``. Otherwise, if this property is set to `false`, a single leg passes through the
    /// waypoint without specifically mentioning it. Regardless of the value of this property, each resulting route
    /// passes through the location specified by the ``coordinate`` property, accounting for approach-related properties
    /// such as ``heading``.
    ///
    /// With the Mapbox Directions API, set this property to `false` if you want the waypoint’s location to influence
    /// the path that the route follows without attaching any meaning to the waypoint object itself. With the Mapbox Map
    /// Matching API, use this property when the ``DirectionsOptions/includesSteps`` property is `true` or when
    /// ``coordinate`` represents a trace with a high sample rate.
    ///
    /// This property has no effect if ``DirectionsOptions/includesSteps`` is set to `false`, or if
    /// ``MatchOptions/waypointIndices`` is non-nil.
    /// This property corresponds to the [`approaches`](https://docs.mapbox.com/api/navigation/#retrieve-directions)
    /// query parameter in the Mapbox Directions and Map Matching APIs.
    public var separatesLegs: Bool = true
}

extension Waypoint: CustomStringConvertible {
    public var description: String {
        return Mirror(reflecting: self).children.compactMap {
            if let label = $0.label {
                return "\(label): \($0.value)"
            }

            return ""
        }.joined(separator: "\n")
    }
}

#if canImport(CoreLocation)
extension Waypoint: CustomQuickLookConvertible {
    func debugQuickLookObject() -> Any? {
        return CLLocation(
            coordinate: targetCoordinate ?? coordinate,
            altitude: 0,
            horizontalAccuracy: coordinateAccuracy ?? -1,
            verticalAccuracy: -1,
            course: heading ?? -1,
            speed: -1,
            timestamp: Date()
        )
    }
}
#endif
