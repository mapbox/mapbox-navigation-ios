import UIKit
import MapboxDirections
import MapboxCoreNavigation
import SDWebImage

class RouteManeuverViewController: UIViewController {
    
    @IBOutlet weak var instructionsBannerView: InstructionsBannerView!
    
    let distanceFormatter = DistanceFormatter(approximate: true)
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
            if let distance = distance {
                instructionsBannerView.distanceLabel.text = distanceFormatter.string(from: distance)
            } else {
                instructionsBannerView.distanceLabel.text = " "
            }
        }
    }
    
    var roadCode: String? {
        didSet {
            guard roadCode != oldValue, let components = roadCode?.components(separatedBy: " ") else {
                return
            }
            
            instructionsBannerView.primaryLabel.text = roadCode
            
            if components.count == 2 || (components.count == 3 && ["North", "South", "East", "West", "Nord", "Sud", "Est", "Ouest", "Norte", "Sur", "Este", "Oeste"].contains(components[2])) {
                // TODO: Set shield image
            } else {
                //shieldImage = nil
            }
        }
    }
    
//    var shieldImage: UIImage? {
//        didSet {
//            //shieldImageView.image = shieldImage
//            updateStreetNameForStep()
//        }
//    }
    
    var shieldAPIDataTask: URLSessionDataTask?
    var shieldImageDownloadToken: SDWebImageDownloadToken?
    let webImageManager = SDWebImageManager.shared()
    
    
//    var availableStreetLabelBounds: CGRect {
//        return CGRect(origin: .zero, size: maximumAvailableStreetLabelSize)
//    }
    
    /** 
     Returns maximum available size for street label with padding, turnArrowView and shieldImage taken into account. Multiple lines will be used if distance is nil.
     
     width = | -8- TurnArrowView -8- availableWidth -8- |
     */
    
//    var maximumAvailableStreetLabelSize: CGSize {
//        get {
//            let height = ("|" as NSString).size(attributes: [NSFontAttributeName: secondaryDestinationLabel.font]).height
//            let lines = CGFloat(numberOfDestinationLines)
//            let padding: CGFloat = 8*4
//            return CGSize(width: view.bounds.width-padding-turnArrowView.bounds.width, height: height*lines)
//        }
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        primaryDestinationLabel.availableBounds = {[weak self] in CGRect(origin: .zero, size: self != nil ? self!.maximumAvailableStreetLabelSize : .zero) }
//        secondaryDestinationLabel.availableBounds = {[weak self] in CGRect(origin: .zero, size: self != nil ? self!.maximumAvailableStreetLabelSize : .zero) }
    }
    
    func notifyDidChange(routeProgress: RouteProgress, secondsRemaining: TimeInterval) {
        let stepProgress = routeProgress.currentLegProgress.currentStepProgress
        let distanceRemaining = stepProgress.distanceRemaining

        distance = distanceRemaining > 5 ? distanceRemaining : 0

        if routeProgress.currentLegProgress.userHasArrivedAtWaypoint {
            distance = nil
            
            let text = routeProgress.currentLeg.destination.name ?? routeStepFormatter.string(for: routeStepFormatter.string(for: routeProgress.currentLegProgress.upComingStep, legIndex: routeProgress.legIndex, numberOfLegs: routeProgress.route.legs.count, markUpWithSSML: false))
            instructionsBannerView.secondaryLabel.text = text
        } else {
            updateStreetNameForStep()
        }

        instructionsBannerView.turnArrowView.step = routeProgress.currentLegProgress.upComingStep
    }
    
    func updateStreetNameForStep() {
        instructionsBannerView.secondaryLabel.text = visualInstructionFormatter.string(leg: leg, step: step)
    }
}
