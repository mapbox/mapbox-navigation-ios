import UIKit

extension UIViewController {
    
    func simulatateViewControllerPresented() {
        _ = view // load view
        viewWillAppear(false)
        viewDidAppear(false)
    }
}
