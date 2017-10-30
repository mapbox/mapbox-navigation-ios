import UIKit
import MapboxDirections
import MapboxCoreNavigation
import SDWebImage

class RouteManeuverViewController: UIViewController {
    
    @IBOutlet weak var instructionsBannerView: InstructionsBannerView!
    
    let routeStepFormatter = RouteStepFormatter()
    let visualInstructionFormatter = VisualInstructionFormatter()
    
    var step: RouteStep? {
        didSet {
            if isViewLoaded {
                instructionsBannerView.maneuverView.step = step
                updateStreetNameForStep()
            }
        }
    }
    
    var leg: RouteLeg? {
        didSet {
            if isViewLoaded {
                updateStreetNameForStep()
            }
        }
    }
    
    var distance: CLLocationDistance? {
        didSet {
            instructionsBannerView.distance = distance
        }
    }
    
    var shieldAPIDataTask: URLSessionDataTask?
    var shieldImageDownloadToken: SDWebImageDownloadToken?
    let webImageManager = SDWebImageManager.shared()
    
    func notifyDidChange(routeProgress: RouteProgress, secondsRemaining: TimeInterval) {
        let stepProgress = routeProgress.currentLegProgress.currentStepProgress
        let distanceRemaining = stepProgress.distanceRemaining

        distance = distanceRemaining > 5 ? distanceRemaining : 0

        if routeProgress.currentLegProgress.userHasArrivedAtWaypoint {
            distance = nil
            
            if let text = routeProgress.currentLeg.destination.name ?? routeStepFormatter.string(for: routeStepFormatter.string(for: routeProgress.currentLegProgress.upComingStep, legIndex: routeProgress.legIndex, numberOfLegs: routeProgress.route.legs.count, markUpWithSSML: false)) {
                instructionsBannerView.set(Instruction(text), secondaryInstruction: nil)
            }
            
        } else {
            updateStreetNameForStep()
        }

        instructionsBannerView.maneuverView.step = routeProgress.currentLegProgress.upComingStep
    }
    
    func updateStreetNameForStep() {
        let instructions = visualInstructionFormatter.instructions(leg: leg, step: step)
        instructionsBannerView.set(instructions.0, secondaryInstruction: instructions.1)
    }
}
