import UIKit
import MapboxDirections
import MapboxCoreNavigation

class StreetLabel: TitleLabel {
    typealias AvailableBoundsHandler = () -> (CGRect)
    var availableBounds: AvailableBoundsHandler!
    var unabridgedText: String? {
        didSet {
            super.text = unabridgedText?.abbreviated(toFit: availableBounds(), font: font)
        }
    }
}

class RouteManeuverViewController: UIViewController {
    @IBOutlet var separatorViews: [SeparatorView]!
    @IBOutlet weak var stackViewContainer: UIView!
    @IBOutlet fileprivate weak var distanceLabel: TitleLabel!
    @IBOutlet fileprivate weak var shieldImageView: UIImageView!
    @IBOutlet weak var turnArrowView: TurnArrowView!
    @IBOutlet weak var streetLabel: StreetLabel!
    @IBOutlet var laneViews: [LaneArrowView]!
    
    let distanceFormatter = DistanceFormatter(approximate: true)
    let routeStepFormatter = RouteStepFormatter()
    
    weak var step: RouteStep! {
        didSet {
            if isViewLoaded {
                updateStreetNameForStep()
            }
        }
    }
    
    var distance: CLLocationDistance? {
        didSet {
            if let distance = distance {
                distanceLabel.isHidden = false
                distanceLabel.text = distanceFormatter.string(from: distance)
                streetLabel.numberOfLines = 1
            } else {
                distanceLabel.isHidden = true
                distanceLabel.text = nil
                streetLabel.numberOfLines = 2
            }
        }
    }
    
    var shieldImage: UIImage? {
        didSet {
            shieldImageView.image = shieldImage
            updateStreetNameForStep()
        }
    }
    
    var availableStreetLabelBounds: CGRect {
        return CGRect(origin: .zero, size: maximumAvailableStreetLabelSize)
    }
    
    /** 
     Returns maximum available size for street label with padding, turnArrowView
     and shieldImage taken into account. Multiple lines will be used if distance
     is nil.
     
     width = | -8- TurnArrowView -8- availableWidth -8- shieldImage -8- |
     */
    var maximumAvailableStreetLabelSize: CGSize {
        get {
            let height = ("|" as NSString).size(attributes: [NSFontAttributeName: streetLabel.font]).height
            let lines: CGFloat = distance == nil ? 2 : 1
            let padding: CGFloat = 8*4
            return CGSize(width: view.bounds.width-padding-shieldImageView.bounds.size.width-turnArrowView.bounds.width, height: height*lines)
        }
    }
    
    var isPagingThroughStepList = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        turnArrowView.backgroundColor = .clear
        streetLabel.availableBounds = {[weak self] in CGRect(origin: .zero, size: self != nil ? self!.maximumAvailableStreetLabelSize : .zero) }
    }
    
    public func notifyDidChange(routeProgress: RouteProgress, secondsRemaining: TimeInterval) {
        let stepProgress = routeProgress.currentLegProgress.currentStepProgress
        let distanceRemaining = stepProgress.distanceRemaining
        
        distance = distanceRemaining > 10 ? distanceRemaining : nil
        
        if routeProgress.currentLegProgress.alertUserLevel == .arrive {
            distance = nil
            streetLabel.unabridgedText = routeStepFormatter.string(for: routeStepFormatter.string(for: routeProgress.currentLegProgress.upComingStep))
        } else if let upComingStep = routeProgress.currentLegProgress?.upComingStep {
            updateStreetNameForStep()
            showLaneView(step: upComingStep)
        }
        
        turnArrowView.step = routeProgress.currentLegProgress.upComingStep
    }
    
    public func updateStreetNameForStep() {
        if let name = step?.names?.first {
            streetLabel.unabridgedText = name
        } else if let destinations = step?.destinations?.joined(separator: "\n") {
            streetLabel.unabridgedText = destinations
        } else if let step = step {
            streetLabel.unabridgedText = routeStepFormatter.string(for: step)
        }
    }
    
    func showLaneView(step: RouteStep) {
        if let allLanes = step.intersections?.first?.approachLanes, let usableLanes = step.intersections?.first?.usableApproachLanes {
            for (i, lane) in allLanes.enumerated() {
                guard i < laneViews.count else {
                    return
                }
                stackViewContainer.isHidden = false
                let laneView = laneViews[i]
                laneView.isHidden = false
                laneView.lane = lane
                laneView.maneuverDirection = step.maneuverDirection
                laneView.isValid = usableLanes.contains(i as Int)
                laneView.setNeedsDisplay()
            }
        } else {
            stackViewContainer.isHidden = true
        }
    }
}
