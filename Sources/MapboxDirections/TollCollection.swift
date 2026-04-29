import Foundation
import Turf

/// `TollCollection` describes corresponding object on the route.
public struct TollCollection: Codable, Equatable, ForeignMemberContainer, Sendable {
    public var foreignMembers: JSONObject = [:]

    public enum CollectionType: String, Codable, Sendable {
        case booth = "toll_booth"
        case gantry = "toll_gantry"
    }

    /// The type of the toll collection point.
    public let type: CollectionType

    /// The name of the toll collection point.
    public var name: String?

    private enum CodingKeys: String, CodingKey {
        case type
        case name
    }

    public init(type: CollectionType) {
        self.init(type: type, name: nil)
    }

    public init(type: CollectionType, name: String?) {
        self.type = type
        self.name = name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(CollectionType.self, forKey: .type)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)

        try decodeForeignMembers(notKeyedBy: CodingKeys.self, with: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(name, forKey: .name)

        try encodeForeignMembers(notKeyedBy: CodingKeys.self, to: encoder)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.type == rhs.type
    }
}
