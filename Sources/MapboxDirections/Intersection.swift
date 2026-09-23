import Foundation
import Turf
#if canImport(CoreLocation)
import CoreLocation
#endif

/// A single cross street along a step.
public struct Intersection: ForeignMemberContainer, Equatable, Sendable {
    public var foreignMembers: JSONObject = [:]
    public var lanesForeignMembers: [JSONObject] = []

    // MARK: Creating an Intersection

    /// Initializes an intersection.
    ///
    /// - Parameter laneValidIndications: For each item in `approachLanes`, the indication that is applicable to
    /// the current route, or `nil` for a lane that has no applicable indication.
    public init(
        location: LocationCoordinate2D,
        headings: [LocationDirection],
        approachIndex: Int,
        outletIndex: Int,
        outletIndexes: IndexSet,
        approachLanes: [LaneIndication]?,
        usableApproachLanes: IndexSet?,
        preferredApproachLanes: IndexSet?,
        laneValidIndications: [ManeuverDirection?]? = nil,
        outletRoadClasses: RoadClasses? = nil,
        tollCollection: TollCollection? = nil,
        tunnelName: String? = nil,
        restStop: RestStop? = nil,
        isUrban: Bool? = nil,
        regionCode: String? = nil,
        outletMapboxStreetsRoadClass: MapboxStreetsRoadClass? = nil,
        railroadCrossing: Bool? = nil,
        trafficSignal: Bool? = nil,
        stopSign: Bool? = nil,
        yieldSign: Bool? = nil,
        interchange: Interchange? = nil,
        junction: Junction? = nil
    ) {
        self.location = location
        self.headings = headings
        self.approachIndex = approachIndex
        self.approachLanes = approachLanes
        self.outletIndex = outletIndex
        self.outletIndexes = outletIndexes
        self.usableApproachLanes = usableApproachLanes
        self.preferredApproachLanes = preferredApproachLanes
        self.laneValidIndications = laneValidIndications
        self._usableLaneIndication = Intersection.collapsedLaneIndication(
            laneValidIndications: laneValidIndications,
            usableApproachLanes: usableApproachLanes,
            preferredApproachLanes: preferredApproachLanes
        )
        self.outletRoadClasses = outletRoadClasses
        self.tollCollection = tollCollection
        self.tunnelName = tunnelName
        self.isUrban = isUrban
        self.restStop = restStop
        self.regionCode = regionCode
        self.outletMapboxStreetsRoadClass = outletMapboxStreetsRoadClass
        self.railroadCrossing = railroadCrossing
        self.trafficSignal = trafficSignal
        self.stopSign = stopSign
        self.yieldSign = yieldSign
        self.interchange = interchange
        self.junction = junction
    }

    /// Initializes an intersection whose lanes all share a single applicable maneuver direction.
    ///
    /// Lanes at the same intersection may legitimately have differing applicable maneuver directions, which a
    /// single `usableLaneIndication` cannot represent. Use the initializer that takes `laneValidIndications`
    /// instead, passing one indication per lane.
    @available(
        *,
        deprecated,
        message: "Use the initializer that takes laneValidIndications, which reflects that lanes may have differing indications."
    )
    public init(
        location: LocationCoordinate2D,
        headings: [LocationDirection],
        approachIndex: Int,
        outletIndex: Int,
        outletIndexes: IndexSet,
        approachLanes: [LaneIndication]?,
        usableApproachLanes: IndexSet?,
        preferredApproachLanes: IndexSet?,
        usableLaneIndication: ManeuverDirection?,
        outletRoadClasses: RoadClasses? = nil,
        tollCollection: TollCollection? = nil,
        tunnelName: String? = nil,
        restStop: RestStop? = nil,
        isUrban: Bool? = nil,
        regionCode: String? = nil,
        outletMapboxStreetsRoadClass: MapboxStreetsRoadClass? = nil,
        railroadCrossing: Bool? = nil,
        trafficSignal: Bool? = nil,
        stopSign: Bool? = nil,
        yieldSign: Bool? = nil,
        interchange: Interchange? = nil,
        junction: Junction? = nil
    ) {
        self.location = location
        self.headings = headings
        self.approachIndex = approachIndex
        self.approachLanes = approachLanes
        self.outletIndex = outletIndex
        self.outletIndexes = outletIndexes
        self.usableApproachLanes = usableApproachLanes
        self.preferredApproachLanes = preferredApproachLanes
        self.laneValidIndications = nil
        self._usableLaneIndication = usableLaneIndication
        self.outletRoadClasses = outletRoadClasses
        self.tollCollection = tollCollection
        self.tunnelName = tunnelName
        self.isUrban = isUrban
        self.restStop = restStop
        self.regionCode = regionCode
        self.outletMapboxStreetsRoadClass = outletMapboxStreetsRoadClass
        self.railroadCrossing = railroadCrossing
        self.trafficSignal = trafficSignal
        self.stopSign = stopSign
        self.yieldSign = yieldSign
        self.interchange = interchange
        self.junction = junction
    }

