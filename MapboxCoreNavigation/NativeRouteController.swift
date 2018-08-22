import Foundation
import MapboxNavigationNative
import MapboxDirections


public class NativeRouteController: RouteController {
    
    let navigator = MBNavigator()
    
    override public var route: Route {
        get {
            return routeProgress.route
        }
        set {
            routeProgress = RouteProgress(route: newValue)
            updateNavigator()
        }
    }
    
    func updateNavigator() {
        guard let json = route.json else {
            assertionFailure("Missing json route")
            return
        }
        
        let data = try! JSONSerialization.data(withJSONObject: json, options: [])
        let jsonString = String(data: data, encoding: .utf8)!
        
        navigator.setDirectionsForDirections(jsonString)
    }
    
    public required init(along route: Route, directions: Directions, dataSource source: RouterDataSource) {
        super.init(along: route, directions: directions, dataSource: source)
        updateNavigator()
    }
    
    override func getDirections(from location: CLLocation, along progress: RouteProgress, completion: @escaping (Route?, Error?) -> Void) {
        routeTask?.cancel()
        let options = progress.reroutingOptions(with: location)
        
        self.lastRerouteLocation = location
        
        let complete = { [weak self] (route: Route?, error: NSError?) in
            self?.isRerouting = false
            completion(route, error)
        }
        
        routeTask = directions.calculate(options) {(waypoints, potentialRoutes, potentialError) in
            guard let routes = potentialRoutes else {
                complete(nil, potentialError)
                return
            }
            
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

