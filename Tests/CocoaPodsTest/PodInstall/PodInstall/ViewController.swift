import UIKit
import MapboxNavigation
import MapboxCoreNavigation

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Test that classes are accessible
        // and prevent comiler optimizations for unused imports.
        _ = PassiveLocationManager()
        _ = NavigationMapView(frame: .zero)
    }
}

