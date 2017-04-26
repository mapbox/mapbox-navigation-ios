import UIKit

extension UIView {
    class func defaultAnimation(_ duration: TimeInterval, animations: @escaping () -> Void, completion: ((_ completed: Bool) -> Void)?) {
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: animations, completion: completion)
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
}