    /// Collapses per-lane applicable maneuver directions into the single value published by the deprecated
    /// ``usableLaneIndication`` property.
    ///
    /// The indication of the first preferred lane that has one is preferred, then the indication of the first
    /// usable lane that has one, then the indication of the first lane.
    static func collapsedLaneIndication(
        laneValidIndications: [ManeuverDirection?]?,
        usableApproachLanes: IndexSet?,
        preferredApproachLanes: IndexSet?
    ) -> ManeuverDirection? {
        guard let laneValidIndications else { return nil }

        func firstIndication(among laneIndices: IndexSet?) -> ManeuverDirection? {
            guard let laneIndices else { return nil }
            return laneIndices.lazy
                .compactMap { laneValidIndications.indices.contains($0) ? laneValidIndications[$0] : nil }
                .first
        }

        return firstIndication(among: preferredApproachLanes)
            ?? firstIndication(among: usableApproachLanes)
            ?? laneValidIndications.first.flatMap { $0 }
    }

    // MARK: Getting the Location of the Intersection

    /// The geographic coordinates at the center of the intersection.
    public let location: LocationCoordinate2D

    // MARK: Getting the Roads that Meet at the Intersection

    /// An array of `LocationDirection`s indicating the absolute headings of the roads that meet at the intersection.
    ///
    /// A road is represented in this array by a heading indicating the direction from which the road meets the
    /// intersection. To get the direction of travel when leaving the intersection along the road, rotate the heading
    /// 180 degrees.
    ///
    /// A single road that passes through this intersection is represented by two items in this array: one for the
    /// segment that enters the intersection and one for the segment that exits it.
    /// - Note: These values will be rounded to an integer during encoding.
    public let headings: [LocationDirection]

    /// The indices of the items in the ``headings`` array that correspond to the roads that may be used to leave the
    /// intersection.
    ///
    /// This index set effectively excludes any one-way road that leads toward the intersection.
    public let outletIndexes: IndexSet

    // MARK: Getting the Roads That Take the Route Through the Intersection

    /// The index of the item in the ``headings`` array that corresponds to the road that the containing route step uses
    /// to approach the intersection.
    ///
    /// This property is set to `nil` for a departure maneuver.
    public let approachIndex: Int?

    /// The index of the item in the ``headings`` array that corresponds to the road that the containing route step uses
    /// to leave the intersection.
    ///
    /// This property is set to `nil` for an arrival maneuver.
    public let outletIndex: Int?

    /// The road classes of the road that the containing step uses to leave the intersection.
    ///
    /// If road class information is unavailable, this property is set to `nil`.
    public let outletRoadClasses: RoadClasses?

    /// The road classes of the road that the containing step uses to leave the intersection, according to the [Mapbox
    /// Streets source](https://docs.mapbox.com/vector-tiles/reference/mapbox-streets-v8/#road) , version 8.
    ///
    /// If detailed road class information is unavailable, this property is set to `nil`. This property only indicates
    /// the road classification; for other aspects of the road, use the ``outletRoadClasses`` property.
    public let outletMapboxStreetsRoadClass: MapboxStreetsRoadClass?

