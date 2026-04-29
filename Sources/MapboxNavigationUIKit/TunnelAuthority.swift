import CoreLocation
import Foundation
import MapboxDirections
import MapboxNavigationCore

struct TunnelAuthority {
    enum Constants {
        static let tunnelEntranceRadius: CLLocationDistance = 15
        static let minimumTunnelEntranceSpeed: CLLocationSpeed = 5
        static let validLocationThreshold: Int = 3
        static let minimumAdjacentSurfaceRoadLength: CLLocationDistance = 500
    }

    let isInTunnel: (CLLocation, RouteProgress) -> Bool
}

extension TunnelAuthority {
    static var liveValue: Self {
        .init { location, progress in
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
            if let upcomingIntersection = currentStepProgress.upcomingIntersection,
               let outletRoadClasses = upcomingIntersection.outletRoadClasses,
               outletRoadClasses.contains(.tunnel)
            {
                // If we are entering sufficiently fast and we are either within the
                // tunnel entrance radius or the location is not qualified
                if location.speed >= Constants.minimumTunnelEntranceSpeed,
                   let distanceToTunnel = currentStepProgress.userDistanceToUpcomingIntersection,
                   distanceToTunnel <= Constants.tunnelEntranceRadius || !location.isQualified
                {
                    return true
                }

                // If the next intersection is a tunnel and distance between
                // intersections is suffiently short
                let distanceToUpcomingTunnel = currentIntersection.location.distance(to: upcomingIntersection.location)
                if distanceToUpcomingTunnel < Constants.minimumAdjacentSurfaceRoadLength {
                    return true
                }
            }

            return false
        }
    }
}
