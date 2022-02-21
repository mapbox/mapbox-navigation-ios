import UIKit

// :nodoc:
@available(*, deprecated, message: "This class is no longer used.")
@objc(MBManeuverContainerView)
open class ManeuverContainerView: UIView {
    
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    @objc dynamic public var height: CGFloat = 100 {
        didSet {
            heightConstraint.constant = height
            setNeedsUpdateConstraints()
        }
    }
}
