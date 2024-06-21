import Foundation
import Turf

/// A lane on the road approaching an intersection.
struct Lane: Equatable, ForeignMemberContainer {
    var foreignMembers: JSONObject = [:]

    /// The lane indications specifying the maneuvers that may be executed from the lane.
    let indications: LaneIndication

    /// Whether the lane can be taken to complete the maneuver (`true`) or not (`false`)
    var isValid: Bool

    /// Whether the lane is a preferred lane (`true`) or not (`false`)
    ///
    /// A preferred lane is a lane that is recommended if there are multiple lanes available
    var isActive: Bool?

    /// Which of the ``indications`` is applicable to the current route, when there is more than one
    var validIndication: ManeuverDirection?

    init(indications: LaneIndication, valid: Bool = false, active: Bool? = false, preferred: ManeuverDirection? = nil) {
        self.indications = indications
        self.isValid = valid
        self.isActive = active
        self.validIndication = preferred
    }
}

extension Lane: Codable {
    private enum CodingKeys: String, CodingKey {
        case indications
        case valid
        case active
        case preferred = "valid_indication"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(indications, forKey: .indications)
        try container.encode(isValid, forKey: .valid)
        try container.encodeIfPresent(isActive, forKey: .active)
        try container.encodeIfPresent(validIndication, forKey: .preferred)

        try encodeForeignMembers(notKeyedBy: CodingKeys.self, to: encoder)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.indications = try container.decode(LaneIndication.self, forKey: .indications)
        self.isValid = try container.decode(Bool.self, forKey: .valid)
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .active)
        self.validIndication = try container.decodeIfPresent(ManeuverDirection.self, forKey: .preferred)

        try decodeForeignMembers(notKeyedBy: CodingKeys.self, with: decoder)
    }
}
