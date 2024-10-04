import Foundation
import Turf
#if canImport(CoreLocation)
import CoreLocation
#endif

/// A ``TransportType`` specifies the mode of transportation used for part of a route.
public enum TransportType: String, Codable, Equatable, Sendable {
    /// Possible transport types when the `profileIdentifier` is ``ProfileIdentifier/automobile`` or
    /// ``ProfileIdentifier/automobileAvoidingTraffic``

    /// The route requires the user to drive or ride a car, truck, or motorcycle.
    /// This is the usual transport type when the `profileIdentifier` is ``ProfileIdentifier/automobile`` or
    /// ``ProfileIdentifier/automobileAvoidingTraffic``.
    case automobile = "driving" // automobile

    /// The route requires the user to board a ferry.
    ///
    /// The user should verify that the ferry is in operation. For driving and cycling directions, the user should also
    /// verify that their vehicle is permitted onboard the ferry.
    case ferry // automobile, walking, cycling

    /// The route requires the user to cross a movable bridge.
    ///
    /// The user may need to wait for the movable bridge to become passable before continuing.
    case movableBridge = "movable bridge" // automobile, cycling

    /// The route becomes impassable at this point.
    ///
    /// You should not encounter this transport type under normal circumstances.
    case inaccessible = "unaccessible" // automobile, walking, cycling

    /// Possible transport types when the `profileIdentifier` is ``ProfileIdentifier/walking``

    /// The route requires the user to walk.
    ///
    /// This is the usual transport type when the `profileIdentifier` is ``ProfileIdentifier/walking``. For cycling
    /// directions, this value indicates that the user is expected to dismount.
    case walking // walking, cycling

    /// Possible transport types when the `profileIdentifier` is ``ProfileIdentifier/cycling``

    /// The route requires the user to ride a bicycle.
    ///
    /// This is the usual transport type when the `profileIdentifier` is ``ProfileIdentifier/cycling``.
    case cycling // cycling

    /// The route requires the user to board a train.
    ///
    /// The user should consult the train’s timetable. For cycling directions, the user should also verify that bicycles
    /// are permitted onboard the train.
    case train // cycling

    /// Custom implementation of decoding is needed to circumvent issue reported in
    /// https://github.com/mapbox/mapbox-directions-swift/issues/413
    public init(from decoder: Decoder) throws {
        let valueContainer = try decoder.singleValueContainer()
        let rawValue = try valueContainer.decode(String.self)

        if rawValue == "pushing bike" {
            self = .walking

            return
        }

        guard let value = TransportType(rawValue: rawValue) else {
            throw DecodingError.dataCorruptedError(
                in: valueContainer,
                debugDescription: "Cannot initialize TransportType from invalid String value \(rawValue)"
            )
        }

        self = value
    }
}

/// A ``ManeuverType`` specifies the type of maneuver required to complete the route step. You can pair a maneuver type
/// with a ``ManeuverDirection`` to choose an appropriate visual or voice prompt to present the user.
///
/// To avoid a complex series of if-else-if statements or switch statements, use pattern matching with a single switch
/// statement on a tuple that consists of the maneuver type and maneuver direction.
public enum ManeuverType: String, Codable, Equatable, Sendable {
    /// The step requires the user to depart from a waypoint.
    ///
    /// If the waypoint is some distance away from the nearest road, the maneuver direction indicates the direction the
    /// user must turn upon reaching the road.
    case depart

    /// The step requires the user to turn.
    ///
    /// The maneuver direction indicates the direction in which the user must turn relative to the current direction of
    /// travel. The exit index indicates the number of intersections, large or small, from the previous maneuver up to
    /// and including the intersection at which the user must turn.
    case turn

    /// The step requires the user to continue after a turn.
    case `continue`

    /// The step requires the user to continue on the current road as it changes names.
    ///
    /// The step’s name contains the road’s new name. To get the road’s old name, use the previous step’s name.
    case passNameChange = "new name"

    /// The step requires the user to merge onto another road.
    ///
    /// The maneuver direction indicates the side from which the other road approaches the intersection relative to the
    /// user.
    case merge

    /// The step requires the user to take a entrance ramp (slip road) onto a highway.
    case takeOnRamp = "on ramp"

    /// The step requires the user to take an exit ramp (slip road) off a highway.
    ///
    /// The maneuver direction indicates the side of the highway from which the user must exit. The exit index indicates
    /// the number of highway exits from the previous maneuver up to and including the exit that the user must take.
    case takeOffRamp = "off ramp"

    /// The step requires the user to choose a fork at a Y-shaped fork in the road.
    ///
    /// The maneuver direction indicates which fork to take.
    case reachFork = "fork"

    /// The step requires the user to turn at either a T-shaped three-way intersection or a sharp bend in the road where
    /// the road also changes names.
    ///
    /// This maneuver type is called out separately so that the user may be able to proceed more confidently, without
    /// fear of having overshot the turn. If this distinction is unimportant to you, you may treat the maneuver as an
    /// ordinary ``ManeuverType/turn``.
    case reachEnd = "end of road"

    /// The step requires the user to get into a specific lane in order to continue along the current road.
    ///
    /// The maneuver direction is set to ``ManeuverDirection/straightAhead``. Each of the first intersection’s usable
    /// approach lanes also has an indication of ``LaneIndication/straightAhead``. A maneuver in a different direction
    /// would instead have a maneuver type of ``ManeuverType/turn``.
    ///
    /// This maneuver type is called out separately so that the application can present the user with lane guidance
    /// based on the first element in the ``RouteStep/intersections`` property. If lane guidance is unimportant to you,
    /// you may
    /// treat the maneuver as an ordinary ``ManeuverType/continue`` or ignore it.
    case useLane = "use lane"

    /// The step requires the user to enter and traverse a roundabout (traffic circle or rotary).
    ///
    /// The step has no name, but the exit name is the name of the road to take to exit the roundabout. The exit index
    /// indicates the number of roundabout exits up to and including the exit to take.
    ///
    /// If ``RouteOptions/includesExitRoundaboutManeuver`` is set to `true`, this step is followed by an
    /// ``ManeuverType/exitRoundabout`` maneuver. Otherwise, this step represents the entire roundabout maneuver, from
    /// the entrance to the exit.
    case takeRoundabout = "roundabout"

