import CarPlay
import MapboxDirections
import MapboxCoreNavigation

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
    
    public var indexedRouteResponse: IndexedRouteResponse? {
        return indexedRouteResponseUserInfo?.indexedRouteResponse
    }
}
