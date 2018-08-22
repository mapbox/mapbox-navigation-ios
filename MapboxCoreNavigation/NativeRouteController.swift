import Foundation
import MapboxNavigationNative
import MapboxDirections


public class NativeRouteController: RouteController {
    
    let navigator = MBNavigator()
    
    public var routeData: Data? {
        didSet {
            navigator.setDirectionsForDirections(getRouteResponseAsString())
        }
    }
    
    override public var route: Route {
        get {
            return routeProgress.route
        }
        set {
            navigator.setDirectionsForDirections(getRouteResponseAsString())
            routeProgress = RouteProgress(route: newValue)
        }
    }
    
    func getRouteResponseAsString() -> String {
        guard let routeData = routeData else {
            assertionFailure("Route data missing")
            return String()
        }
        
        guard let routeString = String(data: routeData, encoding: .utf8) else {
            assertionFailure("Unable to convert route Data to String")
            return String()
        }
        return routeString
    }
    
    override func getDirections(from location: CLLocation, along progress: RouteProgress, completion: @escaping (Route?, Error?) -> Void) {
        routeTask?.cancel()
        let options = progress.reroutingOptions(with: location)
        
        self.lastRerouteLocation = location
        
        let complete = { [weak self] (route: Route?, error: NSError?) in
            self?.isRerouting = false
            completion(route, error)
        }
        
        routeTask = directions.calculate(options) {[weak self] (waypoints, potentialRoutes, response, potentialError) in
            guard let routes = potentialRoutes else {
                complete(nil, potentialError)
                return
            }
            
            self?.routeData = response // TODO: Ensure route
            
            let mostSimilar = routes.mostSimilar(to: progress.route)
            
            complete(mostSimilar ?? routes.first, potentialError)
        }
    }
    
    override public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locations.forEach { navigator.updateLocation(for: $0.asMBFixLocation()) }
        super.locationManager(manager, didUpdateLocations: locations)
    }
    
    override public func userIsOnRoute(_ location: CLLocation) -> Bool {
        let status = navigator.getStatusForTimestamp(location.timestamp)
        return status.routeState.isOnRoute()
    }
}

extension MBRouteState {
    
    func isOnRoute() -> Bool {
        let validStates: [MBRouteState] = [MBRouteState.initialized, MBRouteState.tracking, MBRouteState.complete]
        return validStates.contains(self)
    }
}