    /// The step requires the user to enter and traverse a large, named roundabout (traffic circle or rotary).
    ///
    /// The step’s name is the name of the roundabout. The exit name is the name of the road to take to exit the
    /// roundabout. The exit index indicates the number of rotary exits up to and including the exit that the user must
    /// take.
    ///
    /// If ``RouteOptions/includesExitRoundaboutManeuver`` is set to `true`, this step is followed by an
    /// ``ManeuverType/exitRotary`` maneuver. Otherwise, this step represents the entire roundabout maneuver, from the
    /// entrance to the exit.
    case takeRotary = "rotary"

    /// The step requires the user to enter and exit a roundabout (traffic circle or rotary) that is compact enough to
    /// constitute a single intersection.
    ///
    /// The step’s name is the name of the road to take after exiting the roundabout. This maneuver type is called out
    /// separately because the user may perceive the roundabout as an ordinary intersection with an island in the
    /// middle. If this distinction is unimportant to you, you may treat the maneuver as either an ordinary
    /// ``ManeuverType/turn`` or as a ``ManeuverType/takeRoundabout``.
    case turnAtRoundabout = "roundabout turn"

    /// The step requires the user to exit a roundabout (traffic circle or rotary).
    ///
    /// This maneuver type follows a ``ManeuverType/takeRoundabout`` maneuver. It is only used when
    /// ``RouteOptions/includesExitRoundaboutManeuver`` is set to true.
    case exitRoundabout = "exit roundabout"

    /// The step requires the user to exit a large, named roundabout (traffic circle or rotary).
    ///
    /// This maneuver type follows a ``ManeuverType/takeRotary`` maneuver. It is only used when
    /// ``RouteOptions/includesExitRoundaboutManeuver`` is set to true.
    case exitRotary = "exit rotary"

    /// The step requires the user to respond to a change in travel conditions.
    ///
    /// This maneuver type may occur for example when driving directions require the user to board a ferry, or when
    /// cycling directions require the user to dismount. The step’s transport type and instructions contains important
    /// contextual details that should be presented to the user at the maneuver location.
    ///
    /// Similar changes can occur simultaneously with other maneuvers, such as when the road changes its name at the
    /// site of a movable bridge. In such cases, ``heedWarning`` is suppressed in favor of another maneuver type.
    case heedWarning = "notification"

    /// The step requires the user to arrive at a waypoint.
    ///
    /// The distance and expected travel time for this step are set to zero, indicating that the route or route leg is
    /// complete. The maneuver direction indicates the side of the road on which the waypoint can be found (or whether
    /// it is straight ahead).
    case arrive

    // Unrecognized maneuver types are interpreted as turns.
    // http://project-osrm.org/docs/v5.5.1/api/#stepmaneuver-object
    static let `default` = ManeuverType.turn
}

/// A ``ManeuverDirection`` clarifies a ``ManeuverType`` with directional information. The exact meaning of the maneuver
/// direction for a given step depends on the step’s maneuver type; see the ``ManeuverType`` documentation for details.
public enum ManeuverDirection: String, Codable, Equatable, Sendable {
    /// The maneuver requires a sharp turn to the right.
    case sharpRight = "sharp right"

    /// The maneuver requires a turn to the right, a merge to the right, or an exit on the right, or the destination is
    /// on the right.
    case right

    /// The maneuver requires a slight turn to the right.
    case slightRight = "slight right"

    /// The maneuver requires no notable change in direction, or the destination is straight ahead.
    case straightAhead = "straight"

    /// The maneuver requires a slight turn to the left.
    case slightLeft = "slight left"

    /// The maneuver requires a turn to the left, a merge to the left, or an exit on the left, or the destination is on
    /// the right.
    case left

    /// The maneuver requires a sharp turn to the left.
    case sharpLeft = "sharp left"

    /// The maneuver requires a U-turn when possible.
    ///
    /// Use the difference between the step’s initial and final headings to distinguish between a U-turn to the left
    /// (typical in countries that drive on the right) and a U-turn on the right (typical in countries that drive on the
    /// left). If the difference in headings is greater than 180 degrees, the maneuver requires a U-turn to the left. If
    /// the difference in headings is less than 180 degrees, the maneuver requires a U-turn to the right.
    case uTurn = "uturn"

    case undefined

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let rawValue = try? container.decode(String.self) {
            self = ManeuverDirection(rawValue: rawValue) ?? .undefined
        } else {
            self = .undefined
        }
    }
}

/// A road sign design standard.
///
/// A sign standard can affect how a user interface should display information related to the road. For example, a speed
/// limit from the ``RouteLeg/segmentMaximumSpeedLimits`` property may appear in a different-looking view depending on
/// the ``RouteStep/speedLimitSign` property.
public enum SignStandard: String, Codable, Equatable, Sendable {
    /// The [Manual on Uniform Traffic Control
    /// Devices](https://en.wikipedia.org/wiki/Manual_on_Uniform_Traffic_Control_Devices).
    ///
    /// This standard has been adopted by the United States and Canada, and several other countries have adopted parts
    /// of the standard as well.
    case mutcd

    /// The [Vienna Convention on Road Signs and
    /// Signals](https://en.wikipedia.org/wiki/Vienna_Convention_on_Road_Signs_and_Signals).
    ///
    /// This standard is prevalent in Europe and parts of Asia and Latin America. Countries in southern Africa and
    /// Central America have adopted similar regional standards.
    case viennaConvention = "vienna"
}

extension String {
    func tagValues(separatedBy separator: String) -> [String] {
        return components(separatedBy: separator).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
}

extension [String] {
    func tagValues(joinedBy separator: String) -> String {
        return joined(separator: "\(separator) ")
    }
}

/// Encapsulates all the information about a road.
struct Road: Equatable, Sendable {
    let names: [String]?
    let codes: [String]?
    let exitCodes: [String]?
    let destinations: [String]?
    let destinationCodes: [String]?
    let rotaryNames: [String]?

