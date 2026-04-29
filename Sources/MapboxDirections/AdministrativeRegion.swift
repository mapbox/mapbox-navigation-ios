import Foundation
import Turf

/// ``AdministrativeRegion`` describes corresponding object on the route.
///
/// You can also use ``Intersection/regionCode`` or ``RouteLeg/regionCode(atStepIndex:intersectionIndex:)`` to
/// retrieve ISO 3166-1 country code.
public struct AdministrativeRegion: Codable, Equatable, ForeignMemberContainer, Sendable {
    public var foreignMembers: JSONObject = [:]

    private enum CodingKeys: String, CodingKey {
        case countryCodeAlpha3 = "iso_3166_1_alpha3"
        case countryCode = "iso_3166_1"
    }

    /// ISO 3166-1 alpha-3 country code
    public var countryCodeAlpha3: String?
    /// ISO 3166-1 country code
    public var countryCode: String

    public init(countryCode: String, countryCodeAlpha3: String) {
        self.countryCode = countryCode
        self.countryCodeAlpha3 = countryCodeAlpha3
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.countryCode = try container.decode(String.self, forKey: .countryCode)
        self.countryCodeAlpha3 = try container.decodeIfPresent(String.self, forKey: .countryCodeAlpha3)

        try decodeForeignMembers(notKeyedBy: CodingKeys.self, with: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(countryCode, forKey: .countryCode)
        try container.encodeIfPresent(countryCodeAlpha3, forKey: .countryCodeAlpha3)

        try encodeForeignMembers(notKeyedBy: CodingKeys.self, to: encoder)
    }
}
