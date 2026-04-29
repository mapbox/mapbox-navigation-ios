#if !os(Linux)
import MapboxDirections
#if canImport(CoreLocation)
import CoreLocation
#endif

final class CustomRouteOptions: RouteOptions {
    var customParameters: [URLQueryItem]

    init(
        waypoints: [Waypoint],
        profileIdentifier: ProfileIdentifier? = nil,
        customParameters: [URLQueryItem] = []
    ) {
        self.customParameters = customParameters

        super.init(waypoints: waypoints, profileIdentifier: profileIdentifier)
    }

    required init(
        waypoints: [Waypoint],
        profileIdentifier: ProfileIdentifier? = nil,
        queryItems: [URLQueryItem]? = nil
    ) {
        self.customParameters = []
        super.init(
            waypoints: waypoints,
            profileIdentifier: profileIdentifier,
            queryItems: queryItems
        )
    }

    required init(from decoder: any Decoder) throws {
        self.customParameters = []
        try super.init(from: decoder)
    }

    override var urlQueryItems: [URLQueryItem] {
        var combined = super.urlQueryItems
        combined.append(contentsOf: customParameters)
        return combined
    }
}
#endif
