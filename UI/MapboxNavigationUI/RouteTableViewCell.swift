import UIKit
import MapboxDirections

class RouteTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: StyleLabel!
    @IBOutlet weak var subtitleLabel: StyleLabel!
    @IBOutlet weak var turnArrowView: TurnArrowView!
    
    let distanceFormatter = DistanceFormatter(approximate: true)
    let routeStepFormatter = RouteStepFormatter()
    
    var step: RouteStep? {
        didSet {
            turnArrowView.isHidden = step == nil
            guard let step = step else {
                return
            }
            
            turnArrowView.step = step
            titleLabel.text = routeStepFormatter.string(for: step)
            subtitleLabel.text = distanceFormatter.string(from: step.distance)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.alpha = 1
    }
}
