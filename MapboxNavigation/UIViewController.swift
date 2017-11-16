import UIKit

extension UIViewController {
    
    class func fromStoryboard<T>() -> T {
        let storyboard = UIStoryboard(name: "Navigation", bundle: .mapboxNavigation)
        let identifier = String(describing: T.self)
        return storyboard.instantiateViewController(withIdentifier: identifier) as! T
    }
}
