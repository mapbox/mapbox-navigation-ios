import UIKit

protocol RouteTableViewHeaderViewDelegate: class {
    func didTapCancel()
}

@IBDesignable
class RouteTableViewHeaderView: UIView {
    
    @IBOutlet weak var progressBarWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var progressBar: ProgressBar!
    
    @IBOutlet weak var titleLabel: HeaderTitleLabel!
    @IBOutlet weak var subtitleLabel: HeaderSubtitleLabel!
    
    weak var delegate: RouteTableViewHeaderViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        //clear default values from the storyboard so user does not see a 'flash' of random values
        titleLabel.text = ""
        subtitleLabel.text = ""
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
