import Foundation
import MapboxDirections

extension ResponseOptions {
    var directionsOptionsType: DirectionsOptions.Type {
        switch self {
        case .route(let options):
            type(of: options)
        case .match(let options):
            type(of: options)
        }
    }

    var directionsOptions: DirectionsOptions {
        switch self {
        case .route(let options):
            options
        case .match(let options):
            options
        }
    }
}

extension DirectionsOptions {
    static func from(requestString: String) -> Self? {
        guard let url = URL(string: requestString),
              let baseOptions = RouteOptions(url: url)
        else {
            return nil
        }
        let profileIdentifier = baseOptions.profileIdentifier
        let waypoints = baseOptions.waypoints
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems
        return Self(waypoints: waypoints, profileIdentifier: profileIdentifier, queryItems: queryItems)
    }

    static func requestOptions(from requestString: String) -> ResponseOptions? {
        guard let directionsOptions = from(requestString: requestString) else {
            return nil
        }
        switch directionsOptions {
        case let routeOptions as RouteOptions:
            return .route(routeOptions)
        case let matchOptions as MatchOptions:
            return .match(matchOptions)
        default:
            return nil
        }
    }
}
