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
    
    var delegate: RouteTableViewHeaderViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        progressBar.backgroundColor = NavigationUI.shared.tintColor
    }
    
    override var intrinsicContentSize: CGSize {
        get {
            return CGSize(width: bounds.width, height: 106)
        }
    }
    
    // Set the progress between 0.0-1.0
    @IBInspectable
    var progress: CGFloat = 0 {
        didSet {
            if (progressBarWidthConstraint != nil) {
                progressBarWidthConstraint.constant = bounds.width * progress
                setNeedsUpdateConstraints()
            }
        }
    }
    
    @IBAction func didTapCancel(_ sender: Any) {
        delegate?.didTapCancel()
    }
}
