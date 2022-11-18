import Foundation
import MapboxCoreNavigation
import CoreLocation
import MapboxDirections

public final class RouterDelegateSpy: RouterDelegate {
    public var onDidRefresh: ((RouteProgress) -> Void)?
    public var onShouldRerouteFrom: ((CLLocation) -> Bool)?
    public var onShouldProactivelyRerouteFrom: ((CLLocation, Route) -> Bool)?
    public var onWillRerouteFrom: ((CLLocation) -> Void)?
    public var onModifiedOptionsForReroute: ((RouteOptions) -> RouteOptions)?
    public var onShouldDiscard: ((CLLocation) -> Bool)?
    public var onDidRerouteAlong: (((route: Route, location: CLLocation?, proactive: Bool)) -> Void)?
    public var onDidFailToRerouteWith: ((Error) -> Void)?
    public var onDidUpdate: (((progress: RouteProgress, location: CLLocation, rawLocation: CLLocation)) -> Void)?
    public var onDidPassVisualInstructionPoint: ((VisualInstructionBanner, RouteProgress) -> Void)?
    public var onDidPassSpokenInstructionPoint: ((SpokenInstruction, RouteProgress) -> Void)?
    public var onWillArriveAt: (((_: Waypoint,
                                  remainingTimeInterval: TimeInterval,
                                  distance: CLLocationDistance)) -> Void)?
    public var onDidArriveAt: ((Waypoint) -> Bool)?
    public var onShouldPreventReroutesWhenArrivingAt: ((Waypoint) -> Bool)?
    public var onRouterShouldDisableBatteryMonitoring: (() -> Bool)?
    public var onDidUpdateAlternativeRoutes: (([AlternativeRoute], [AlternativeRoute]) -> Void)?
    public var onDidFailToUpdateAlternativeRoutes: ((AlternativeRouteError) -> Void)?
    public var onWillTakeAlternativeRoute: ((Route, CLLocation?) -> Void)?
    public var onDidTakeAlternativeRoute: ((CLLocation?) -> Void)?
    public var onDidFailToTakeAlternativeRoute: ((CLLocation?) -> Void)?
    public var onDidSwitchToCoincideRoute: ((Route) -> Void)?
    
    public init() {}

    public func router(_ router: Router, didRefresh routeProgress: RouteProgress) {
        onDidRefresh?(routeProgress)
    }

    public func router(_ router: Router,
                       shouldRerouteFrom location: CLLocation) -> Bool {
        return onShouldRerouteFrom?(location) ?? RouteController.DefaultBehavior.shouldRerouteFromLocation
    }

    public func router(_ router: Router, shouldProactivelyRerouteFrom location: CLLocation, to route: Route, completion: @escaping () -> Void) {
        if onShouldProactivelyRerouteFrom?(location, route) ?? RouteController.DefaultBehavior.shouldProactivelyRerouteFromLocation {
            completion()
        }
    }
    
    public func router(_ router: Router,
                       willRerouteFrom location: CLLocation) {
        onWillRerouteFrom?(location)
    }
    
    public func router(_ router: Router, modifiedOptionsForReroute options: RouteOptions) -> RouteOptions {
        return onModifiedOptionsForReroute?(options) ?? options
    }
    
    public func router(_ router: Router,
                       shouldDiscard location: CLLocation) -> Bool {
        return onShouldDiscard?(location) ?? RouteController.DefaultBehavior.shouldDiscardLocation
    }

    public func router(_ router: Router,
                       didRerouteAlong route: Route,
                       at location: CLLocation?,
                       proactive: Bool) {
        onDidRerouteAlong?((route: route, location: location, proactive: proactive))
    }

    public func router(_ router: Router,
                       didFailToRerouteWith error: Error) {
        onDidFailToRerouteWith?(error)
    }

    public func router(_ router: Router,
                       didUpdate progress: RouteProgress,
                       with location: CLLocation,
                       rawLocation: CLLocation) {
        onDidUpdate?((progress: progress, location: location, rawLocation: rawLocation))
    }

    public func router(_ router: Router,
                       didPassVisualInstructionPoint instruction: VisualInstructionBanner,
                       routeProgress: RouteProgress) {
        onDidPassVisualInstructionPoint?(instruction, routeProgress)
    }

    public func router(_ router: Router,
                       didPassSpokenInstructionPoint instruction: SpokenInstruction,
                       routeProgress: RouteProgress) {
        onDidPassSpokenInstructionPoint?(instruction, routeProgress)
    }

    public func router(_ router: Router,
                       willArriveAt waypoint: Waypoint,
                       after remainingTimeInterval: TimeInterval,
                       distance: CLLocationDistance) {
        onWillArriveAt?((waypoint, remainingTimeInterval: remainingTimeInterval, distance: distance))
    }

    public func router(_ router: Router,
                       didArriveAt waypoint: Waypoint) -> Bool {
        return onDidArriveAt?(waypoint) ?? RouteController.DefaultBehavior.didArriveAtWaypoint
    }

    public func router(_ router: Router,
                       shouldPreventReroutesWhenArrivingAt waypoint: Waypoint) -> Bool {
        return onShouldPreventReroutesWhenArrivingAt?(waypoint) ??
            RouteController.DefaultBehavior.shouldPreventReroutesWhenArrivingAtWaypoint
    }

    public func routerShouldDisableBatteryMonitoring(_ router: Router) -> Bool {
        return onRouterShouldDisableBatteryMonitoring?() ??
            RouteController.DefaultBehavior.shouldDisableBatteryMonitoring
    }
    
    public func router(_ router: Router, didUpdateAlternatives updatedAlternatives: [AlternativeRoute], removedAlternatives: [AlternativeRoute]) {
        onDidUpdateAlternativeRoutes?(updatedAlternatives, removedAlternatives)
    }
    
    public func router(_ router: Router, didFailToUpdateAlternatives error: AlternativeRouteError) {
        onDidFailToUpdateAlternativeRoutes?(error)
    }
    
    public func router(_ router: Router, willTakeAlternativeRoute route: Route, at location: CLLocation?) {
        onWillTakeAlternativeRoute?(route, location)
    }
    
    public func router(_ router: Router, didTakeAlternativeRouteAt location: CLLocation?) {
        onDidTakeAlternativeRoute?(location)
    }
    
    public func router(_ router: Router, didFailToTakeAlternativeRouteAt location: CLLocation?) {
        onDidFailToTakeAlternativeRoute?(location)
    }
    
    public func router(_ router: Router, didSwitchToCoincidentOnlineRoute coincideRoute: Route) {
        onDidSwitchToCoincideRoute?(coincideRoute)
    }
}
