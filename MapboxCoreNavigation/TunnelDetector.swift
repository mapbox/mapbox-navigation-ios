import Foundation
import CoreLocation

@objc(MBTunnelDetectorDelegate)
public protocol TunnelDetectorDelegate: class {
    
    @objc(tunnelDetector:didEnterTunnelAtLocation:)
    optional func tunnelDetector(_ tunnelDetector: TunnelDetector, didEnterTunnelAt location: CLLocation)
    
    @objc(tunnelDetector:didExitTunnelAtLocation:)
    optional func tunnelDetector(_ tunnelDetector: TunnelDetector, didExitTunnelAt location: CLLocation)
    
    @objc(tunnelDector:willEnableAnimationAtLocation:callback:)
    optional func tunnelDetector(_ tunnelDetector: TunnelDetector, willEnableAnimationAt location: CLLocation, callback: RouteControllerSimulationCompletionBlock?)
    
    @objc(tunnelDetector:willDisableAnimationAtLocation:callback:)
    optional func tunnelDetector(_ tunnelDetector: TunnelDetector, willDisableAnimationAt location: CLLocation, callback: RouteControllerSimulationCompletionBlock?)
}

@objc(MBTunnelDetector)
open class TunnelDetector: NSObject {
    
    @objc public weak var delegate: TunnelDetectorDelegate?
    
    @objc public var routeController: RouteController?
    
    @objc public var badLocationsUponExit: [CLLocation] = [CLLocation]()
    
    /**
     Given a user's current location and route progress,
     returns a Boolean whether a tunnel has been detected on the current route step progress.
     */
    @objc public func didDetectTunnel(at routeProgress: RouteProgress) -> Bool {
        if let currentIntersection = routeProgress.currentLegProgress.currentStepProgress.currentIntersection, let classes = currentIntersection.outletRoadClasses {
                return classes.contains(.tunnel)
        }
        return false
    }
    
    /**
     Given a user's current location, location manager and route progress,
     returns a Boolean whether a tunnel has been detected on the current route step progress.
     */
    @objc public func didDetectTunnel(at location: CLLocation, for manager: CLLocationManager, routeProgress: RouteProgress) -> Bool {
        
        guard let currentIntersection = routeProgress.currentLegProgress.currentStepProgress.currentIntersection else {
            return false
        }
        
        if let classes = currentIntersection.outletRoadClasses {
            // Main conditions to enable simulated tunnel animation:
            // - User location is within minimum tunnel entrance radius
            // - Current intersection's road classes contain a tunnel AND when we receive series of bad GPS location updates
           let isWithinTunnelEntranceRadius = userWithinTunnelEntranceRadius(at: location, routeProgress: routeProgress)
            if isWithinTunnelEntranceRadius || ((manager is NavigationLocationManager && !location.isQualified) && classes.contains(.tunnel)) {
                return true
            }
        }
        
        return false
    }
    
    /**
     Given a user's current location and the route progress,
     detects whether the upcoming intersection contains a tunnel road class, and
     returns a Boolean whether they are within the minimum radius of a tunnel entrance.
     */
    @objc public func userWithinTunnelEntranceRadius(at location: CLLocation, routeProgress: RouteProgress) -> Bool {
        // Ensure the upcoming intersection is a tunnel intersection
        // OR the location speed is either at least 5 m/s or is considered a bad location update
        guard let upcomingIntersection = routeProgress.currentLegProgress.currentStepProgress.upcomingIntersection, let roadClasses = upcomingIntersection.outletRoadClasses, roadClasses.contains(.tunnel), (location.speed >= RouteControllerMinimumSpeedAtTunnelEntranceRadius || !location.isQualified) else {
            return false
        }
        
        // Distance to the upcoming tunnel entrance
        guard let distanceToTunnelEntrance = routeProgress.currentLegProgress.currentStepProgress.userDistanceToUpcomingIntersection else { return false }
        
        return distanceToTunnelEntrance < RouteControllerMinimumDistanceToTunnelEntrance
    }
}
