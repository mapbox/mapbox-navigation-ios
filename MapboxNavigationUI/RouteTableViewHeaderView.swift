import UIKit

protocol RouteTableViewHeaderViewDelegate {
    func didTapCancel()
}

@IBDesignable
class RouteTableViewHeaderView: UIView {
    
    @IBOutlet weak var progressBarWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var progressBar: UIView!
    @IBOutlet weak var distanceRemaining: StyleLabel!
    @IBOutlet weak var timeRemaining: StyleLabel!
    @IBOutlet weak var etaLabel: StyleLabel!
    @IBOutlet weak var dividerView: UIView!
    
    var delegate: RouteTableViewHeaderViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        //clear default values from the storyboard so user does not see a 'flash' of random values
        distanceRemaining.text = ""
        timeRemaining.text = ""
        etaLabel.text = ""
        
        dividerView.backgroundColor = NavigationUI.shared.lineColor
    }
    
    override var intrinsicContentSize: CGSize {
        get {
            return CGSize(width: bounds.width, height: 80)
        }
    }
    
    // Set the progress between 0.0-1.0
    @IBInspectable
    var progress: CGFloat = 0 {
        didSet {
            if (progressBarWidthConstraint != nil) {
                progressBar.backgroundColor = NavigationUI.shared.tintColor
                progressBarWidthConstraint.constant = bounds.width * progress
                setNeedsUpdateConstraints()
            }
        }
    }
    
    @IBAction func didTapCancel(_ sender: Any) {
        delegate?.didTapCancel()
    }
}