    /// The name of the tunnel that this intersection is a part of.
    ///
    /// If this Intersection is not a tunnel entrance or exit, or if information is unavailable then this property is
    /// set to `nil`.
    public let tunnelName: String?

    /// A toll collection point.
    ///
    /// If this Intersection is not a toll collection intersection, or if this information is unavailable then this
    /// property is set to `nil`.
    public let tollCollection: TollCollection?

    /// Corresponding rest stop.
    ///
    /// If this Intersection is not a rest stop, or if this information is unavailable then this property is set to
    /// `nil`.
    public let restStop: RestStop?

    /// Whether the intersection lays within the bounds of an urban zone.
    ///
    /// If this information is unavailable, then this property is set to `nil`.
    public let isUrban: Bool?

    /// A 2-letter region code to identify corresponding country that this intersection lies in.
    ///
    /// Automatically populated during decoding a ``RouteLeg`` object, since this is the source of all
    /// ``AdministrativeRegion``s. Value is `nil` if such information is unavailable.
    ///
    /// - SeeAlso: ``RouteLeg/regionCode(atStepIndex:intersectionIndex:)``
    public private(set) var regionCode: String?

    mutating func updateRegionCode(_ regionCode: String?) {
        self.regionCode = regionCode
    }

    // MARK: Telling the User Which Lanes to Use

    /// All the lanes of the road that the containing route step uses to approach the intersection. Each item in the
    /// array represents a lane, which is represented by one or more ``LaneIndication``s.
    ///
    /// If no lane information is available for the intersection, this property’s value is `nil`. The first item
    /// corresponds to the leftmost lane, the second item corresponds to the second lane from the left, and so on,
    /// regardless of whether the surrounding country drives on the left or on the right.
    public let approachLanes: [LaneIndication]?

    /// The indices of the items in the ``approachLanes`` array that correspond to the lanes that may be used to execute
    /// the maneuver.
    ///
    /// If no lane information is available for an intersection, this property’s value is `nil`.
    public let usableApproachLanes: IndexSet?

    /// The indices of the items in the ``approachLanes`` array that correspond to the lanes that are preferred to
    /// execute
    /// the maneuver.
    ///
    /// If no lane information is available for an intersection, this property’s value is `nil`.
    public let preferredApproachLanes: IndexSet?

    /// For each item in the ``approachLanes`` array, which of its ``LaneIndication``s is applicable to the
    /// current route, when there is more than one.
    ///
    /// A lane's entry is `nil` if the lane has no applicable indication. Lanes at the same intersection may have
    /// differing entries — for example, one lane may indicate a straight maneuver while an adjacent lane
    /// indicates a slight turn, if both lanes can be used for the route.
    ///
    /// If no lane information is available for the intersection, this property’s value is `nil`.
    public let laneValidIndications: [ManeuverDirection?]?

    /// Which of the ``LaneIndication``s is applicable to the current route when there is more than one.
    ///
    /// If no lane information is available for the intersection, this property’s value is `nil`.
    ///
    /// - Note: Lanes at the same intersection may legitimately have differing indications, in which case this
    /// property collapses them to a single value (preferring a preferred lane's indication, then a usable
    /// lane's, then the first lane's) and therefore does not represent every lane. Use
    /// ``laneValidIndications`` instead.
    @available(
        *,
        deprecated,
        message: "Use laneValidIndications, which reflects that lanes may have differing indications."
    )
    public var usableLaneIndication: ManeuverDirection? {
        _usableLaneIndication
    }

    let _usableLaneIndication: ManeuverDirection?

    /// Indicates whether there is a railroad crossing at the intersection.
    ///
    /// If such information is not available for an intersection, this property’s value is `nil`.
    public let railroadCrossing: Bool?

