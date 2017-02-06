import UIKit

extension UIView {
    class func defaultAnimation(_ duration: TimeInterval, animations: @escaping () -> Void, completion: ((_ completed: Bool) -> Void)?) {
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: animations, completion: completion)
    }
    
    func applyDefaultCornerRadiusShadow(cornerRadius: CGFloat? = 4, shadowOpacity: CGFloat? = 0.1) {
        self.layer.cornerRadius = cornerRadius!
        
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.layer.shadowRadius = 4
        self.layer.shadowOpacity = Float(shadowOpacity!)
    }
}
