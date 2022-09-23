import CarPlay
import MapboxDirections
import MapboxCoreNavigation

@available(iOS 12.0, *)
extension CPRouteChoice {
    
    struct IndexedRouteResponseUserInfo {
        
        static let key = "\(Bundle.mapboxNavigation.bundleIdentifier!).cpRouteChoice.indexedRouteResponse"
        
        /**
         Route response from the Mapbox Directions service with a selected route.
         */
        let indexedRouteResponse: IndexedRouteResponse
    }
    
    var indexedRouteResponseUserInfo: IndexedRouteResponseUserInfo? {
        guard let userInfo = userInfo as? CarPlayUserInfo else {
            return nil
        }
        
        return userInfo[IndexedRouteResponseUserInfo.key] as? IndexedRouteResponseUserInfo
    }
}
