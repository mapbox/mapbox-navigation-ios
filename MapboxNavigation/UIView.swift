import UIKit

enum UIViewLayoutError: String, Error {
    case noSuperview = "Error! `superview` was nil – call `addSubview(view: UIView)` before calling `pinToSuperview()` to fix this."
}

extension UIView {
    class func defaultAnimation(_ duration: TimeInterval, delay: TimeInterval = 0, animations: @escaping () -> Void, completion: ((_ completed: Bool) -> Void)?) {
        UIView.animate(withDuration: duration, delay: delay, options: .curveEaseInOut, animations: animations, completion: completion)
    }
    
    func applyDefaultCornerRadiusShadow(cornerRadius: CGFloat? = 4, shadowOpacity: CGFloat? = 0.1) {
        layer.cornerRadius = cornerRadius!
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 4
        layer.shadowOpacity = Float(shadowOpacity!)
    }
    
    func applyDefaultShadow(shadowOpacity: CGFloat? = 0.1) {
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 4
        layer.shadowOpacity = Float(shadowOpacity!)
    }
    
    
    func pinToSuperview() throws {
        guard let superview = self.superview else { throw UIViewLayoutError.noSuperview }
        
        self.translatesAutoresizingMaskIntoConstraints = false
        superview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[subview]-0-|", options: .directionLeadingToTrailing, metrics: nil, views: ["subview": self]))
        superview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[subview]-0-|", options: .directionLeadingToTrailing, metrics: nil, views: ["subview": self]))
        
        superview.setNeedsLayout()
    }
    

}
