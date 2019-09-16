import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

/// :nodoc:
extension ViewController: InstructionsCardCollectionDelegate {
    
    public func instructionsCardCollection(_ instructionsCardCollection: InstructionsCardViewController, didPreview step: RouteStep) {
        
        guard let route = routes?.first else { return }
        
        // find the leg that contains the step, legIndex, and stepIndex
        guard let leg = route.legs.first(where: { $0.steps.contains(step) }),
            let legIndex = route.legs.firstIndex(of: leg),
            let stepIndex = leg.steps.firstIndex(of: step) else {
                return
        }
        
        // find the upcoming manuever step, and update instructions banner to show preview
        guard stepIndex + 1 < leg.steps.endIndex, let mapView = activeNavigationViewController?.mapView else { return }
        let maneuverStep = leg.steps[stepIndex + 1]
        
        // stop tracking user, and move camera to step location
        mapView.tracksUserCourse = false
        mapView.userTrackingMode = .none
        mapView.enableFrameByFrameCourseViewTracking(for: 1)
        mapView.setCenter(maneuverStep.maneuverLocation, zoomLevel: mapView.zoomLevel, direction: maneuverStep.initialHeading!, animated: true, completionHandler: nil)
        
        // add arrow to map for preview instruction
        mapView.addArrow(route: route, legIndex: legIndex, stepIndex: stepIndex + 1)
    }
    
    public func primaryLabel(_ primaryLabel: InstructionLabel, willPresent instruction: VisualInstruction, as presented: NSAttributedString) -> NSAttributedString? {
        // Override to customize the primary label displayed on the visible instructions card.
        return nil
    }
}
