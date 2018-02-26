
_Source available [here](https://github.com/mapbox/navigation-ios-examples/blob/master/Navigation-Examples/Examples/Custom-Voice-Controller.swift)_

```swift
import Foundation
import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import AVFoundation

class CustomVoiceControllerUI: UIViewController {
    
    var voiceController: CustomVoiceController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        voiceController = CustomVoiceController()
        
        let origin = CLLocationCoordinate2DMake(37.77440680146262, -122.43539772352648)
        let destination = CLLocationCoordinate2DMake(37.76556957793795, -122.42409811526268)
        let options = NavigationRouteOptions(coordinates: [origin, destination])
        
        Directions.shared.calculate(options) { (waypoints, routes, error) in
            guard let route = routes?.first, error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            let navigationController = NavigationViewController(for: route)
            navigationController.voiceController = self.voiceController
            
            // This allows the developer to simulate the route.
            // Note: If copying and pasting this code in your own project,
            // comment out `simulationIsEnabled` as it is defined elsewhere in this project.
            if simulationIsEnabled {
                navigationController.routeController.locationManager = SimulatedLocationManager(route: route)
            }
            
            self.present(navigationController, animated: true, completion: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        voiceController = nil
    }
}

class CustomVoiceController: MapboxVoiceController {
    
    // You will need audio files for as many or few cases as you'd like to handle
    // This example just covers left, right and straight.
    let turnLeft = NSDataAsset(name: "turnleft")!.data
    let turnRight = NSDataAsset(name: "turnright")!.data
    let straight = NSDataAsset(name: "continuestraight")!.data
    
    override func didPassSpokenInstructionPoint(notification: NSNotification) {
        let routeProgress = notification.userInfo![RouteControllerNotificationUserInfoKey.routeProgressKey] as! RouteProgress
        let soundForInstruction = audio(for: routeProgress.currentLegProgress.currentStep)
        play(soundForInstruction)
    }
    
    func audio(for step: RouteStep) -> Data {
        switch step.maneuverDirection {
        case .left:
            return turnLeft
        case .right:
            return turnRight
        default:
            return straight
        }
    }
}
```
