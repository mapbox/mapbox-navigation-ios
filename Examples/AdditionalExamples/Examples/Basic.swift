/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios-examples
 To learn more about each example in this app, including descriptions and links
 to documentation, see our docs: https://docs.mapbox.com/ios/navigation/examples/basic
 */

import Foundation
import UIKit
import MapboxNavigationCore
import MapboxNavigationUIKit
import CoreLocation

class BasicViewController: UIViewController {
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let origin = CLLocationCoordinate2DMake(37.77440680146262, -122.43539772352648)
        let destination = CLLocationCoordinate2DMake(37.76556957793795, -122.42409811526268)
        let options = NavigationRouteOptions(coordinates: [origin, destination])
        
        let request = mapboxNavigation.routingProvider().calculateRoutes(options: options)
        
        Task {
            switch await request.result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let navigationRoutes):
                
                // For demonstration purposes, simulate locations if the Simulate Navigation option is on.                
                let navigationOptions = NavigationOptions(mapboxNavigation: mapboxNavigation,
                                                          voiceController: mapboxNavigationProvider.routeVoiceController, 
                                                          eventsManager: mapboxNavigationProvider.eventsManager())
                let navigationViewController = NavigationViewController(navigationRoutes: navigationRoutes,
                                                                        navigationOptions: navigationOptions)
                navigationViewController.modalPresentationStyle = .fullScreen
                // Render part of the route that has been traversed with full transparency, to give the illusion of a disappearing route.
                navigationViewController.routeLineTracksTraversal = true
                
                present(navigationViewController, animated: true, completion: nil)
            }
        }
    }
}
