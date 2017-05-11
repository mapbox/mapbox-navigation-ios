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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        turnArrowView.backgroundColor = .clear
    }
}
