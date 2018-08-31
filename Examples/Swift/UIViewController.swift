import UIKit


extension UIViewController {
    
    static func viewControllerInStack<T: UIViewController>(of type: T.Type? = nil) -> T? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        
        if let vc = appDelegate.window?.rootViewController as? T {
            return vc
        } else if let vc = appDelegate.window?.rootViewController?.presentedViewController as? T {
            return vc
        } else if let vc = appDelegate.window?.rootViewController?.childViewControllers {
            return vc.lazy.compactMap { $0 as? T }.first
        }
        
        return nil
    }
}