    init(
        names: [String]?,
        codes: [String]?,
        exitCodes: [String]?,
        destinations: [String]?,
        destinationCodes: [String]?,
        rotaryNames: [String]?
    ) {
        self.names = names
        self.codes = codes
        self.exitCodes = exitCodes
        self.destinations = destinations
        self.destinationCodes = destinationCodes
        self.rotaryNames = rotaryNames
    }

    init(name: String, ref: String?, exits: String?, destination: String?, rotaryName: String?) {
        if !name.isEmpty, let ref {
            // Directions API v5 profiles powered by Valhalla no longer include the ref in the name. However, the
            // `mapbox/cycling` profile, which is powered by OSRM, still includes the ref.
            let parenthetical = "(\(ref))"
            if name == ref {
                self.names = nil
            } else {
                self.names = name.replacingOccurrences(of: parenthetical, with: "").tagValues(separatedBy: ";")
            }
        } else {
            self.names = name.isEmpty ? nil : name.tagValues(separatedBy: ";")
        }

        // Mapbox Directions API v5 combines the destination’s ref and name.
        if let destination, destination.contains(": ") {
            let destinationComponents = destination.components(separatedBy: ": ")
            self.destinationCodes = destinationComponents.first?.tagValues(separatedBy: ",")
            self.destinations = destinationComponents.dropFirst().joined(separator: ": ").tagValues(separatedBy: ",")
        } else {
            self.destinationCodes = nil
            self.destinations = destination?.tagValues(separatedBy: ",")
        }

        self.exitCodes = exits?.tagValues(separatedBy: ";")
        self.codes = ref?.tagValues(separatedBy: ";")
        self.rotaryNames = rotaryName?.tagValues(separatedBy: ";")
    }
}

extension Road: Codable {
    enum CodingKeys: String, CodingKey, CaseIterable {
        case name
        case ref
        case exits
        case destinations
        case rotaryName = "rotary_name"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Decoder apparently treats an empty string as a null value.
        let name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        let ref = try container.decodeIfPresent(String.self, forKey: .ref)
        let exits = try container.decodeIfPresent(String.self, forKey: .exits)
        let destinations = try container.decodeIfPresent(String.self, forKey: .destinations)
        let rotaryName = try container.decodeIfPresent(String.self, forKey: .rotaryName)
        self.init(name: name, ref: ref, exits: exits, destination: destinations, rotaryName: rotaryName)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        let ref = codes?.tagValues(joinedBy: ";")
        if var name = names?.tagValues(joinedBy: ";") {
            if let ref {
                name = "\(name) (\(ref))"
            }
            try container.encodeIfPresent(name, forKey: .name)
        } else {
            try container.encode(ref ?? "", forKey: .name)
        }

        if var destinations = destinations?.tagValues(joinedBy: ",") {
            if let destinationCodes = destinationCodes?.tagValues(joinedBy: ",") {
                destinations = "\(destinationCodes): \(destinations)"
            }
            try container.encode(destinations, forKey: .destinations)
        }

        try container.encodeIfPresent(exitCodes?.tagValues(joinedBy: ";"), forKey: .exits)
        try container.encodeIfPresent(ref, forKey: .ref)
        try container.encodeIfPresent(rotaryNames?.tagValues(joinedBy: ";"), forKey: .rotaryName)
    }
}

/// A ``RouteStep`` object represents a single distinct maneuver along a route and the approach to the next maneuver.
/// The route step object corresponds to a single instruction the user must follow to complete a portion of the route.
/// For example, a step might require the user to turn then follow a road.
///
/// You do not create instances of this class directly. Instead, you receive route step objects as part of route objects
/// when you request directions using the `Directions.calculate(_:completionHandler:)` method, setting the
/// ``DirectionsOptions/includesSteps`` option to `true` in the ``RouteOptions`` object that you pass into that method.
public struct RouteStep: Codable, ForeignMemberContainer, Equatable, Sendable {
    public var foreignMembers: JSONObject = [:]
    public var maneuverForeignMembers: JSONObject = [:]

    private enum CodingKeys: String, CodingKey, CaseIterable {
        case shape = "geometry"
        case distance
        case drivingSide = "driving_side"
        case expectedTravelTime = "duration"
        case typicalTravelTime = "duration_typical"
        case instructions
        case instructionsDisplayedAlongStep = "bannerInstructions"
        case instructionsSpokenAlongStep = "voiceInstructions"
        case intersections
        case maneuver
        case pronunciation
        case rotaryPronunciation = "rotary_pronunciation"
        case speedLimitSignStandard = "speedLimitSign"
        case speedLimitUnit
        case transportType = "mode"
    }

    private struct Maneuver: Codable, ForeignMemberContainer, Equatable, Sendable {
        var foreignMembers: JSONObject = [:]

        private enum CodingKeys: String, CodingKey {
            case instruction
            case location
            case type
            case exitIndex = "exit"
            case direction = "modifier"
            case initialHeading = "bearing_before"
            case finalHeading = "bearing_after"
        }

        let instructions: String
        let maneuverType: ManeuverType
        let maneuverDirection: ManeuverDirection?
        let maneuverLocation: Turf.LocationCoordinate2D
        let initialHeading: Turf.LocationDirection?
        let finalHeading: Turf.LocationDirection?
        let exitIndex: Int?

