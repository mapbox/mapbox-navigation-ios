import UIKit
import MapboxNavigation
import MapboxCoreNavigation

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let navigationMapView = NavigationMapView()
        navigationMapView.autoresizingMask = [
            .flexibleWidth,
            .flexibleHeight
        ]
        view.addSubview(navigationMapView)
    }
}
