
_Source available [here](https://github.com/mapbox/navigation-ios-examples/blob/master/Navigation-Examples/Examples/Embedded-Navigation.swift)_

```swift
import Foundation
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

class EmbeddedExampleViewController: UIViewController {
 
    @IBOutlet weak var reroutedLabel: UILabel!
    @IBOutlet weak var enableReroutes: UISwitch!
    @IBOutlet weak var container: UIView!
    var route: Route?

    lazy var options: NavigationRouteOptions = {
        let origin = CLLocationCoordinate2DMake(37.77440680146262, -122.43539772352648)
        let destination = CLLocationCoordinate2DMake(37.76556957793795, -122.42409811526268)
        return NavigationRouteOptions(coordinates: [origin, destination])
    }()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(EmbeddedExampleViewController.flashReroutedLabel(_:)), name: .routeControllerDidReroute, object: nil)
        reroutedLabel.isHidden = true
        calculateDirections()
    }

    
    func calculateDirections() {
        Directions.shared.calculate(options) { (waypoints, routes, error) in
            guard let route = routes?.first, error == nil else {
                print(error!.localizedDescription)
                return
            }
            self.route = route
            self.startEmbeddedNavigation()
        }
    }
    @objc func flashReroutedLabel(_ sender: Any) {
        reroutedLabel.isHidden = false
        reroutedLabel.alpha = 1.0
        UIView.animate(withDuration: 1.0, delay: 1, options: .curveEaseIn, animations: {
            self.reroutedLabel.alpha = 0.0
        }, completion: { _ in
            self.reroutedLabel.isHidden = true
        })
    }
    
    func startEmbeddedNavigation() {
        let nav = NavigationViewController(for: route!)
        
        // This allows the developer to simulate the route.
        // Note: If copying and pasting this code in your own project,
        // comment out `simulationIsEnabled` as it is defined elsewhere in this project.
        if simulationIsEnabled {
            nav.routeController.locationManager = SimulatedLocationManager(route: route!)
        }
        
        nav.delegate = self
        addChildViewController(nav)
        container.addSubview(nav.view)
        nav.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nav.view.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 0),
            nav.view.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 0),
            nav.view.topAnchor.constraint(equalTo: container.topAnchor, constant: 0),
            nav.view.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 0)
            ])
        self.didMove(toParentViewController: self)
    }
}

extension EmbeddedExampleViewController: NavigationViewControllerDelegate {
    func navigationViewController(_ navigationViewController: NavigationViewController, shouldRerouteFrom location: CLLocation) -> Bool {
        return enableReroutes.isOn
    }
}
```
