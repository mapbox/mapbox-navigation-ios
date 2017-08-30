import UIKit
import MapboxDirections

protocol RouteTableViewHeaderViewDelegate: class {
    func didTapCancel()
}

@IBDesignable
@objc(MBRouteTableViewHeaderView)
open class RouteTableViewHeaderView: UIView {
    
    @IBOutlet weak var progressBarWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var progressBar: ProgressBar!
    @IBOutlet weak var distanceRemainingLabel: DistanceRemainingLabel!
    @IBOutlet weak var timeRemainingLabel: TimeRemainingLabel!
    @IBOutlet weak var arrivalTimeLabel: ArrivalTimeLabel!
    @IBOutlet weak var dividerView: SeparatorView!
    
    weak var delegate: RouteTableViewHeaderViewDelegate?
    
    var congestionLevel: CongestionLevel = .unknown {
        didSet {
            switch congestionLevel {
            case .unknown:
                timeRemainingLabel.textColor = timeRemainingLabel.trafficUnknownColor
            case .low:
                timeRemainingLabel.textColor = timeRemainingLabel.trafficLowColor
            case .moderate:
                timeRemainingLabel.textColor = timeRemainingLabel.trafficModerateColor
            case .heavy:
                timeRemainingLabel.textColor = timeRemainingLabel.trafficHeavyColor
            case .severe:
                timeRemainingLabel.textColor = timeRemainingLabel.trafficSevereColor
            }
        }
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        
        //clear default values from the storyboard so user does not see a 'flash' of random values
        distanceRemainingLabel.text = ""
        timeRemainingLabel.text = ""
        arrivalTimeLabel.text = ""
    }
    
    override open var intrinsicContentSize: CGSize {
        get {
            return CGSize(width: bounds.width, height: 80)
        }
    }
    
    @IBAction func didTapCancel(_ sender: Any) {
        delegate?.didTapCancel()
    }
}
