/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios-examples
 To learn more about each example in this app, including descriptions and links
 to documentation, see our docs: https://docs.mapbox.com/ios/navigation/examples/embedded-navigation
 */

import Foundation
import MapboxDirections
import MapboxMaps
import MapboxNavigationCore
import MapboxNavigationUIKit
import UIKit

class EmbeddedExampleViewController: UIViewController {
    let mapboxNavigationProvider = MapboxNavigationProvider(
        coreConfig: .init(
            locationSource: simulationIsEnabled ? .simulation(
                initialLocation: .init(
                    latitude: 37.77440680146262,
                    longitude: -122.43539772352648
                )
            ) : .live
        )
    )
    lazy var mapboxNavigation = mapboxNavigationProvider.mapboxNavigation

    @IBOutlet var reroutedLabel: UILabel!
    @IBOutlet var container: UIView!
    var navigationRoutes: NavigationRoutes?

    lazy var routeOptions: NavigationRouteOptions = {
        let origin = CLLocationCoordinate2DMake(37.77440680146262, -122.43539772352648)
        let destination = CLLocationCoordinate2DMake(37.76556957793795, -122.42409811526268)
        return NavigationRouteOptions(coordinates: [origin, destination])
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        reroutedLabel.isHidden = true
        calculateDirections()
    }

    func calculateDirections() {
        Task {
            switch await mapboxNavigation.routingProvider().calculateRoutes(options: routeOptions).result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let response):

                self.navigationRoutes = response
                self.startEmbeddedNavigation()
            }
        }
    }

    func flashReroutedLabel() {
        reroutedLabel.isHidden = false
        reroutedLabel.alpha = 1.0
        UIView.animate(withDuration: 1.0, delay: 1, options: .curveEaseIn, animations: {
            self.reroutedLabel.alpha = 0.0
        }, completion: { _ in
            self.reroutedLabel.isHidden = true
        })
    }

    func startEmbeddedNavigation() {
        // For demonstration purposes, simulate locations if the Simulate Navigation option is on.
        guard let navigationRoutes else { return }
        let navigationOptions = NavigationOptions(
            mapboxNavigation: mapboxNavigation,
            voiceController: mapboxNavigationProvider.routeVoiceController,
            eventsManager: mapboxNavigationProvider.eventsManager()
        )
        let navigationViewController = NavigationViewController(
            navigationRoutes: navigationRoutes,
            navigationOptions: navigationOptions
        )

        navigationViewController.delegate = self
        addChild(navigationViewController)
        container.addSubview(navigationViewController.view)
        navigationViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            navigationViewController.view.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 0),
            navigationViewController.view.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 0),
            navigationViewController.view.topAnchor.constraint(equalTo: container.topAnchor, constant: 0),
            navigationViewController.view.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 0),
        ])
        didMove(toParent: self)
    }
}

extension EmbeddedExampleViewController: NavigationViewControllerDelegate {
    func navigationViewController(_ navigationViewController: NavigationViewController, didRerouteAlong route: Route) {
        flashReroutedLabel()
    }

    func navigationViewControllerDidDismiss(
        _ navigationViewController: NavigationViewController,
        byCanceling canceled: Bool
    ) {
        navigationController?.popViewController(animated: true)
    }
}
