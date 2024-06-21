import Foundation

/// Each of these options specifies a maneuver direction for which a given lane can be used.
///
/// A Lane object has zero or more indications that usually correspond to arrows on signs or pavement markings. If no
/// options are specified, it may be the case that no maneuvers are indicated on signage or pavement markings for the
/// lane.
public struct LaneIndication: OptionSet, CustomStringConvertible, Sendable {
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Indicates a sharp turn to the right.
    public static let sharpRight = LaneIndication(rawValue: 1 << 1)

    /// Indicates a turn to the right.
    public static let right = LaneIndication(rawValue: 1 << 2)

    /// Indicates a turn to the right.
    public static let slightRight = LaneIndication(rawValue: 1 << 3)

    /// Indicates no turn.
    public static let straightAhead = LaneIndication(rawValue: 1 << 4)

    /// Indicates a slight turn to the left.
    public static let slightLeft = LaneIndication(rawValue: 1 << 5)

    /// Indicates a turn to the left.
    public static let left = LaneIndication(rawValue: 1 << 6)

    /// Indicates a sharp turn to the left.
    public static let sharpLeft = LaneIndication(rawValue: 1 << 7)

    /// Indicates a U-turn.
    public static let uTurn = LaneIndication(rawValue: 1 << 8)

    /// Creates a lane indication from the given description strings.
    public init?(descriptions: [String]) {
        var laneIndication: LaneIndication = []
        for description in descriptions {
            switch description {
            case "sharp right":
                laneIndication.insert(.sharpRight)
            case "right":
                laneIndication.insert(.right)
            case "slight right":
                laneIndication.insert(.slightRight)
            case "straight":
                laneIndication.insert(.straightAhead)
            case "slight left":
                laneIndication.insert(.slightLeft)
            case "left":
                laneIndication.insert(.left)
            case "sharp left":
                laneIndication.insert(.sharpLeft)
            case "uturn":
                laneIndication.insert(.uTurn)
            case "none":
                break
            default:
                return nil
            }
        }
        self.init(rawValue: laneIndication.rawValue)
    }

    init?(from direction: ManeuverDirection) {
        // Assuming that every possible raw value of ManeuverDirection matches valid raw value of LaneIndication
        self.init(descriptions: [direction.rawValue])
    }

    public var descriptions: [String] {
        if isEmpty {
            return []
        }

        var descriptions: [String] = []
        if contains(.sharpRight) {
            descriptions.append("sharp right")
        }
        if contains(.right) {
            descriptions.append("right")
        }
        if contains(.slightRight) {
            descriptions.append("slight right")
        }
        if contains(.straightAhead) {
            descriptions.append("straight")
        }
        if contains(.slightLeft) {
            descriptions.append("slight left")
        }
        if contains(.left) {
            descriptions.append("left")
        }
        if contains(.sharpLeft) {
            descriptions.append("sharp left")
        }
        if contains(.uTurn) {
            descriptions.append("uturn")
        }
        return descriptions
    }

    public var description: String {
        return descriptions.joined(separator: ",")
    }

    static func indications(from strings: [String], container: SingleValueDecodingContainer) throws -> LaneIndication {
        guard let indications = self.init(descriptions: strings) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unable to initialize lane indications from decoded string. This should not happen."
            )
        }
        return indications
    }
}

extension LaneIndication: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValues = try container.decode([String].self)

        self = try LaneIndication.indications(from: stringValues, container: container)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(descriptions)
    }
}
