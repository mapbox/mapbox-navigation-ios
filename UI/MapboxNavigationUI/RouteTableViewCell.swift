import UIKit
import MapboxDirections

class RouteTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: StyleLabel!
    @IBOutlet weak var subtitleLabel: StyleLabel!
    @IBOutlet weak var turnArrowView: TurnArrowView!
    
    var step: RouteStep? {
        didSet {
            // TODO: Fix DistanceFormatter and RouteStepFormatter
        }
    }
    
}
