import Foundation
import CoreLocation
import MapboxDirections



//:nodoc: See NavigationServiceDelegate.
@objc(MBRouterDelegate)
public protocol RouterDelegate: class {
    
    @objc(router:shouldRerouteFromLocation:)
    optional func router(_ router: Router, shouldRerouteFrom location: CLLocation) -> Bool

    @objc(router:willRerouteFromLocation:)
    optional func router(_ router: Router, willRerouteFrom location: CLLocation)
    
    @objc(router:shouldDiscardLocation:)
    optional func router(_ router: Router, shouldDiscard location: CLLocation) -> Bool

    @objc(router:didRerouteAlongRoute:at:proactive:)
    optional func router(_ router: Router, didRerouteAlong route: Route, at location: CLLocation?, proactive: Bool)

    @objc(router:didFailToRerouteWithError:)
    optional func router(_ router: Router, didFailToRerouteWith error: Error)
    
    @objc(router:didUpdateProgress:withLocation:rawLocation:)
    optional func router(_ router: Router, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation)
    
    @objc(router:didPassVisualInstructionPoint:routeProgress:)
    optional func router(_ router: Router, didPassVisualInstructionPoint instruction: VisualInstructionBanner, routeProgress: RouteProgress)
    
    @objc(router:didPassSpokenInstructionPoint:routeProgress:)
    optional func router(_ router: Router, didPassSpokenInstructionPoint instruction: SpokenInstruction, routeProgress: RouteProgress)
    
    @objc(router:willArriveAtWaypoint:in:distance:)
    optional func router(_ router: Router, willArriveAt waypoint: Waypoint, after remainingTimeInterval:TimeInterval, distance: CLLocationDistance)
    
    @objc(router:didArriveAtWaypoint:)
    optional func router(_ router: Router, didArriveAt waypoint: Waypoint) -> Bool
    
    @objc(router:shouldPreventReroutesWhenArrivingAtWaypoint:)
    optional func router(_ router: Router, shouldPreventReroutesWhenArrivingAt waypoint: Waypoint) -> Bool

    @objc(routerShouldDisableBatteryMonitoring:)
    optional func routerShouldDisableBatteryMonitoring(_ router: Router) -> Bool
}

