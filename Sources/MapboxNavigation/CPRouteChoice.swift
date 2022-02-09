import CarPlay
import MapboxDirections

@available(iOS 12.0, *)
extension CPRouteChoice {
    
    struct RouteResponseUserInfo {
        
        static let key = "\(Bundle.mapboxNavigation.bundleIdentifier!).cpRouteChoice.routeResponse"
        
        /**
         Route response from the Mapbox Directions service.
         */
        let response: RouteResponse
        
        /**
         Index of the route.
         */
        let routeIndex: Int
        
        /**
         Options, which were used for calculating results from the Mapbox Directions service.
         */
        let options: DirectionsOptions
    }
    
    var routeResponseFromUserInfo: RouteResponseUserInfo? {
        guard let userInfo = userInfo as? CarPlayUserInfo else {
            return nil
        }
        
        return userInfo[RouteResponseUserInfo.key] as? RouteResponseUserInfo
    }
}
