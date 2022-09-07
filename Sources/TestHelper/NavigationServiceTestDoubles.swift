import Foundation
import CoreLocation
import MapboxCoreNavigation
import MapboxDirections
import Turf

public class RouteControllerDataSourceFake: RouterDataSource {
    let manager = NavigationLocationManager()

    public var location: CLLocation? {
        return manager.location
    }

    public var locationManagerType: NavigationLocationManager.Type {
        return type(of: manager)
    }
}

public class NavigationServiceDelegateSpy: NavigationServiceDelegate {
    private(set) var recentMessages: [String] = []

    public func reset() {
        recentMessages.removeAll()
    }

    public func navigationService(_ service: NavigationService, shouldRerouteFrom location: CLLocation) -> Bool {
        recentMessages.append(#function)
        return true
    }

    public func navigationService(_ service: NavigationService, willRerouteFrom location: CLLocation) {
        recentMessages.append(#function)
    }
    
    public func navigationService(_ service: NavigationService, modifiedOptionsForReroute options: RouteOptions) -> RouteOptions {
        recentMessages.append(#function)
        return options
    }
    
    public func navigationService(_ service: NavigationService, shouldDiscard location: CLLocation) -> Bool {
        recentMessages.append(#function)
        return false
    }

    public func navigationService(_ service: NavigationService, didRerouteAlong route: Route, at location: CLLocation?, proactive: Bool) {
        recentMessages.append(#function)
    }

    public func navigationService(_ service: NavigationService, didFailToRerouteWith error: Error) {
        recentMessages.append(#function)
    }

    public func navigationService(_ service: NavigationService, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        recentMessages.append(#function)
    }
    
    public func navigationService(_ service: NavigationService, willArriveAt waypoint: Waypoint, after remainingTimeInterval: TimeInterval, distance: CLLocationDistance) {
        recentMessages.append(#function)
    }
    
    public func navigationService(_ service: NavigationService, didArriveAt waypoint: Waypoint) -> Bool {
        recentMessages.append(#function)
        return true
    }
    
    public func navigationService(_ service: NavigationService, shouldPreventReroutesWhenArrivingAt waypoint: Waypoint) -> Bool {
        recentMessages.append(#function)
        return true
    }
}
