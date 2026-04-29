import Foundation

/// Provides information about amenity that is available at a given ``RestStop``.
public struct Amenity: Codable, Equatable, Sendable {
    /// Name of the amenity, if available.
    public let name: String?

    /// Brand of the amenity, if available.
    public let brand: String?

    /// Type of the amenity.
    public let type: AmenityType

    private enum CodingKeys: String, CodingKey {
        case type
        case name
        case brand
    }

    /// Initializes an ``Amenity``.
    /// - Parameters:
    ///   - type: Type of the amenity.
    ///   - name: Name of the amenity.
    ///   - brand: Brand of the amenity.
    public init(type: AmenityType, name: String? = nil, brand: String? = nil) {
        self.type = type
        self.name = name
        self.brand = brand
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(AmenityType.self, forKey: .type)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.brand = try container.decodeIfPresent(String.self, forKey: .brand)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(brand, forKey: .brand)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.name == rhs.name &&
            lhs.brand == rhs.brand &&
            lhs.type == rhs.type
    }
}
