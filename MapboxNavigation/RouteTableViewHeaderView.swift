import UIKit

protocol RouteTableViewHeaderViewDelegate: class {
    func didTapCancel()
}

@IBDesignable
class RouteTableViewHeaderView: UIView {
    
    @IBOutlet weak var progressBarWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var progressBar: ProgressBar!
    
    @IBOutlet weak var timeRemainingLabel: HeaderTitleLabel!
    @IBOutlet weak var timeUnitLabel: HeaderSubtitleLabel!
    
    @IBOutlet weak var etaLabel: HeaderTitleLabel!
    @IBOutlet weak var etaUnitLabel: HeaderSubtitleLabel!
    
    @IBOutlet weak var distanceRemainingLabel: HeaderTitleLabel!
    @IBOutlet weak var distanceUnitLabel: HeaderSubtitleLabel!
    
    weak var delegate: RouteTableViewHeaderViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        //clear default values from the storyboard so user does not see a 'flash' of random values
        timeRemainingLabel.text     = ""
        timeUnitLabel.text          = ""
        etaLabel.text               = ""
        etaUnitLabel.text           = ""
        distanceRemainingLabel.text = ""
        distanceUnitLabel.text      = ""
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
                progressBarWidthConstraint.constant = bounds.width * progress
                UIView.animate(withDuration: 0.5) { [weak self] in
                    self?.layoutIfNeeded()
                }
            }
        }
    }
    
    @IBAction func didTapCancel(_ sender: Any) {
        delegate?.didTapCancel()
    }
}
