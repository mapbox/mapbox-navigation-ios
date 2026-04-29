import CoreLocation
import MapboxDirections
import MapboxNavigationCore

final class CustomRouteOptions: NavigationRouteOptions, @unchecked Sendable {
    enum CodingKeys: String, CodingKey {
        case custom
    }

    var custom: String?

    required init(
        waypoints: [MapboxDirections.Waypoint],
        profileIdentifier: ProfileIdentifier? = .automobileAvoidingTraffic,
        queryItems: [URLQueryItem]? = nil
    ) {
        self.custom = queryItems?.first(where: { $0.name == CodingKeys.custom.stringValue })?.value
        super.init(waypoints: waypoints, profileIdentifier: profileIdentifier, queryItems: queryItems)
    }

    override var urlQueryItems: [URLQueryItem] {
        var items = super.urlQueryItems
        if let custom {
            items.append(URLQueryItem(name: CodingKeys.custom.stringValue, value: custom))
        }
        return items
    }

    required init(from decoder: any Decoder) throws {
        try super.init(from: decoder)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.custom = try container.decodeIfPresent(String.self, forKey: .custom)
    }

    override func encode(to encoder: any Encoder) throws {
        try super.encode(to: encoder)

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(custom, forKey: .custom)
    }
}
