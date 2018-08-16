import Foundation
import MapboxCoreNavigation
import MapboxDirections

class NavigationServiceDelegateSpy: NavigationServiceDelegate {
    private(set) var recentMessages: [String] = []

    public func reset() {
        recentMessages.removeAll()
    }

    internal func routeController(_ routeController: RouteController, shouldRerouteFrom location: CLLocation) -> Bool {
        recentMessages.append(#function)
        return true
    }

    internal func routeController(_ routeController: RouteController, willRerouteFrom location: CLLocation) {
        recentMessages.append(#function)
    }

    internal func routeController(_ routeController: RouteController, shouldDiscard location: CLLocation) -> Bool {
        recentMessages.append(#function)
        return true
    }

    internal func routeController(_ routeController: RouteController, didRerouteAlong route: Route, at location: CLLocation?, proactive: Bool) {
        recentMessages.append(#function)
    }

    internal func routeController(_ routeController: RouteController, didFailToRerouteWith error: Error) {
        recentMessages.append(#function)
    }

    internal func routeController(_ routeController: RouteController, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        recentMessages.append(#function)
    }

    internal func routeController(_ routeController: RouteController, didArriveAt waypoint: Waypoint) -> Bool {
        recentMessages.append(#function)
        return true
    }
    
    internal func routeController(_ routeController: RouteController, shouldPreventReroutesWhenArrivingAt waypoint: Waypoint) -> Bool {
        recentMessages.append(#function)
        return true
    }
}