    /// Indicates whether there is a traffic signal at the intersection.
    ///
    /// If such information is not available for an intersection, this property’s value is `nil`.
    public let trafficSignal: Bool?

    /// Indicates whether there is a stop sign at the intersection.
    ///
    /// If such information is not available for an intersection, this property’s value is `nil`.
    public let stopSign: Bool?

    /// Indicates whether there is a yield sign at the intersection.

    /// If such information is not available for an intersection, this property’s value is `nil`.
    public let yieldSign: Bool?

    /// An object containing information about routing and passing interchange along the route.
    /// If such information is not available for an intersection, this property’s value is `nil`.
    public let interchange: Interchange?

    /// An object containing information about routing and passing junction along the route.
    /// If such information is not available for an intersection, this property’s value is `nil`.
    public let junction: Junction?
}

extension Intersection: Codable {
    private enum CodingKeys: String, CodingKey {
        case outletIndexes = "entry"
        case headings = "bearings"
        case location
        case approachIndex = "in"
        case outletIndex = "out"
        case lanes
        case outletRoadClasses = "classes"
        case tollCollection = "toll_collection"
        case tunnelName
        case mapboxStreets = "mapbox_streets_v8"
        case isUrban = "is_urban"
        case restStop = "rest_stop"
        case administrativeRegionIndex = "admin_index"
        case geometryIndex = "geometry_index"
        case railroadCrossing = "railway_crossing"
        case trafficSignal = "traffic_signal"
        case stopSign = "stop_sign"
        case yieldSign = "yield_sign"
        case interchange = "ic"
        case junction = "jct"
    }

    /// Used to code `Intersection.outletMapboxStreetsRoadClass`
    private struct MapboxStreetClassCodable: Codable, ForeignMemberContainer {
        var foreignMembers: JSONObject = [:]

        private enum CodingKeys: String, CodingKey {
            case streetClass = "class"
        }

        let streetClass: MapboxStreetsRoadClass?

        init(streetClass: MapboxStreetsRoadClass?) {
            self.streetClass = streetClass
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            if let classString = try container.decodeIfPresent(String.self, forKey: .streetClass) {
                self.streetClass = MapboxStreetsRoadClass(rawValue: classString)
            } else {
                self.streetClass = nil
            }

            try decodeForeignMembers(notKeyedBy: CodingKeys.self, with: decoder)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(streetClass, forKey: .streetClass)

            try encodeForeignMembers(notKeyedBy: CodingKeys.self, to: encoder)
        }
    }

