import MapboxCoreNavigation
import MapboxNavigation
import MapboxMaps
import MapboxDirections

extension ViewController: InstructionsCardCollectionDelegate {
    
    public func instructionsCardCollection(_ instructionsCardCollection: InstructionsCardViewController,
                                           didPreview step: RouteStep) {
        // Find the leg that contains the step, legIndex, and stepIndex.
        guard let route = instructionsCardCollection.routeProgress?.route,
              let leg = route.legs.first(where: { $0.steps.contains(step) }),
              let legIndex = route.legs.firstIndex(of: leg),
              let stepIndex = leg.steps.firstIndex(of: step) else {
                  return
              }
        
        // Find the upcoming manuever step, and update instructions banner to show preview
        guard stepIndex + 1 < leg.steps.endIndex,
              let navigationMapView = activeNavigationViewController?.navigationMapView else { return }
        let maneuverStep = leg.steps[stepIndex + 1]
        
        // Stop tracking user, and move camera to step location.
        navigationMapView.navigationCamera.stop()
        
        let cameraOptions = CameraOptions(center: maneuverStep.maneuverLocation,
                                          zoom: navigationMapView.mapView.cameraState.zoom,
                                          bearing: maneuverStep.initialHeading)
        navigationMapView.mapView.camera.ease(to: cameraOptions, duration: 1.0)
        
        // Add arrow to map for preview instruction.
        navigationMapView.addArrow(route: route,
                                   legIndex: legIndex,
                                   stepIndex: stepIndex + 1)
    }
}

extension ViewController: InstructionsCardContainerViewDelegate {
    
    public func primaryLabel(_ primaryLabel: InstructionLabel,
                             willPresent instruction: VisualInstruction,
                             as presented: NSAttributedString) -> NSAttributedString? {
        let updatedPrimaryLabel = NSMutableAttributedString(attributedString: presented)
        updatedPrimaryLabel.addAttribute(.backgroundColor,
                                         value: UIColor.blue,
                                         range: NSMakeRange(0, presented.length))
        
        return updatedPrimaryLabel
    }
    
    public func secondaryLabel(_ secondaryLabel: InstructionLabel,
                               willPresent instruction: VisualInstruction,
                               as presented: NSAttributedString) -> NSAttributedString? {
        let updatedSecondaryLabel = NSMutableAttributedString(attributedString: presented)
        updatedSecondaryLabel.addAttribute(.backgroundColor,
                                           value: UIColor.red,
                                           range: NSMakeRange(0, presented.length))
        
        return updatedSecondaryLabel
    }
}
