import UIKit
import MapboxDirections
import MapboxCoreNavigation

class RouteTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: CellTitleLabel!
    @IBOutlet weak var subtitleLabel: CellSubtitleLabel!
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
            distanceFormatter.numberFormatter.locale = .nationalizedCurrent
            subtitleLabel.text = distanceFormatter.string(from: step.distance)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.alpha = 1
    }
}
