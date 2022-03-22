import UIKit

// :nodoc:
@available(*, deprecated, message: "This class is no longer used.")
@objc(MBLineView)
public class LineView: UIView {
    
    // Set the line color on all line views.
    @objc dynamic public var lineColor: UIColor = .black {
        didSet {
            setNeedsDisplay()
            setNeedsLayout()
        }
    }
}