        init(
            instructions: String,
            maneuverType: ManeuverType,
            maneuverDirection: ManeuverDirection?,
            maneuverLocation: Turf.LocationCoordinate2D,
            initialHeading: Turf.LocationDirection?,
            finalHeading: Turf.LocationDirection?,
            exitIndex: Int?
        ) {
            self.instructions = instructions
            self.maneuverType = maneuverType
            self.maneuverLocation = maneuverLocation
            self.maneuverDirection = maneuverDirection
            self.initialHeading = initialHeading
            self.finalHeading = finalHeading
            self.exitIndex = exitIndex
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.maneuverLocation = try container.decode(LocationCoordinate2DCodable.self, forKey: .location)
                .decodedCoordinates
            self.maneuverType = (try? container.decode(ManeuverType.self, forKey: .type)) ?? .default
            self.maneuverDirection = try container.decodeIfPresent(ManeuverDirection.self, forKey: .direction)
            self.exitIndex = try container.decodeIfPresent(Int.self, forKey: .exitIndex)

            self.initialHeading = try container.decodeIfPresent(Turf.LocationDirection.self, forKey: .initialHeading)
            self.finalHeading = try container.decodeIfPresent(Turf.LocationDirection.self, forKey: .finalHeading)

            if let instruction = try? container.decode(String.self, forKey: .instruction) {
                self.instructions = instruction
            } else {
                self.instructions = "\(maneuverType) \(maneuverDirection?.rawValue ?? "")"
            }

            try decodeForeignMembers(notKeyedBy: CodingKeys.self, with: decoder)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encode(instructions, forKey: .instruction)
            try container.encode(maneuverType, forKey: .type)
            try container.encodeIfPresent(exitIndex, forKey: .exitIndex)

            try container.encodeIfPresent(maneuverDirection, forKey: .direction)
            try container.encode(LocationCoordinate2DCodable(maneuverLocation), forKey: .location)
            try container.encodeIfPresent(initialHeading, forKey: .initialHeading)
            try container.encodeIfPresent(finalHeading, forKey: .finalHeading)

            try encodeForeignMembers(notKeyedBy: CodingKeys.self, to: encoder)
        }
    }

    // MARK: Creating a Step

    /// Initializes a step.
    /// - Parameters:
    ///   - transportType: The mode of transportation used for the step.
    ///   - maneuverLocation: The location of the maneuver at the beginning of this step.
    ///   - maneuverType: The type of maneuver required for beginning this step.
    ///   - maneuverDirection: Additional directional information to clarify the maneuver type.
    ///   - instructions: A string with instructions explaining how to perform the step’s maneuver.
    ///   - initialHeading: The user’s heading immediately before performing the maneuver.
    ///   - finalHeading: The user’s heading immediately after performing the maneuver.
    ///   - drivingSide: Indicates what side of a bidirectional road the driver must be driving on. Also referred to as
    /// the rule of the road.
    ///   - exitCodes: Any [exit numbers](https://en.wikipedia.org/wiki/Exit_number) assigned to the highway exit at the
    /// maneuver.
    ///   - exitNames: The names of the roundabout exit.
    ///   - phoneticExitNames: A phonetic or phonemic transcription indicating how to pronounce the names in the
    /// ``exitNames`` property.
    ///   - distance: The step’s distance, measured in meters.
    ///   - expectedTravelTime: The step's expected travel time, measured in seconds.
    ///   - typicalTravelTime: The step's typical travel time, measured in seconds.
    ///   - names: The names of the road or path leading from this step’s maneuver to the next step’s maneuver.
    ///   - phoneticNames: A phonetic or phonemic transcription indicating how to pronounce the names in the ``names``
    /// property.
    ///   - codes: Any route reference codes assigned to the road or path leading from this step’s maneuver to the next
    /// step’s maneuver.
    ///   - destinationCodes: Any route reference codes that appear on guide signage for the road leading from this
    /// step’s maneuver to the next step’s maneuver.
    ///   - destinations: Destinations, such as [control cities](https://en.wikipedia.org/wiki/Control_city), that
    /// appear on guide signage for the road leading from this step’s maneuver to the next step’s maneuver.
    ///   - intersections: An array of intersections along the step.
    ///   - speedLimitSignStandard: The sign design standard used for speed limit signs along the step.
    ///   - speedLimitUnit: The unit of speed limits on speed limit signs along the step.
    ///   - instructionsSpokenAlongStep: Instructions about the next step’s maneuver, optimized for speech synthesis.
    ///   - instructionsDisplayedAlongStep: Instructions about the next step’s maneuver, optimized for display in real
    /// time.
    ///   - administrativeAreaContainerByIntersection: administrative region indices for each ``Intersection`` along the
    /// step.
    ///   - segmentIndicesByIntersection: Segments indices for each ``Intersection`` along the step.
    public init(
        transportType: TransportType,
        maneuverLocation: Turf.LocationCoordinate2D,
        maneuverType: ManeuverType,
        maneuverDirection: ManeuverDirection? = nil,
        instructions: String,
        initialHeading: Turf.LocationDirection? = nil,
        finalHeading: Turf.LocationDirection? = nil,
        drivingSide: DrivingSide,
        exitCodes: [String]? = nil,
        exitNames: [String]? = nil,
        phoneticExitNames: [String]? = nil,
        distance: Turf.LocationDistance,
        expectedTravelTime: TimeInterval,
        typicalTravelTime: TimeInterval? = nil,
        names: [String]? = nil,
        phoneticNames: [String]? = nil,
        codes: [String]? = nil,
        destinationCodes: [String]? = nil,
        destinations: [String]? = nil,
        intersections: [Intersection]? = nil,
        speedLimitSignStandard: SignStandard? = nil,
        speedLimitUnit: UnitSpeed? = nil,
        instructionsSpokenAlongStep: [SpokenInstruction]? = nil,
        instructionsDisplayedAlongStep: [VisualInstructionBanner]? = nil,
        administrativeAreaContainerByIntersection: [Int?]? = nil,
        segmentIndicesByIntersection: [Int?]? = nil
    ) {
        self.transportType = transportType
        self.maneuverLocation = maneuverLocation
        self.maneuverType = maneuverType
        self.maneuverDirection = maneuverDirection
        self.instructions = instructions
        self.initialHeading = initialHeading
        self.finalHeading = finalHeading
        self.drivingSide = drivingSide
        self.exitCodes = exitCodes
        self.exitNames = exitNames
        self.phoneticExitNames = phoneticExitNames
        self.distance = distance
        self.expectedTravelTime = expectedTravelTime
        self.typicalTravelTime = typicalTravelTime
        self.names = names
        self.phoneticNames = phoneticNames
        self.codes = codes
        self.destinationCodes = destinationCodes
        self.destinations = destinations
        self.intersections = intersections
        self.speedLimitSignStandard = speedLimitSignStandard
        self.speedLimitUnit = speedLimitUnit
        self.instructionsSpokenAlongStep = instructionsSpokenAlongStep
        self.instructionsDisplayedAlongStep = instructionsDisplayedAlongStep
        self.administrativeAreaContainerByIntersection = administrativeAreaContainerByIntersection
        self.segmentIndicesByIntersection = segmentIndicesByIntersection
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(instructionsSpokenAlongStep, forKey: .instructionsSpokenAlongStep)
        try container.encodeIfPresent(instructionsDisplayedAlongStep, forKey: .instructionsDisplayedAlongStep)
        try container.encode(distance, forKey: .distance)
        try container.encode(expectedTravelTime, forKey: .expectedTravelTime)
        try container.encodeIfPresent(typicalTravelTime, forKey: .typicalTravelTime)
        try container.encode(transportType, forKey: .transportType)

        let isRound = maneuverType == .takeRotary || maneuverType == .takeRoundabout
        let road = Road(
            names: isRound ? exitNames : names,
            codes: codes,
            exitCodes: exitCodes,
            destinations: destinations,
            destinationCodes: destinationCodes,
            rotaryNames: isRound ? names : nil
        )
        try road.encode(to: encoder)
        if isRound {
            try container.encodeIfPresent(phoneticNames?.tagValues(joinedBy: ";"), forKey: .rotaryPronunciation)
            try container.encodeIfPresent(phoneticExitNames?.tagValues(joinedBy: ";"), forKey: .pronunciation)
        } else {
            try container.encodeIfPresent(phoneticNames?.tagValues(joinedBy: ";"), forKey: .pronunciation)
        }

        if let intersectionsToEncode = intersections {
            var intersectionsContainer = container.nestedUnkeyedContainer(forKey: .intersections)
            try Intersection.encode(
                intersections: intersectionsToEncode,
                to: &intersectionsContainer,
                administrativeRegionIndices: administrativeAreaContainerByIntersection,
                segmentIndicesByIntersection: segmentIndicesByIntersection
            )
        }

        try container.encode(drivingSide, forKey: .drivingSide)
        if let shape {
            let options = encoder.userInfo[.options] as? DirectionsOptions
            let shapeFormat = options?.shapeFormat ?? .default
            let polyLineString = PolyLineString(lineString: shape, shapeFormat: shapeFormat)
            try container.encode(polyLineString, forKey: .shape)
        }

        var maneuver = Maneuver(
            instructions: instructions,
            maneuverType: maneuverType,
            maneuverDirection: maneuverDirection,
            maneuverLocation: maneuverLocation,
            initialHeading: initialHeading,
            finalHeading: finalHeading,
            exitIndex: exitIndex
        )
        maneuver.foreignMembers = maneuverForeignMembers
        try container.encode(maneuver, forKey: .maneuver)

        try container.encodeIfPresent(speedLimitSignStandard, forKey: .speedLimitSignStandard)
        if let speedLimitUnit,
           let unit = SpeedLimitDescriptor.UnitDescriptor(unit: speedLimitUnit)
        {
            try container.encode(unit, forKey: .speedLimitUnit)
        }

        try encodeForeignMembers(notKeyedBy: CodingKeys.self, to: encoder)
    }

