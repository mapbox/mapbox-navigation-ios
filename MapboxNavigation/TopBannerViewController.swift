import Foundation
import UIKit
import MapboxCoreNavigation
import MapboxDirections

class TopBannerViewController: UIViewController, NavigationComponent {
    override func viewDidLoad() {
        view.backgroundColor = .orange
        
        view.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }
}
