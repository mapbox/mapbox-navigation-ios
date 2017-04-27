import UIKit
import MapboxDirections

class RouteManeuverViewController: UIViewController {

    @IBOutlet var separatorViews: [SeparatorView]!
    @IBOutlet weak var stackViewContainer: UIView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var streetLabel: UILabel!
    @IBOutlet weak var turnArrowView: TurnArrowView!
    @IBOutlet weak fileprivate var shieldImageView: UIImageView!
    @IBOutlet var laneViews: [LaneArrowView]!
    
    weak var step: RouteStep!
    
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