    static func decode(from decoder: Decoder, administrativeRegions: [AdministrativeRegion]) throws -> [RouteStep] {
        var container = try decoder.unkeyedContainer()

        var steps = [RouteStep]()
        while !container.isAtEnd {
            let step = try RouteStep(from: container.superDecoder(), administrativeRegions: administrativeRegions)

            steps.append(step)
        }

        return steps
    }

    /// Used to Decode `Intersection.admin_index`
    private struct AdministrativeAreaIndex: Codable, Sendable {
        private enum CodingKeys: String, CodingKey {
            case administrativeRegionIndex = "admin_index"
        }

        var administrativeRegionIndex: Int?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.administrativeRegionIndex = try container.decodeIfPresent(Int.self, forKey: .administrativeRegionIndex)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(administrativeRegionIndex, forKey: .administrativeRegionIndex)
        }
    }

    /// Used to Decode `Intersection.geometry_index`
    private struct IntersectionShapeIndex: Codable, Sendable {
        private enum CodingKeys: String, CodingKey {
            case geometryIndex = "geometry_index"
        }

        let geometryIndex: Int?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.geometryIndex = try container.decodeIfPresent(Int.self, forKey: .geometryIndex)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(geometryIndex, forKey: .geometryIndex)
        }
    }

    public init(from decoder: Decoder) throws {
        try self.init(from: decoder, administrativeRegions: nil)
    }

    init(from decoder: Decoder, administrativeRegions: [AdministrativeRegion]?) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let maneuver = try container.decode(Maneuver.self, forKey: .maneuver)

        self.maneuverLocation = maneuver.maneuverLocation
        self.maneuverType = maneuver.maneuverType
        self.maneuverDirection = maneuver.maneuverDirection
        self.exitIndex = maneuver.exitIndex
        self.initialHeading = maneuver.initialHeading
        self.finalHeading = maneuver.finalHeading
        self.instructions = maneuver.instructions
        self.maneuverForeignMembers = maneuver.foreignMembers

        if let polyLineString = try container.decodeIfPresent(PolyLineString.self, forKey: .shape) {
            self.shape = try LineString(polyLineString: polyLineString)
        } else {
            self.shape = nil
        }

        self.drivingSide = try container.decode(DrivingSide.self, forKey: .drivingSide)

        self.instructionsSpokenAlongStep = try container.decodeIfPresent(
            [SpokenInstruction].self,
            forKey: .instructionsSpokenAlongStep
        )

        if var visuals = try container.decodeIfPresent(
            [VisualInstructionBanner].self,
            forKey: .instructionsDisplayedAlongStep
        ) {
            for index in visuals.indices {
                visuals[index].drivingSide = drivingSide
            }

            self.instructionsDisplayedAlongStep = visuals
        } else {
            self.instructionsDisplayedAlongStep = nil
        }

        self.distance = try container.decode(Turf.LocationDirection.self, forKey: .distance)
        self.expectedTravelTime = try container.decode(TimeInterval.self, forKey: .expectedTravelTime)
        self.typicalTravelTime = try container.decodeIfPresent(TimeInterval.self, forKey: .typicalTravelTime)

        self.transportType = try container.decode(TransportType.self, forKey: .transportType)
        self.administrativeAreaContainerByIntersection = try container.decodeIfPresent(
            [AdministrativeAreaIndex].self,
            forKey: .intersections
        )?
            .map(\.administrativeRegionIndex)
        var rawIntersections = try container.decodeIfPresent([Intersection].self, forKey: .intersections)

        // Updating `Intersection.regionCode` since we removed it's `admin_index` for convenience
        if let administrativeRegions,
           rawIntersections != nil,
           let rawAdminIndicies = administrativeAreaContainerByIntersection
        {
            for index in 0..<rawIntersections!.count {
                if let regionIndex = rawAdminIndicies[index],
                   administrativeRegions.count > regionIndex
                {
                    rawIntersections![index].updateRegionCode(administrativeRegions[regionIndex].countryCode)
                }
            }
        }

        self.intersections = rawIntersections

        self.segmentIndicesByIntersection = try container.decodeIfPresent(
            [IntersectionShapeIndex].self,
            forKey: .intersections
        )?.map(\.geometryIndex)

        let road = try Road(from: decoder)
        self.codes = road.codes
        self.exitCodes = road.exitCodes
        self.destinations = road.destinations
        self.destinationCodes = road.destinationCodes

        self.speedLimitSignStandard = try container.decodeIfPresent(SignStandard.self, forKey: .speedLimitSignStandard)
        self.speedLimitUnit = try (container.decodeIfPresent(
            SpeedLimitDescriptor.UnitDescriptor.self,
            forKey: .speedLimitUnit
        ))?.describedUnit

        let type = maneuverType
        if type == .takeRotary || type == .takeRoundabout {
            self.names = road.rotaryNames
            self.phoneticNames = try container.decodeIfPresent(String.self, forKey: .rotaryPronunciation)?
                .tagValues(separatedBy: ";")
            self.exitNames = road.names
            self.phoneticExitNames = try container.decodeIfPresent(String.self, forKey: .pronunciation)?
                .tagValues(separatedBy: ";")
        } else {
            self.names = road.names
            self.phoneticNames = try container.decodeIfPresent(String.self, forKey: .pronunciation)?
                .tagValues(separatedBy: ";")
            self.exitNames = nil
            self.phoneticExitNames = nil
        }

        try decodeForeignMembers(notKeyedBy: CodingKeys.self, with: decoder)
        try decodeForeignMembers(notKeyedBy: Road.CodingKeys.self, with: decoder)
    }

    // MARK: Getting the Shape of the Step

    /// The path of the route step from the location of the maneuver to the location of the next step’s maneuver.
    ///
    /// The value of this property may be `nil`, for example when the maneuver type is ``ManeuverType/arrive``.
    ///
    /// Using the [Mapbox Maps SDK for iOS](https://www.mapbox.com/ios-sdk/) or [Mapbox Maps SDK for
    /// macOS](https://github.com/mapbox/mapbox-gl-native/tree/master/platform/macos/), you can create an `MGLPolyline`
    /// object using the `LineString.coordinates` property to display a portion of a route on an `MGLMapView`.
    public var shape: LineString?

    // MARK: Getting the Mode of Transportation

    /// The mode of transportation used for the step.
    ///
    /// This step may use a different mode of transportation than the overall route.
    public let transportType: TransportType

    // MARK: Getting Details About the Maneuver

    /// The location of the maneuver at the beginning of this step.
    public let maneuverLocation: Turf.LocationCoordinate2D

    /// The type of maneuver required for beginning this step.
    public let maneuverType: ManeuverType

    /// Additional directional information to clarify the maneuver type.
    public let maneuverDirection: ManeuverDirection?

    /// A string with instructions explaining how to perform the step’s maneuver.
    ///
    /// You can display this string or read it aloud to the user. The string does not include the distance to or from
    /// the maneuver. For instructions optimized for real-time delivery during turn-by-turn navigation, set the
    /// ``DirectionsOptions/includesSpokenInstructions`` option and use the ``instructionsSpokenAlongStep`` property. If
    /// you need customized instructions, you can construct them yourself from the step’s other properties or use [OSRM
    /// Text Instructions](https://github.com/Project-OSRM/osrm-text-instructions.swift/).
    ///
    /// - Note: If you use the MapboxDirections framework with the Mapbox Directions API, this property is formatted and
    /// localized for display to the user. If you use OSRM directly, this property contains a basic string that only
    /// includes the maneuver type and direction. Use [OSRM Text
    /// Instructions](https://github.com/Project-OSRM/osrm-text-instructions.swift/) to construct a complete, localized
    /// instruction string for display.
    public let instructions: String

    /// The user’s heading immediately before performing the maneuver.
    public let initialHeading: Turf.LocationDirection?

    /// The user’s heading immediately after performing the maneuver.
    ///
    /// The value of this property may differ from the user’s heading after traveling along the road past the maneuver.
    public let finalHeading: Turf.LocationDirection?

    /// Indicates what side of a bidirectional road the driver must be driving on. Also referred to as the rule of the
    /// road.
    public let drivingSide: DrivingSide

    /// The number of exits from the previous maneuver up to and including this step’s maneuver.
    ///
    /// If the maneuver takes place on a surface street, this property counts intersections. The number of intersections
    /// does not necessarily correspond to the number of blocks. If the maneuver takes place on a grade-separated
    /// highway (freeway or motorway), this property counts highway exits but not highway entrances. If the maneuver is
    /// a roundabout maneuver, the exit index is the number of exits from the approach to the recommended outlet. For
    /// the signposted exit numbers associated with a highway exit, use the ``exitCodes`` property.
    ///
    /// In some cases, the number of exits leading to a maneuver may be more useful to the user than the distance to the
    /// maneuver.
    public var exitIndex: Int?

    /// Any [exit numbers](https://en.wikipedia.org/wiki/Exit_number) assigned to the highway exit at the maneuver.
    ///
    /// This property is only set when the ``maneuverType`` is ``ManeuverType/takeOffRamp``. For the number of exits
    /// from the previous maneuver, regardless of the highway’s exit numbering scheme, use the ``exitIndex`` property.
    /// For the route reference codes associated with the connecting road, use the ``destinationCodes`` property. For
    /// the names associated with a roundabout exit, use the ``exitNames`` property.
    ///
    /// An exit number is an alphanumeric identifier posted at or ahead of a highway off-ramp. Exit numbers may increase
    /// or decrease sequentially along a road, or they may correspond to distances from either end of the road. An
    /// alphabetic suffix may appear when multiple exits are located in the same interchange. If multiple exits are
    /// [combined into a single
    /// exit](https://en.wikipedia.org/wiki/Local-express_lanes#Example_of_cloverleaf_interchanges), the step may have
    /// multiple exit codes.
    public let exitCodes: [String]?

    /// The names of the roundabout exit.
    ///
    /// This property is only set for roundabout (traffic circle or rotary) maneuvers. For the signposted names
    /// associated with a highway exit, use the ``destinations`` property. For the signposted exit numbers, use the
    /// ``exitCodes`` property.
    ///
    /// If you display a name to the user, you may need to abbreviate common words like “East” or “Boulevard” to ensure
    /// that it fits in the allotted space.
    public let exitNames: [String]?

    /// A phonetic or phonemic transcription indicating how to pronounce the names in the ``exitNames`` property.
    ///
    /// This property is only set for roundabout (traffic circle or rotary) maneuvers.
    ///
    /// The transcription is written in the [International Phonetic
    /// Alphabet](https://en.wikipedia.org/wiki/International_Phonetic_Alphabet).
    public let phoneticExitNames: [String]?

    // MARK: Getting Details About the Approach to the Next Maneuver

    /// The step’s distance, measured in meters.
    ///
    /// The value of this property accounts for the distance that the user must travel to go from this step’s maneuver
    /// location to the next step’s maneuver location. It is not the sum of the direct distances between the route’s
    /// waypoints, nor should you assume that the user would travel along this distance at a fixed speed.
    public let distance: Turf.LocationDistance

    /// The step’s expected travel time, measured in seconds.
    ///
    /// The value of this property reflects the time it takes to go from this step’s maneuver location to the next
    /// step’s maneuver location. If the route was calculated using the ``ProfileIdentifier/automobileAvoidingTraffic``
    /// profile, this property reflects current traffic conditions at the time of the request, not necessarily the
    /// traffic conditions at the time the user would begin this step. For other profiles, this property reflects travel
    /// time under ideal conditions and does not account for traffic congestion. If the step makes use of a ferry or
    /// train, the actual travel time may additionally be subject to the schedules of those services.
    ///
    /// Do not assume that the user would travel along the step at a fixed speed. For the expected travel time on each
    /// individual segment along the leg, specify the ``AttributeOptions/expectedTravelTime`` option and use the
    /// ``RouteLeg/expectedSegmentTravelTimes`` property.
    public var expectedTravelTime: TimeInterval

    /// The step’s typical travel time, measured in seconds.
    ///
    /// The value of this property reflects the typical time it takes to go from this step’s maneuver location to the
    /// next step’s maneuver location. This property is available when using the
    /// ``ProfileIdentifier/automobileAvoidingTraffic`` profile. This property reflects typical traffic conditions at
    /// the time of the request, not necessarily the typical traffic conditions at the time the user would begin this
    /// step. If the step makes use of a ferry, the typical travel time may additionally be subject to the schedule of
    /// this service.
    ///
    /// Do not assume that the user would travel along the step at a fixed speed.
    public var typicalTravelTime: TimeInterval?

    /// The names of the road or path leading from this step’s maneuver to the next step’s maneuver.
    ///
    /// If the maneuver is a turning maneuver, the step’s names are the name of the road or path onto which the user
    /// turns. If you display a name to the user, you may need to abbreviate common words like “East” or “Boulevard” to
    /// ensure that it fits in the allotted space.
    ///
    /// If the maneuver is a roundabout maneuver, the outlet to take is named in the ``exitNames`` property; the
    /// ``names`` property is only set for large roundabouts that have their own names.
    public let names: [String]?

    /// A phonetic or phonemic transcription indicating how to pronounce the names in the `names` property.
    ///
    /// The transcription is written in the [International Phonetic
    /// Alphabet](https://en.wikipedia.org/wiki/International_Phonetic_Alphabet).
    ///
    /// If the maneuver traverses a large, named roundabout, this property contains a hint about how to pronounce the
    /// names of the outlet to take.
    public let phoneticNames: [String]?

    /// Any route reference codes assigned to the road or path leading from this step’s maneuver to the next step’s
    /// maneuver.
    ///
    /// A route reference code commonly consists of an alphabetic network code, a space or hyphen, and a route number.
    /// You should not assume that the network code is globally unique: for example, a network code of “NH” may indicate
    /// a “National Highway” or “New Hampshire”. Moreover, a route number may not even uniquely identify a route within
    /// a given network.
    ///
    /// If a highway ramp is part of a numbered route, its reference code is contained in this property. On the other
    /// hand, guide signage for a highway ramp usually indicates route reference codes of the adjoining road; use the
    /// ``destinationCodes`` property for those route reference codes.
    public let codes: [String]?

    /// Any route reference codes that appear on guide signage for the road leading from this step’s maneuver to the
    /// next step’s maneuver.
    ///
    /// This property is typically available in steps leading to or from a freeway or expressway. This property contains
    /// route reference codes associated with a road later in the route. If a highway ramp is itself part of a numbered
    /// route, its reference code is contained in the `codes` property. For the signposted exit numbers associated with
    /// a highway exit, use the `exitCodes` property.
    ///
    /// A route reference code commonly consists of an alphabetic network code, a space or hyphen, and a route number.
    /// You should not assume that the network code is globally unique: for example, a network code of “NH” may indicate
    /// a “National Highway” or “New Hampshire”. Moreover, a route number may not even uniquely identify a route within
    /// a given network. A destination code for a divided road is often suffixed with the cardinal direction of travel,
    /// for example “I 80 East”.
    public let destinationCodes: [String]?

    /// Destinations, such as [control cities](https://en.wikipedia.org/wiki/Control_city), that appear on guide signage
    /// for the road leading from this step’s maneuver to the next step’s maneuver.
    ///
    /// This property is typically available in steps leading to or from a freeway or expressway.
    public let destinations: [String]?

    /// An array of intersections along the step.
    ///
    /// Each item in the array corresponds to a cross street, starting with the intersection at the maneuver location
    /// indicated by the coordinates property and continuing with each cross street along the step.
    public let intersections: [Intersection]?

    /// Each intersection’s administrative region index.
    ///
    /// This property is set to `nil` if the ``intersections`` property is `nil`. An individual array element may be
    /// `nil` if the corresponding ``Intersection`` instance has no administrative region assigned.
    /// - SeeAlso: ``Intersection/regionCode``, ``RouteLeg/regionCode(atStepIndex:intersectionIndex:)``
    public let administrativeAreaContainerByIntersection: [Int?]?

    /// Segments indices for each ``Intersection`` along the step.
    ///
    /// The indices are arranged in the same order as the items of ``intersections``. This property is `nil` if
    /// ``intersections`` is `nil`. An individual item may be `nil` if the corresponding JSON-formatted intersection
    /// object has no `geometry_index` property.
    public let segmentIndicesByIntersection: [Int?]?

    /// The sign design standard used for speed limit signs along the step.
    ///
    /// This standard affects how corresponding speed limits in the ``RouteLeg/segmentMaximumSpeedLimits`` property
    /// should be displayed.
    public let speedLimitSignStandard: SignStandard?

    /// The unit of speed limits on speed limit signs along the step.
    ///
    /// This standard affects how corresponding speed limits in the ``RouteLeg/segmentMaximumSpeedLimits`` property
    /// should be displayed.
    public let speedLimitUnit: UnitSpeed?

    // MARK: Getting Details About the Next Maneuver

    /// Instructions about the next step’s maneuver, optimized for speech synthesis.
    ///
    /// As the user traverses this step, you can give them advance notice of the upcoming maneuver by reading aloud each
    /// item in this array in order as the user reaches the specified distances along this step. The text of the spoken
    /// instructions refers to the details in the next step, but the distances are measured from the beginning of this
    /// step.
    ///
    /// This property is non-`nil` if the ``DirectionsOptions/includesSpokenInstructions`` option is set to `true`. For
    /// instructions designed for display, use the ``instructions`` property.
    public let instructionsSpokenAlongStep: [SpokenInstruction]?

    /// Instructions about the next step’s maneuver, optimized for display in real time.
    ///
    /// As the user traverses this step, you can give them advance notice of the upcoming maneuver by displaying each
    /// item in this array in order as the user reaches the specified distances along this step. The text and images of
    /// the visual instructions refer to the details in the next step, but the distances are measured from the beginning
    /// of this step.
    ///
    /// This property is non-`nil` if the ``DirectionsOptions/includesVisualInstructions`` option is set to `true`. For
    /// instructions designed for speech synthesis, use the ``instructionsSpokenAlongStep`` property. For instructions
    /// designed for display in a static list, use the ``instructions`` property.
    public let instructionsDisplayedAlongStep: [VisualInstructionBanner]?
}

