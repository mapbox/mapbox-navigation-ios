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

    public var returnedShouldReroute = true
    public var returnedShouldDiscard = false
    public var returnedShouldPreventReroutesWhenArrivingAt = true
    public var returnedDidArrive = true
    public var returnedShouldDisableBatteryMonitoring = true

    public var passedLocation: CLLocation?
    public var passedWaypoint: Waypoint?

    public func reset() {
        recentMessages.removeAll()
    }

    public func navigationService(_ service: NavigationService, shouldRerouteFrom location: CLLocation) -> Bool {
        recentMessages.append(#function)
        passedLocation = location
        return returnedShouldReroute
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
        passedLocation = location
        return returnedShouldDiscard
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
        passedWaypoint = waypoint
        recentMessages.append(#function)
    }
    
    public func navigationService(_ service: NavigationService, didArriveAt waypoint: Waypoint) -> Bool {
        recentMessages.append(#function)
        passedWaypoint = waypoint
        return returnedDidArrive
    }
    
    public func navigationService(_ service: NavigationService, shouldPreventReroutesWhenArrivingAt waypoint: Waypoint) -> Bool {
        passedWaypoint = waypoint
        recentMessages.append(#function)
        return returnedShouldPreventReroutesWhenArrivingAt
    }

    public func navigationService(_ service: NavigationService, willEndSimulating progress: RouteProgress, becauseOf reason: SimulationIntent) {
        recentMessages.append(#function)
    }

    public func navigationService(_ service: NavigationService, didEndSimulating progress: RouteProgress, becauseOf reason: SimulationIntent) {
        recentMessages.append(#function)
    }

    public func navigationService(_ service: NavigationService, willBeginSimulating progress: RouteProgress, becauseOf reason: SimulationIntent) {
        recentMessages.append(#function)
    }

    public func navigationService(_ service: NavigationService, didBeginSimulating progress: RouteProgress, becauseOf reason: SimulationIntent) {
        recentMessages.append(#function)
    }

    public func navigationService(_ service: NavigationService, didRefresh routeProgress: RouteProgress) {
        recentMessages.append(#function)
    }

    public func navigationService(_ service: NavigationService,
                                  didPassVisualInstructionPoint instruction: VisualInstructionBanner,
                                  routeProgress: RouteProgress) {
        recentMessages.append(#function)
    }

    public func navigationService(_ service: NavigationService,
                                  didPassSpokenInstructionPoint instruction: SpokenInstruction,
                                  routeProgress: RouteProgress) {
        recentMessages.append(#function)
    }

    public func navigationServiceShouldDisableBatteryMonitoring(_ service: NavigationService) -> Bool {
        recentMessages.append(#function)
        return returnedShouldDisableBatteryMonitoring
    }

    public func navigationService(_ service: NavigationService,
                                  didUpdateAlternatives updatedAlternatives: [AlternativeRoute],
                                  removedAlternatives: [AlternativeRoute]) {
        recentMessages.append(#function)
    }

    public func navigationService(_ service: NavigationService, didSwitchToCoincidentOnlineRoute coincideRoute: Route) {
        recentMessages.append(#function)
    }

    public func navigationService(_ service: NavigationService, willTakeAlternativeRoute route: Route, at location: CLLocation?) {
        recentMessages.append(#function)
    }

    public func navigationService(_ service: NavigationService, didTakeAlternativeRouteAt location: CLLocation?) {
        recentMessages.append(#function)
    }

    public func navigationService(_ service: NavigationService, didFailToTakeAlternativeRouteAt location: CLLocation?) {
        recentMessages.append(#function)
    }

    public func navigationService(_ service: NavigationService, didFailToUpdateAlternatives error: AlternativeRouteError) {
        recentMessages.append(#function)
    }

    public func navigationServiceDidChangeAuthorization(_ service: NavigationService, didChangeAuthorizationFor locationManager: CLLocationManager) {
        recentMessages.append(#function)
    }
}
