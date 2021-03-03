import MapboxCoreNavigation
import MapboxNavigation
import MapboxMaps
import MapboxDirections

extension ViewController: InstructionsCardCollectionDelegate {
    public func instructionsCardCollection(_ instructionsCardCollection: InstructionsCardViewController, didPreview step: RouteStep) {
        guard let route = response?.routes?.first else { return }
        
        // find the leg that contains the step, legIndex, and stepIndex
        guard let leg = route.legs.first(where: { $0.steps.contains(step) }),
            let legIndex = route.legs.firstIndex(of: leg),
            let stepIndex = leg.steps.firstIndex(of: step) else {
                return
        }
        
        // find the upcoming manuever step, and update instructions banner to show preview
        guard stepIndex + 1 < leg.steps.endIndex, let navigationMapView = activeNavigationViewController?.navigationMapView else { return }
        let maneuverStep = leg.steps[stepIndex + 1]
        
        // stop tracking user, and move camera to step location
        navigationMapView.navigationCamera.requestNavigationCameraToIdle()
        navigationMapView.enableFrameByFrameCourseViewTracking(for: 1)
        
        let camera = CameraOptions(center: maneuverStep.maneuverLocation,
                                   zoom: navigationMapView.mapView.zoom,
                                   bearing: maneuverStep.initialHeading!)
        navigationMapView.mapView.cameraManager.setCamera(to: camera, animated: true, duration: 1.0, completion: nil)
        
        // add arrow to map for preview instruction
        navigationMapView.addArrow(route: route, legIndex: legIndex, stepIndex: stepIndex + 1)
    }
    
    public func primaryLabel(_ primaryLabel: InstructionLabel, willPresent instruction: VisualInstruction, as presented: NSAttributedString) -> NSAttributedString? {
        // Override to customize the primary label displayed on the visible instructions card.
        return nil
    }
}
