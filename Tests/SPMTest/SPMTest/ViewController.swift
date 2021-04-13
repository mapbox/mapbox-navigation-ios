import UIKit
import MapboxCoreNavigation

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let distanceFormatter = DistanceFormatter()
        print(distanceFormatter.attributedString(from: .init(value: 10, unit: .meters)))
    }
}
