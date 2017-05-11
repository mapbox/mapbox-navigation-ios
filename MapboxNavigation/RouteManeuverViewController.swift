import UIKit
import MapboxDirections

class RouteManeuverViewController: UIViewController {

    @IBOutlet var separatorViews: [SeparatorView]!
    @IBOutlet weak var stackViewContainer: UIView!
    @IBOutlet fileprivate weak var distanceLabel: UILabel!
    @IBOutlet weak var streetLabel: UILabel!
    @IBOutlet weak var turnArrowView: TurnArrowView!
    @IBOutlet weak fileprivate var shieldImageView: UIImageView!
    @IBOutlet var laneViews: [LaneArrowView]!
    
    weak var step: RouteStep!
    
    var distanceText: String? {
        didSet {
            streetLabel.numberOfLines = distanceText != nil ? 1 : 2
            distanceLabel.text = distanceText
        }
    }
    
    var shieldImage: UIImage? {
        didSet {
            shieldImageView.image = shieldImage
        }
    }
    
    var isPagingThroughStepList = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        turnArrowView.backgroundColor = .clear
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
