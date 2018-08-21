import Foundation
import CoreLocation
import MapboxDirections

class TunnelAuthority {
    enum Constants {
        static let tunnelEntranceRadius: CLLocationDistance = 15
        static let minimumTunnelEntranceSpeed: CLLocationSpeed = 5
        static let validLocationThreshold: Int = 3
    }
    
    
    
    private var validExitUpdates: [CLLocation] = []
    private var currentlyInTunnel: Bool = false
    
    func isInTunnel(at location: CLLocation, along progress: RouteProgress) -> Bool {
        let currentStepProgress = progress.currentLegProgress.currentStepProgress
        guard let currentIntersection = currentStepProgress.currentIntersection else {
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
        guard let upcomingIntersection = currentStepProgress.upcomingIntersection,
            let roadClasses = upcomingIntersection.outletRoadClasses, roadClasses.contains(.tunnel),
            (location.speed >= Constants.minimumTunnelEntranceSpeed || !location.isQualified) else {
                return false
        }
        
        // Distance to the upcoming tunnel entrance
        guard let distanceToTunnelEntrance = currentStepProgress.userDistanceToUpcomingIntersection else { return false }
        
        let tunnelDetected = distanceToTunnelEntrance < Constants.tunnelEntranceRadius
        
        let state = (tunnelDetected, currentlyInTunnel)
        switch state {
        case (true, true): //we are progressing in the tunnel
            return true
        case (true, false): //we are entering the tunnel
            currentlyInTunnel = true
            return true
        case (false, false): //we're nowhere near a tunnel
            return false
        case (false, true): //we're just exiting a tunnel
            if validExitUpdates.count >= Constants.validLocationThreshold {
                //we've found enough valid location updates, lets offically exit
                validExitUpdates = []
                currentlyInTunnel = false
                return false
            } else {
                //we don't have enough valid updates yet
                if location.isQualified {
                    validExitUpdates.append(location)
                }
                return true //declare we're still in the tunnel, even though we're not
            }
         }
    }
}
