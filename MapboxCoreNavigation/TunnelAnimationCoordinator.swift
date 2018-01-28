import Foundation
import CoreLocation
import Turf

public struct TunnelAnimationCoordinator {
    
    public var tunnelGeometry: Polyline?
    public let tunnelLength: CLLocationDistance = 500 // WIP / placeholder
    
    init(_ tunnelGeom: Polyline? = nil) {
        tunnelGeometry = tunnelGeom
    }
    
    public func isWithinMinimumSpeed(_ speed: CLLocationSpeed) -> Bool {
        return speed > RouteControllerMinimumSpeedForTunnelAnimation
    }
    
    public func containsIdenticalCongestions(for congestions:[RouteProgress.TimedCongestionLevel]) -> Bool {
        guard let firstCongestion = congestions.first else { return false }
        for congestion in congestions {
            if congestion.0 != firstCongestion.0 {
                return false
            }
        }
        return true
    }
    
    public func totalTravelTime(for congestions:[RouteProgress.TimedCongestionLevel]) -> TimeInterval {
        let tunnelTravelTime = congestions.reduce(0, { (result, congestionTimeInfo) -> TimeInterval in
            let (_ , timeInterval) = congestionTimeInfo
            return result + timeInterval
        })
        return tunnelTravelTime
    }
    
    public func congestions(for routeProgress: RouteProgress, start startIndex: Int, end endIndex: Int) -> [RouteProgress.TimedCongestionLevel]? {
        let congestionTravelTimesSegmentsByStep = routeProgress.congestionTravelTimesSegmentsByStep[routeProgress.legIndex][routeProgress.currentLegProgress.stepIndex]
        
        guard startIndex > -1 && endIndex < congestionTravelTimesSegmentsByStep.count else {
            return nil
        }
        
        return Array(routeProgress.congestionTravelTimesSegmentsByStep[routeProgress.legIndex][routeProgress.currentLegProgress.stepIndex][startIndex..<endIndex])
    }

}


