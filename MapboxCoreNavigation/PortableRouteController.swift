import Foundation
import MapboxNavigationNative
import MapboxDirections


@objc(MBPortableRouteController)
open class PortableRouteController: RouteController {
    
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
        assert(route.json != nil, "route.json missing, please verify the version of MapboxDirections.swift")
        
        let data = try! JSONSerialization.data(withJSONObject: route.json!, options: [])
        let jsonString = String(data: data, encoding: .utf8)!
        
        // TODO: Add support for alternative route
        navigator.setRouteForRouteResponse(jsonString, route: 0, leg: 0)
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
        locations.forEach { navigator.updateLocation(for: MBFixLocation($0)) }
        super.locationManager(manager, didUpdateLocations: locations)
    }
    
    override internal func userIsWithinRadiusOfRoute(location: CLLocation) -> Bool {
        let status = navigator.getStatusForTimestamp(location.timestamp)
        let offRoute = status.routeState == .offRoute
        return !offRoute
    }
    
    /**
     Advances the leg index. This override also advances the leg index of the native navigator.
     
     This is a convienence method provided to advance the leg index of any given router without having to worry about the internal data structure of the router.
     */
    override public func advanceLegIndex(location: CLLocation) {
        super.advanceLegIndex(location: location)
        
        let status = navigator.getStatusForTimestamp(location.timestamp)
        let routeIndex = status.routeIndex

        //The first route is the active one in the navigator.
        navigator.changeRouteLeg(forRoute: routeIndex, leg: UInt32(routeProgress.legIndex))
    }
    
    public func enableLocationRecording() {
        navigator.toggleHistoryFor(onOff: true)
    }
    
    public func disableLocationRecording() {
        navigator.toggleHistoryFor(onOff: false)
    }
    
    public func locationHistory() -> String {
        return navigator.getHistory()
    }
}
