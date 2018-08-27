import Foundation
import MapboxCoreNavigation
import MapboxDirections

class NavigationServiceDelegateSpy: NavigationServiceDelegate {
    private(set) var recentMessages: [String] = []

    public func reset() {
        recentMessages.removeAll()
    }

    internal func navigationService(_ service: NavigationService, shouldRerouteFrom location: CLLocation) -> Bool {
        recentMessages.append(#function)
        return true
    }

    internal func navigationService(_ service: NavigationService, willRerouteFrom location: CLLocation) {
        recentMessages.append(#function)
    }

    internal func navigationService(_ service: NavigationService, shouldDiscard location: CLLocation) -> Bool {
        recentMessages.append(#function)
        return true
    }

    internal func navigationService(_ service: NavigationService, didRerouteAlong route: Route, at location: CLLocation?, proactive: Bool) {
        recentMessages.append(#function)
    }

    internal func navigationService(_ service: NavigationService, didFailToRerouteWith error: Error) {
        recentMessages.append(#function)
    }

    internal func navigationService(_ service: NavigationService, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        recentMessages.append(#function)
    }

    internal func navigationService(_ service: NavigationService, didArriveAt waypoint: Waypoint) -> Bool {
        recentMessages.append(#function)
        return true
    }
    
    internal func navigationService(_ service: NavigationService, shouldPreventReroutesWhenArrivingAt waypoint: Waypoint) -> Bool {
        recentMessages.append(#function)
        return true
    }
}
