import Foundation

extension UIEdgeInsets {
    
    
    func debugQuickLookObject() -> Any? {
        return UIBezierPath(rect: CGRect(origin: .zero, size: CGSize(width: 50, height: 50)))
    }
}


class QuickLook: NSObject {
    
    var view: UIView
    var edgeInsets: UIEdgeInsets
    
    init(view: UIView, edgeInsets: UIEdgeInsets) {
        self.view = view
        self.edgeInsets = edgeInsets
        super.init()
    }
    
    func debugQuickLookObject() -> Any? {
        let path = UIBezierPath(rect: view.frame)
        let insetsRect = UIEdgeInsetsInsetRect(view.frame, edgeInsets)
        path.append(UIBezierPath(rect: insetsRect))
        return path
    }
}
