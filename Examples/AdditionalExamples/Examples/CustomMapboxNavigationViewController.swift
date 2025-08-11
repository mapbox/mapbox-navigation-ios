import MapboxDirections
import MapboxNavigationCore
import MapboxNavigationUIKit
import CoreLocation
import UIKit

class CustomMapboxNavigationViewController: NavigationViewController {
    var shouldDismissOnCompletion = false
    
    override func viewDidLoad() {
            super.viewDidLoad()
            // Ensure auto-dismiss is prevented when a new navigation session starts
            preventDismissal()
        }
    
    @MainActor
    override open func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {

        if shouldDismissOnCompletion {
                    super.dismiss(animated: flag, completion: completion)
                } else {
                    print("Navigation dismissed attempt blocked until user taps arrived button in bottom banner")
                }
    }
    
    func navigationViewController(_ navigationViewController: NavigationViewController,
                                  didArriveAt waypoint: Waypoint) -> Bool {
        // Return true to prevent automatic dismissal
        return true
    }
    
    func allowDismissal() {
            shouldDismissOnCompletion = true
        }
    
    func preventDismissal() {
            shouldDismissOnCompletion = false
        }
}
