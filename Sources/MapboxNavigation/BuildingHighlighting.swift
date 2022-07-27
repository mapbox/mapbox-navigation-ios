import CoreLocation
import MapboxDirections
import MapboxCoreNavigation

protocol BuildingHighlighting: AnyObject {
    
    var waypointStyle: WaypointStyle { get set }
    
    var approachingDestinationThreshold: CLLocationDistance { get set }
    
    var passedApproachingDestinationThreshold: Bool { get set }
    
    var currentLeg: RouteLeg? { get set }
    
    var buildingWasFound: Bool { get set }
    
    func attemptToHighlightBuildings(_ progress: RouteProgress,
                                     navigationMapView: NavigationMapView?,
                                     completion: ((_ success: Bool) -> Void)?)
}

extension BuildingHighlighting {
    
    func attemptToHighlightBuildings(_ progress: RouteProgress,
                                     navigationMapView: NavigationMapView?,
                                     completion: ((_ success: Bool) -> Void)? = nil) {
        // In case if distance was fully covered - do nothing.
        guard let navigationMapView = navigationMapView,
              progress.fractionTraveled < 1.0,
              waypointStyle != .annotation else {
                  completion?(false)
                  return
              }
        
        // In case if current `RouteProgress` has different `RouteLeg` - reset previously
        // remembered information.
        if currentLeg != progress.currentLeg {
            currentLeg = progress.currentLeg
            passedApproachingDestinationThreshold = false
            buildingWasFound = false
        }
        
        // In case if remaining distance on current `RouteLeg` is lower than certain threshold
        // value - remember it.
        if !passedApproachingDestinationThreshold,
           progress.currentLegProgress.distanceRemaining < approachingDestinationThreshold {
            passedApproachingDestinationThreshold = true
        }
        
        // In case if not all buildings were found and user is within allowed destination
        // threshold - attempt to highlight buildings based on destination coordinate.
        if !buildingWasFound, passedApproachingDestinationThreshold,
           let currentLegWaypoint = progress.currentLeg.destination?.targetCoordinate {
            navigationMapView.highlightBuildings(at: [currentLegWaypoint],
                                                 in3D: waypointStyle == .extrudedBuilding ? true : false,
                                                 completion: { found in
                self.buildingWasFound = found
                completion?(found)
            })
        }
    }
}
