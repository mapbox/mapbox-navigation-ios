import Foundation
import CoreLocation

/**
 The `TunnelIntersectionManagerDelegate` protocol provides methods for responding to events where a user enters or exits a tunnel.
 */
@objc(MBTunnelIntersectionManagerDelegate)
public protocol TunnelIntersectionManagerDelegate: class {
    
    /**
     Called immediately when the location manager detects a tunnel on a route.
     
     - parameter manager: The location manager that currently sends the location updates.
     - parameter location: The user’s current location where the tunnel was detected.
     */
    @objc(tunnelIntersectionManager:willEnableAnimationAtLocation:)
    optional func tunnelIntersectionManager(_ manager: TunnelIntersectionManager, willEnableAnimationAt location: CLLocation)
    
    /**
     Called immediately when the location manager detects the user's current location is no longer within a tunnel.
     
     - parameter manager: The location manager that currently sends the location updates.
     - parameter location: The user’s current location where the tunnel was detected.
     */
    @objc(tunnelIntersectionManager:willDisableAnimationAtLocation:)
    optional func tunnelIntersectionManager(_ manager: TunnelIntersectionManager, willDisableAnimationAt location: CLLocation)
}

@objc(MBTunnelIntersectionManager)
open class TunnelIntersectionManager: NSObject {
    
    /**
     The associated delegate for tunnel intersection manager.
     */
    @objc public weak var delegate: TunnelIntersectionManagerDelegate?
    
    /**
     The simulated location manager dedicated to tunnel simulated navigation.
     */
    @objc public var animatedLocationManager: SimulatedLocationManager?
    
    /**
     An array of bad location updates recorded upon exit of a tunnel.
     */
    @objc public var tunnelExitLocations = [CLLocation]()
    
    /**
     The flag that indicates whether simulated location manager is initialized.
     */
    @objc private var isAnimationEnabled: Bool = false
    
    /**
     Flag indicating whether the user is animated through tunnels.
     */
    @objc public var tunnelSimulationEnabled: Bool = true
    
    func checkForTunnelIntersection(at location: CLLocation, routeProgress: RouteProgress) {
        guard tunnelSimulationEnabled else { return }
        
        let tunnelDetected = userWithinTunnelEntranceRadius(at: location, routeProgress: routeProgress)
        
        if tunnelDetected {
            delegate?.tunnelIntersectionManager?(self, willEnableAnimationAt: location)
        } else if isAnimationEnabled {
            delegate?.tunnelIntersectionManager?(self, willDisableAnimationAt: location)
        }
    }

    /**
     Given a user's current location and the route progress,
     detects whether the upcoming intersection contains a tunnel road class, and
     returns a Boolean whether they are within the minimum radius of a tunnel entrance.
     */
    @objc public func userWithinTunnelEntranceRadius(at location: CLLocation, routeProgress: RouteProgress) -> Bool {
        guard let currentIntersection = routeProgress.currentLegProgress.currentStepProgress.currentIntersection else {
            return false
        }
       
        // `currentIntersection` is basically the intersection that you have last passed through.
        // While the upcoming intersection is the one you will be approaching next.
        // The user is essentially always between the current and upcoming intersection.
        if let classes = currentIntersection.outletRoadClasses, classes.contains(.tunnel) {
            return true
        }
        
        // Ensure the upcoming intersection is a tunnel intersection
        // OR the location speed is either at least 5 m/s or is considered a bad location update
        guard let upcomingIntersection = routeProgress.currentLegProgress.currentStepProgress.upcomingIntersection,
            let roadClasses = upcomingIntersection.outletRoadClasses, roadClasses.contains(.tunnel),
            (location.speed >= RouteControllerMinimumSpeedAtTunnelEntranceRadius || !location.isQualified) else {
                return false
        }
        
        // Distance to the upcoming tunnel entrance
        guard let distanceToTunnelEntrance = routeProgress.currentLegProgress.currentStepProgress.userDistanceToUpcomingIntersection else { return false }
        
        return distanceToTunnelEntrance < RouteControllerMinimumDistanceToTunnelEntrance
    }
    
    @objc public func enableTunnelAnimation(routeController: RouteController, routeProgress: RouteProgress) {
        guard !isAnimationEnabled else { return }
        
        self.animatedLocationManager = SimulatedLocationManager(routeProgress: routeProgress)
        self.animatedLocationManager?.delegate = routeController
        self.animatedLocationManager?.routeProgress = routeProgress
        self.animatedLocationManager?.startUpdatingLocation()
        self.animatedLocationManager?.startUpdatingHeading()
        
        isAnimationEnabled = true
    }
    
    @objc public func suspendTunnelAnimation(at location: CLLocation, routeController: RouteController) {
        
        guard isAnimationEnabled else { return }
        
        // Disable the tunnel animation after at least 3 good location updates.
        if location.isQualified {
            tunnelExitLocations.append(location)
        }
        guard tunnelExitLocations.count >= 3 else {
            return
        }
        
        isAnimationEnabled = false
        
        animatedLocationManager?.stopUpdatingLocation()
        animatedLocationManager?.stopUpdatingHeading()
        animatedLocationManager = nil
        tunnelExitLocations.removeAll()
        
        routeController.rawLocation = location
    }
}