extension RouteStep: CustomStringConvertible {
    public var description: String {
        return instructions
    }
}

extension RouteStep: CustomQuickLookConvertible {
    func debugQuickLookObject() -> Any? {
        guard let shape else {
            return nil
        }
        return debugQuickLookURL(illustrating: shape)
    }
}

extension RouteStep {
    public static func == (lhs: RouteStep, rhs: RouteStep) -> Bool {
        // Compare all the properties, from cheapest to most expensive to compare.
        return lhs.initialHeading == rhs.initialHeading &&
            lhs.finalHeading == rhs.finalHeading &&
            lhs.instructions == rhs.instructions &&
            lhs.exitIndex == rhs.exitIndex &&
            lhs.distance == rhs.distance &&
            lhs.expectedTravelTime == rhs.expectedTravelTime &&
            lhs.typicalTravelTime == rhs.typicalTravelTime &&

            lhs.maneuverType == rhs.maneuverType &&
            lhs.maneuverDirection == rhs.maneuverDirection &&
            lhs.drivingSide == rhs.drivingSide &&
            lhs.transportType == rhs.transportType &&

            lhs.maneuverLocation == rhs.maneuverLocation &&

            lhs.exitCodes == rhs.exitCodes &&
            lhs.exitNames == rhs.exitNames &&
            lhs.phoneticExitNames == rhs.phoneticExitNames &&
            lhs.names == rhs.names &&
            lhs.phoneticNames == rhs.phoneticNames &&
            lhs.codes == rhs.codes &&
            lhs.destinationCodes == rhs.destinationCodes &&
            lhs.destinations == rhs.destinations &&

            lhs.speedLimitSignStandard == rhs.speedLimitSignStandard &&
            lhs.speedLimitUnit == rhs.speedLimitUnit &&

            lhs.intersections == rhs.intersections &&
            lhs.instructionsSpokenAlongStep == rhs.instructionsSpokenAlongStep &&
            lhs.instructionsDisplayedAlongStep == rhs.instructionsDisplayedAlongStep &&

            lhs.shape == rhs.shape
    }
}
