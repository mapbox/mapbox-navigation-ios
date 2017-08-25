import UIKit

protocol RouteTableViewHeaderViewDelegate: class {
    func didTapCancel()
}

@IBDesignable
@objc(MBRouteTableViewHeaderView)
open class RouteTableViewHeaderView: UIView {
    
    @IBOutlet weak var progressBarWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var progressBar: ProgressBar!
    @IBOutlet weak var distanceRemaining: DistanceRemainingLabel!
    @IBOutlet weak var timeRemaining: TimeRemainingLabel!
    @IBOutlet weak var arrivalTimeLabel: ArrivalTimeLabel!
    @IBOutlet weak var dividerView: SeparatorView!
    
    weak var delegate: RouteTableViewHeaderViewDelegate?
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        
        //clear default values from the storyboard so user does not see a 'flash' of random values
        distanceRemaining.text = ""
        timeRemaining.text = ""
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
