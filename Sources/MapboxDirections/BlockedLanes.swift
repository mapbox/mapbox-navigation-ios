
import Foundation

/// Defines a lane affected by the ``Incident``
public struct BlockedLanes: OptionSet, CustomStringConvertible, Equatable, Sendable {
    public var rawValue: Int
    var stringKey: String?

    public init(rawValue: Int) {
        self.init(rawValue: rawValue, key: nil)
    }

    init(rawValue: Int, key: String?) {
        self.rawValue = rawValue
        self.stringKey = key
    }

    /// Left lane
    public static let left = BlockedLanes(rawValue: 1 << 0, key: "LEFT")
    /// Left center lane
    ///
    /// Usually refers to the second lane from left on a four-lane highway
    public static let leftCenter = BlockedLanes(rawValue: 1 << 1, key: "LEFT CENTER")
    /// Left turn lane
    public static let leftTurnLane = BlockedLanes(rawValue: 1 << 2, key: "LEFT TURN LANE")
    /// Center lane
    public static let center = BlockedLanes(rawValue: 1 << 3, key: "CENTER")
    /// Right lane
    public static let right = BlockedLanes(rawValue: 1 << 4, key: "RIGHT")
    /// Right center lane
    ///
    /// Usually refers to the second lane from right on a four-lane highway
    public static let rightCenter = BlockedLanes(rawValue: 1 << 5, key: "RIGHT CENTER")
    /// Right turn lane
    public static let rightTurnLane = BlockedLanes(rawValue: 1 << 6, key: "RIGHT TURN LANE")
    /// High occupancy vehicle lane
    public static let highOccupancyVehicle = BlockedLanes(rawValue: 1 << 7, key: "HOV")
    /// Side lane
    public static let side = BlockedLanes(rawValue: 1 << 8, key: "SIDE")
    /// Shoulder lane
    public static let shoulder = BlockedLanes(rawValue: 1 << 9, key: "SHOULDER")
    /// Median lane
    public static let median = BlockedLanes(rawValue: 1 << 10, key: "MEDIAN")
    /// 1st Lane.
    public static let lane1 = BlockedLanes(rawValue: 1 << 11, key: "1")
    /// 2nd Lane.
    public static let lane2 = BlockedLanes(rawValue: 1 << 12, key: "2")
    /// 3rd Lane.
    public static let lane3 = BlockedLanes(rawValue: 1 << 13, key: "3")
    /// 4th Lane.
    public static let lane4 = BlockedLanes(rawValue: 1 << 14, key: "4")
    /// 5th Lane.
    public static let lane5 = BlockedLanes(rawValue: 1 << 15, key: "5")
    /// 6th Lane.
    public static let lane6 = BlockedLanes(rawValue: 1 << 16, key: "6")
    /// 7th Lane.
    public static let lane7 = BlockedLanes(rawValue: 1 << 17, key: "7")
    /// 8th Lane.
    public static let lane8 = BlockedLanes(rawValue: 1 << 18, key: "8")
    /// 9th Lane.
    public static let lane9 = BlockedLanes(rawValue: 1 << 19, key: "9")
    /// 10th Lane.
    public static let lane10 = BlockedLanes(rawValue: 1 << 20, key: "10")

    static var allLanes: [BlockedLanes] {
        return [
            .left,
            .leftCenter,
            .leftTurnLane,
            .center,
            .right,
            .rightCenter,
            .rightTurnLane,
            .highOccupancyVehicle,
            .side,
            .shoulder,
            .median,
            .lane1,
            .lane2,
            .lane3,
            .lane4,
            .lane5,
            .lane6,
            .lane7,
            .lane8,
            .lane9,
            .lane10,
        ]
    }

    /// Creates a ``BlockedLanes`` given an array of strings.
    ///
    /// Resulting options set will only contain known values. If string description does not match any known `Blocked
    /// Lane` identifier - it will be ignored.
    public init?(descriptions: [String]) {
        var blockedLanes: BlockedLanes = []
        Self.allLanes.forEach {
            if descriptions.contains($0.stringKey!) {
                blockedLanes.insert($0)
            }
        }
        self.init(rawValue: blockedLanes.rawValue)
    }

    /// String representation of ``BlockedLanes`` options set.
    ///
    /// Resulting description contains only texts for known options. Custom options will be ignored if any.
    public var description: String {
        var descriptions: [String] = []
        Self.allLanes.forEach {
            if contains($0) {
                descriptions.append($0.stringKey!)
            }
        }
        return descriptions.joined(separator: ",")
    }
}

extension BlockedLanes: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description.components(separatedBy: ",").filter { !$0.isEmpty })
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let descriptions = try container.decode([String].self)
        if let roadClasses = BlockedLanes(descriptions: descriptions) {
            self = roadClasses
        } else {
            throw DirectionsError.invalidResponse(nil)
        }
    }
}
