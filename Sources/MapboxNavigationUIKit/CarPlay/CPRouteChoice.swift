import CarPlay
import MapboxDirections
import MapboxNavigationCore

extension CPRouteChoice {
    struct RouteResponseUserInfo {
        static let key = "\(Bundle.mapboxNavigation.bundleIdentifier!).cpRouteChoice.indexedRouteResponse"

        /// Route response from the Mapbox Directions service with a selected route.
        let navigationRoutes: NavigationRoutes?
        let searchResultRecord: SearchResultRecord?
    }

    var routeResponseUserInfo: RouteResponseUserInfo? {
        guard let userInfo = userInfo as? CarPlayUserInfo else {
            return nil
        }

        return userInfo[RouteResponseUserInfo.key] as? RouteResponseUserInfo
    }

    public var navigationRoutes: NavigationRoutes? {
        return routeResponseUserInfo?.navigationRoutes
    }

    @_spi(MapboxInternal)
    public var searchResult: SearchResultRecord? {
        return routeResponseUserInfo?.searchResultRecord
    }
}
