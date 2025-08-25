import Foundation
import MapboxCoreNavigation
import MapboxDirections

public final class CustomRouteOptions: NavigationRouteOptions {
    enum CodingKeys: String, CodingKey {
        case custom
    }

    public var custom: String?

    public required init(
        waypoints: [MapboxDirections.Waypoint],
        profileIdentifier: ProfileIdentifier? = .automobileAvoidingTraffic,
        queryItems: [URLQueryItem]? = nil
    ) {
        custom = queryItems?.first(where: { $0.name == CodingKeys.custom.stringValue })?.value
        super.init(waypoints: waypoints, profileIdentifier: profileIdentifier, queryItems: queryItems)
    }

    override public var urlQueryItems: [URLQueryItem] {
        var items = super.urlQueryItems
        if let custom {
            items.append(URLQueryItem(name: CodingKeys.custom.stringValue, value: custom))
        }
        return items
    }

    public required init(from decoder: any Decoder) throws {
        try super.init(from: decoder)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        custom = try container.decodeIfPresent(String.self, forKey: .custom)
    }

    override public func encode(to encoder: any Encoder) throws {
        try super.encode(to: encoder)

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(custom, forKey: .custom)
    }
}
