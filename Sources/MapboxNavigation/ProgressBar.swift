import UIKit

// :nodoc:
@available(*, deprecated, message: "This class is no longer used.")
@objc(MBProgressBar)
public class ProgressBar: UIView {
    
    let bar = UIView()
    
    // Sets the color of the progress bar.
    @objc dynamic public var barColor: UIColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1) {
        didSet {
            bar.backgroundColor = barColor
        }
    }
    
    // Set the progress between 0.0-1.0
    var progress: CGFloat = 0 {
        didSet {
            self.updateProgressBar()
            self.layoutIfNeeded()
        }
    }
    
    override open var description: String {
        return super.description + "; progress = \(progress)"
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        if bar.superview == nil {
            addSubview(bar)
        }
        
        updateProgressBar()
    }
    
    func updateProgressBar() {
        if let superview = superview {
            let origin: CGPoint
            if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
                origin = CGPoint(x: superview.bounds.width * (1 - progress), y: 0)
            } else {
                origin = .zero
            }
            bar.frame = CGRect(origin: origin, size: CGSize(width: superview.bounds.width * progress, height: bounds.height))
        }
    }
}
