import UIKit

/// :nodoc:
@objc(MBDraggableView)
open class StepListIndicatorView: UIView {
    
    // Workaround the fact that UIView properties are not marked with UI_APPEARANCE_SELECTOR.
    @objc dynamic open var gradientColors: [UIColor] = [.gray, .lightGray, .gray] {
        didSet {
            setNeedsLayout()
        }
    }
    
    fileprivate lazy var blurredEffectView: UIVisualEffectView = {
        return UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
    }()

    override open func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.midY
        layer.masksToBounds = true
        layer.opacity = 0.25
        applyGradient(colors: gradientColors)
        addBlurredEffect(view: blurredEffectView, to: self)
    }
    
    fileprivate func addBlurredEffect(view: UIView, to parentView: UIView)  {
        guard !view.isDescendant(of: parentView) else { return }
        view.frame = parentView.bounds
        parentView.addSubview(view)
    }
}
