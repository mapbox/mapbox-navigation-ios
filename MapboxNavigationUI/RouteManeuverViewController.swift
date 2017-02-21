import UIKit
import MapboxDirections

class RouteManeuverViewController: UIViewController {

    @IBOutlet weak var stackViewContainer: UIView!
    @IBOutlet weak var instructionsView: UIView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var streetLabel: UILabel!
    @IBOutlet weak var turnArrowView: TurnArrowView!
    @IBOutlet var laneViews: [LaneArrowView]!
    
    weak var step: RouteStep!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        instructionsView.applyDefaultCornerRadiusShadow()
        stackViewContainer.applyDefaultCornerRadiusShadow()
        turnArrowView.showsShield = false
    }

}
