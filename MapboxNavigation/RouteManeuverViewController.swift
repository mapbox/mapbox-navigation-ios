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
                roadCode = step?.codes?.first ?? step?.destinationCodes?.first ?? step?.destinations?.first
                instructionsBannerView.turnArrowView.step = step
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
    
    var roadCode: String? {
        didSet {
            guard roadCode != oldValue, let components = roadCode?.components(separatedBy: " ") else {
                return
            }
            
            if components.count == 2 || (components.count == 3 && ["North", "South", "East", "West", "Nord", "Sud", "Est", "Ouest", "Norte", "Sur", "Este", "Oeste"].contains(components[2])) {
                
                let imageSizeMultiplier: CGFloat = 1.2
                
                let height = ("|" as NSString).size(attributes: [NSFontAttributeName: self.instructionsBannerView.primaryLabel.font]).height*UIScreen.main.scale*imageSizeMultiplier
                
                let network = components[0]
                let number = components[1]

                UIImage.shieldImage(network, number: number, height: height, completion: { (shieldImage) in
                    self.instructionsBannerView.primaryLabel.shieldImage = shieldImage
                })
                
            } else {
                //shieldImage = nil
            }
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
            
            let text = routeProgress.currentLeg.destination.name ?? routeStepFormatter.string(for: routeStepFormatter.string(for: routeProgress.currentLegProgress.upComingStep, legIndex: routeProgress.legIndex, numberOfLegs: routeProgress.route.legs.count, markUpWithSSML: false))
            instructionsBannerView.set(primary: text, secondary: nil)
            
        } else {
            updateStreetNameForStep()
        }

        instructionsBannerView.turnArrowView.step = routeProgress.currentLegProgress.upComingStep
    }
    
    func updateStreetNameForStep() {
        let text = visualInstructionFormatter.strings(leg: leg, step: step)
        instructionsBannerView.set(primary: text.0, secondary: text.1)
    }
}
