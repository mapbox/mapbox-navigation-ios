/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios-examples
 To learn more about each example in this app, including descriptions and links
 to documentation, see our docs: https://docs.mapbox.com/ios/navigation/examples/advanced
 */

import UIKit
import MapboxNavigationCore
import MapboxNavigationUIKit
import MapboxMaps
import MapboxDirections

class AdvancedViewController: UIViewController, NavigationMapViewDelegate, NavigationViewControllerDelegate {
    
    let mapboxNavigationProvider = MapboxNavigationProvider(
        coreConfig: .init(
            // For demonstration purposes, simulate locations if the Simulate Navigation option is on.
            locationSource: simulationIsEnabled ? .simulation(
                initialLocation: nil
            ) : .live
        )
    )
    lazy var mapboxNavigation = mapboxNavigationProvider.mapboxNavigation
    
    var navigationMapView: NavigationMapView! {
        didSet {
            if oldValue != nil {
                oldValue.removeFromSuperview()
            }
            
            navigationMapView.translatesAutoresizingMaskIntoConstraints = false
            
            view.insertSubview(navigationMapView, at: 0)
            
            NSLayoutConstraint.activate([
                navigationMapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                navigationMapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                navigationMapView.topAnchor.constraint(equalTo: view.topAnchor),
                navigationMapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
    }
    
    var navigationRoutes: NavigationRoutes? {
        didSet {
            showCurrentRoute()
        }
    }
    
    func showCurrentRoute() {
        guard let navigationRoutes = navigationRoutes else {
            navigationMapView.removeRoutes()
            return
        }
        navigationMapView.showcase(navigationRoutes)
    }
    
    var startButton: UIButton!
    
    // MARK: - UIViewController lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationMapView = .init(
            location: mapboxNavigation.navigation().locationMatching.map(\.location).eraseToAnyPublisher(),
            routeProgress: mapboxNavigation.navigation().routeProgress.map(\.?.routeProgress).eraseToAnyPublisher(),
            predictiveCacheManager: mapboxNavigationProvider.predictiveCacheManager
        )
        navigationMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        navigationMapView.delegate = self
        navigationMapView.mapView.mapboxMap.loadStyle(StyleURI.dark)
        navigationMapView.puckType = .puck2D(.navigationDefault)
        
        view.addSubview(navigationMapView)
        
        startButton = UIButton()
        startButton.setTitle("Start Navigation", for: .normal)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.backgroundColor = .blue
        startButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        startButton.addTarget(self, action: #selector(tappedButton(sender:)), for: .touchUpInside)
        startButton.isHidden = true
        view.addSubview(startButton)
        
        startButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
        startButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        view.setNeedsLayout()
        
        mapboxNavigation.tripSession().startFreeDrive()
    }
    
    // Override layout lifecycle callback to be able to style the start button.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        startButton.layer.cornerRadius = startButton.bounds.midY
        startButton.clipsToBounds = true
        startButton.setNeedsDisplay()
    }

    @objc func tappedButton(sender: UIButton) {
        guard let navigationRoutes = navigationRoutes else { return }
        
        let navigationOptions = NavigationOptions(
            mapboxNavigation: mapboxNavigation,
            voiceController: mapboxNavigationProvider.routeVoiceController,
            eventsManager: mapboxNavigationProvider.eventsManager(),
            styles: [NightStyle()],
            predictiveCacheManager: mapboxNavigationProvider.predictiveCacheManager,
            // Replace default `NavigationMapView` instance with instance that is used in preview mode.
            navigationMapView: navigationMapView
        )
        let navigationViewController = NavigationViewController(navigationRoutes: navigationRoutes,
                                                                navigationOptions: navigationOptions)
        navigationViewController.delegate = self
        navigationViewController.modalPresentationStyle = .fullScreen
        
        startButton.isHidden = true
        
        // Hide top and bottom container views before animating their presentation.
        navigationViewController.navigationView.bottomBannerContainerView.hide(animated: false)
        navigationViewController.navigationView.topBannerContainerView.hide(animated: false)
        
        // Hide `WayNameView`, `FloatingStackView` and `SpeedLimitView` to smoothly present them.
        navigationViewController.navigationView.wayNameView.alpha = 0.0
        navigationViewController.navigationView.floatingStackView.alpha = 0.0
        navigationViewController.navigationView.speedLimitView.alpha = 0.0
        
        present(navigationViewController, animated: false) {
            // Animate top and bottom banner views presentation.
            let duration = 1.0
            navigationViewController.navigationView.bottomBannerContainerView.show(duration: duration,
                                                                                   animations: {
                navigationViewController.navigationView.wayNameView.alpha = 1.0
                navigationViewController.navigationView.floatingStackView.alpha = 1.0
                navigationViewController.navigationView.speedLimitView.alpha = 1.0
            })
            navigationViewController.navigationView.topBannerContainerView.show(duration: duration)
        }
    }

    func requestRoute(destination: CLLocationCoordinate2D) {
        guard let userLocation = navigationMapView.mapView.location.latestLocation else { return }
        
        let location = CLLocation(latitude: userLocation.coordinate.latitude,
                                  longitude: userLocation.coordinate.longitude)
        
        let userWaypoint = Waypoint(location: location,
                                    name: "user")
        
        let destinationWaypoint = Waypoint(coordinate: destination)
        
        let navigationRouteOptions = NavigationRouteOptions(waypoints: [userWaypoint, destinationWaypoint])
        
        let task = mapboxNavigation.routingProvider().calculateRoutes(options: navigationRouteOptions)
        
        Task { [weak self] in
            switch await task.result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let response):
                guard let self = self else { return }

                self.navigationRoutes = response
                self.startButton?.isHidden = false
            }
        }
    }
    
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        let duration = 1.0
        navigationViewController.navigationView.topBannerContainerView.hide(duration: duration)
        navigationViewController.navigationView.bottomBannerContainerView.hide(duration: duration,
                                                                               animations: {
            navigationViewController.navigationView.wayNameView.alpha = 0.0
            navigationViewController.navigationView.floatingStackView.alpha = 0.0
            navigationViewController.navigationView.speedLimitView.alpha = 0.0
        },
                                                                               completion: { [weak self] _ in
            navigationViewController.dismiss(animated: false) {
                guard let self = self else { return }
                
                // Show previously hidden button that allows to start active navigation.
                self.startButton.isHidden = false
                
                // Since `NavigationViewController` assigns `NavigationMapView`'s delegate to itself,
                // delegate should be re-assigned back to `NavigationMapView` that is used in preview mode.
                self.navigationMapView.delegate = self
                
                // Replace `NavigationMapView` instance with instance that was used in active navigation.
                self.navigationMapView = navigationViewController.navigationMapView
                
                // Showcase originally requested routes.
                self.showCurrentRoute()
            }
        })
    }
    
    // MARK: NavigationMapViewDelegate implementation
    
    func navigationMapView(_ navigationMapView: NavigationMapView, userDidLongTap mapPoint: MapPoint) {
        requestRoute(destination: mapPoint.coordinate)
    }
    
    // Delegate method called when the user selects a route
    func navigationMapView(_ navigationMapView: NavigationMapView, didSelect alternativeRoute: AlternativeRoute) {
        Task {
            guard let selectedRoutes = await self.navigationRoutes?.selecting(alternativeRoute: alternativeRoute) else { return }
            self.navigationRoutes = selectedRoutes
        }
    }
}