    static func encode(
        intersections: [Intersection],
        to parentContainer: inout UnkeyedEncodingContainer,
        administrativeRegionIndices: [Int?]?,
        segmentIndicesByIntersection: [Int?]?
    ) throws {
        guard administrativeRegionIndices == nil || administrativeRegionIndices?.count == intersections.count else {
            let error = EncodingError.Context(
                codingPath: parentContainer.codingPath,
                debugDescription: "`administrativeRegionIndices` should be `nil` or match provided `intersections` to encode"
            )
            throw EncodingError.invalidValue(administrativeRegionIndices as Any, error)
        }
        guard segmentIndicesByIntersection == nil || segmentIndicesByIntersection?.count == intersections.count else {
            let error = EncodingError.Context(
                codingPath: parentContainer.codingPath,
                debugDescription: "`segmentIndicesByIntersection` should be `nil` or match provided `intersections` to encode"
            )
            throw EncodingError.invalidValue(segmentIndicesByIntersection as Any, error)
        }

        for (index, intersection) in intersections.enumerated() {
            var adminIndex: Int?
            var geometryIndex: Int?
            if index < administrativeRegionIndices?.count ?? -1 {
                adminIndex = administrativeRegionIndices?[index]
                geometryIndex = segmentIndicesByIntersection?[index]
            }

            try intersection.encode(
                to: parentContainer.superEncoder(),
                administrativeRegionIndex: adminIndex,
                geometryIndex: geometryIndex
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        try encode(to: encoder, administrativeRegionIndex: nil, geometryIndex: nil)
    }

    func encode(to encoder: Encoder, administrativeRegionIndex: Int?, geometryIndex: Int?) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(LocationCoordinate2DCodable(location), forKey: .location)
        try container.encode(headings.map { Int($0.rounded()) }, forKey: .headings)

        try container.encodeIfPresent(approachIndex, forKey: .approachIndex)
        try container.encodeIfPresent(outletIndex, forKey: .outletIndex)

        var outletArray = headings.map { _ in false }
        for index in outletIndexes {
            outletArray[index] = true
        }

        try container.encode(outletArray, forKey: .outletIndexes)

        var lanes: [Lane]?
        if let approachLanes,
           let usableApproachLanes,
           let preferredApproachLanes
        {
            var encodedLanes = approachLanes.map { Lane(indications: $0) }
            for i in usableApproachLanes {
                encodedLanes[i].isValid = true
                if usableApproachLanes.count == lanesForeignMembers.count {
                    encodedLanes[i].foreignMembers = lanesForeignMembers[i]
                }
            }

            for j in preferredApproachLanes {
                encodedLanes[j].isActive = true
            }

            if let laneValidIndications {
                for (i, laneValidIndication) in zip(encodedLanes.indices, laneValidIndications) {
                    encodedLanes[i].validIndication = laneValidIndication
                }
            } else if let _usableLaneIndication {
                // Back-compat for `Intersection`s constructed without `laneValidIndications`: broadcast the
                // single value to every usable lane whose indications include it.
                for i in usableApproachLanes
                    where encodedLanes[i].indications.descriptions.contains(_usableLaneIndication.rawValue)
                {
                    encodedLanes[i].validIndication = _usableLaneIndication
                }
            }
            lanes = encodedLanes
        }
        try container.encodeIfPresent(lanes, forKey: .lanes)

        if let classes = outletRoadClasses?.description.components(separatedBy: ",").filter({ !$0.isEmpty }) {
            try container.encode(classes, forKey: .outletRoadClasses)
        }

        if let tolls = tollCollection {
            try container.encode(tolls, forKey: .tollCollection)
        }

        if let outletMapboxStreetsRoadClass {
            try container.encode(
                MapboxStreetClassCodable(streetClass: outletMapboxStreetsRoadClass),
                forKey: .mapboxStreets
            )
        }

        if let isUrban {
            try container.encode(isUrban, forKey: .isUrban)
        }

        if let restStop {
            try container.encode(restStop, forKey: .restStop)
        }

        if let tunnelName {
            try container.encode(tunnelName, forKey: .tunnelName)
        }

        if let adminIndex = administrativeRegionIndex {
            try container.encode(adminIndex, forKey: .administrativeRegionIndex)
        }

        if let geoIndex = geometryIndex {
            try container.encode(geoIndex, forKey: .geometryIndex)
        }

        if let railwayCrossing = railroadCrossing {
            try container.encode(railwayCrossing, forKey: .railroadCrossing)
        }

        if let trafficSignal {
            try container.encode(trafficSignal, forKey: .trafficSignal)
        }

        if let stopSign {
            try container.encode(stopSign, forKey: .stopSign)
        }

        if let yieldSign {
            try container.encode(yieldSign, forKey: .yieldSign)
        }

        try container.encodeIfPresent(interchange, forKey: .interchange)
        try container.encodeIfPresent(junction, forKey: .junction)

        try encodeForeignMembers(notKeyedBy: CodingKeys.self, to: encoder)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.location = try container.decode(LocationCoordinate2DCodable.self, forKey: .location).decoded
        self.headings = try container.decode([LocationDirection].self, forKey: .headings)

        if let lanes = try container.decodeIfPresent([Lane].self, forKey: .lanes) {
            self.lanesForeignMembers = lanes.map(\.foreignMembers)
            // Lanes at the same intersection may legitimately have differing indications (e.g. one lane
            // "straight", another "slight right"), so every lane keeps its own indication.
            let laneValidIndications = lanes.map(\.validIndication)
            let usableApproachLanes = lanes.indices { $0.isValid }
            let preferredApproachLanes = lanes.indices { $0.isActive ?? false }
            self.approachLanes = lanes.map(\.indications)
            self.usableApproachLanes = usableApproachLanes
            self.preferredApproachLanes = preferredApproachLanes
            self.laneValidIndications = laneValidIndications
            self._usableLaneIndication = Intersection.collapsedLaneIndication(
                laneValidIndications: laneValidIndications,
                usableApproachLanes: usableApproachLanes,
                preferredApproachLanes: preferredApproachLanes
            )
        } else {
            self.approachLanes = nil
            self.usableApproachLanes = nil
            self.preferredApproachLanes = nil
            self.laneValidIndications = nil
            self._usableLaneIndication = nil
        }

        self.outletRoadClasses = try container.decodeIfPresent(RoadClasses.self, forKey: .outletRoadClasses)

        let outletsArray = try container.decode([Bool].self, forKey: .outletIndexes)
        self.outletIndexes = outletsArray.indices { $0 }

        self.outletIndex = try container.decodeIfPresent(Int.self, forKey: .outletIndex)
        self.approachIndex = try container.decodeIfPresent(Int.self, forKey: .approachIndex)

        self.tollCollection = try container.decodeIfPresent(TollCollection.self, forKey: .tollCollection)

        self.tunnelName = try container.decodeIfPresent(String.self, forKey: .tunnelName)

        self.outletMapboxStreetsRoadClass = try container.decodeIfPresent(
            MapboxStreetClassCodable.self,
            forKey: .mapboxStreets
        )?.streetClass

        self.isUrban = try container.decodeIfPresent(Bool.self, forKey: .isUrban)

        self.restStop = try container.decodeIfPresent(RestStop.self, forKey: .restStop)

        self.railroadCrossing = try container.decodeIfPresent(Bool.self, forKey: .railroadCrossing)
        self.trafficSignal = try container.decodeIfPresent(Bool.self, forKey: .trafficSignal)
        self.stopSign = try container.decodeIfPresent(Bool.self, forKey: .stopSign)
        self.yieldSign = try container.decodeIfPresent(Bool.self, forKey: .yieldSign)

        self.interchange = try container.decodeIfPresent(Interchange.self, forKey: .interchange)
        self.junction = try container.decodeIfPresent(Junction.self, forKey: .junction)

        try decodeForeignMembers(notKeyedBy: CodingKeys.self, with: decoder)
    }
}

extension Intersection {
    public static func == (lhs: Intersection, rhs: Intersection) -> Bool {
        return lhs.location == rhs.location &&
            lhs.headings == rhs.headings &&
            lhs.outletIndexes == rhs.outletIndexes &&
            lhs.approachIndex == rhs.approachIndex &&
            lhs.outletIndex == rhs.outletIndex &&
            lhs.approachLanes == rhs.approachLanes &&
            lhs.usableApproachLanes == rhs.usableApproachLanes &&
            lhs.preferredApproachLanes == rhs.preferredApproachLanes &&
            lhs.laneValidIndications == rhs.laneValidIndications &&
            lhs._usableLaneIndication == rhs._usableLaneIndication &&
            lhs.restStop == rhs.restStop &&
            lhs.regionCode == rhs.regionCode &&
            lhs.outletMapboxStreetsRoadClass == rhs.outletMapboxStreetsRoadClass &&
            lhs.outletRoadClasses == rhs.outletRoadClasses &&
            lhs.tollCollection == rhs.tollCollection &&
            lhs.tunnelName == rhs.tunnelName &&
            lhs.isUrban == rhs.isUrban &&
            lhs.railroadCrossing == rhs.railroadCrossing &&
            lhs.trafficSignal == rhs.trafficSignal &&
            lhs.stopSign == rhs.stopSign &&
            lhs.yieldSign == rhs.yieldSign &&
            lhs.interchange == rhs.interchange &&
            lhs.junction == rhs.junction
    }
}
