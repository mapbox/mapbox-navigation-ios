import UIKit
import Mapbox
import MapboxNavigation
import MapboxDirections
import SDWebImage

var ShieldImageNamesByPrefix: [String: String] = {
    guard let plistPath = Bundle.navigationUI.path(forResource: "Shields", ofType: "plist") else {
        return [:]
    }
    return NSDictionary(contentsOfFile: plistPath) as! [String: String]
}()

class RouteMapViewController: UIViewController {

    @IBOutlet weak var mapView: MGLMapView!
    @IBOutlet weak var recenterButton: UIButton!
    
    let distanceFormatter = DistanceFormatter(approximate: true)
    var pageViewController: RoutePageViewController!
    weak var routeController: RouteController!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier ?? "" {
        case "RoutePageViewController":
            if let controller = segue.destination as? RoutePageViewController {
                pageViewController = controller
                controller.maneuverDelegate = self
            }
        default:
            break
        }
    }
}

extension RouteMapViewController: MGLMapViewDelegate {
    
}

extension RouteMapViewController: RoutePageViewControllerDelegate {
    func routePageViewController(_ controller: RoutePageViewController, willTransitionTo maneuverViewController: RouteManeuverViewController) {
        let step = maneuverViewController.step
        let destinations = step?.destinations?.joined(separator: "\n")
        
        maneuverViewController.streetLabel.text = step?.names?.first ?? destinations
        // TODO: Fix distance formatter
        maneuverViewController.distanceLabel.text = distanceFormatter.string(from: step!.distance)
        maneuverViewController.turnArrowView.step = step
        
        if let allLanes = step?.intersections?.first?.approachLanes, let usableLanes = step?.intersections?.first?.usableApproachLanes {
            for (i, lane) in allLanes.enumerated() {
                guard i < maneuverViewController.laneViews.count else {
                    return
                }
                let laneView = maneuverViewController.laneViews[i]
                laneView.isHidden = false
                laneView.lane = lane
                laneView.maneuverDirection = step?.maneuverDirection
                laneView.isValid = usableLanes.contains(i as Int)
                laneView.setNeedsDisplay()
            }
        } else {
            maneuverViewController.stackViewContainer.isHidden = true
        }
        
        if routeController.routeProgress.currentLegProgress.isCurrentStep(step!) {
            mapView.userTrackingMode = .followWithCourse
        } else {
            mapView.setCenter(step!.maneuverLocation, zoomLevel: mapView.zoomLevel, direction: step!.initialHeading!, animated: true, completionHandler: nil)
        }
    }

    func stepBefore(_ step: RouteStep) -> RouteStep? {
        return routeController.routeProgress.currentLegProgress.stepBefore(step)
    }

    func stepAfter(_ step: RouteStep) -> RouteStep? {
        return routeController.routeProgress.currentLegProgress.stepAfter(step)
    }
    
    func currentStep() -> RouteStep {
        return routeController.routeProgress.currentLegProgress.currentStep
    }
}
