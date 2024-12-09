/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios
 To learn more about the SDK, see our docs: https://docs.mapbox.com/ios/navigation
 */

import MapboxDirections
import MapboxMaps
import MapboxNavigationCore
import MapboxNavigationUIKit
import UIKit

final class AdvancedViewController: UIViewController {
    private let mapboxNavigationProvider = MapboxNavigationProvider(
        coreConfig: .init(
            // For demonstration purposes, simulate locations if the Simulate Navigation option is on.
            locationSource: simulationIsEnabled ? .simulation(
                initialLocation: nil
            ) : .live
        )
    )
    private var mapboxNavigation: MapboxNavigation {
        mapboxNavigationProvider.mapboxNavigation
    }

    private static let styleUrl = "mapbox://styles/mapbox-dash/standard-navigation"

    private var navigationMapView: NavigationMapView! {
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
                navigationMapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }
    }

    private var navigationRoutes: NavigationRoutes? {
        didSet {
            showCurrentRoute()
        }
    }

    private func showCurrentRoute() {
        guard let navigationRoutes else {
            navigationMapView.removeRoutes()
            return
        }
        navigationMapView.showcase(navigationRoutes)
    }

    private var startButton: UIButton!

    // MARK: - UIViewController lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()

        // Provide custom localization.
        LocalizationManager.customLocalizationBundle = .main

        navigationMapView = .init(
            location: mapboxNavigation.navigation()
                .locationMatching.map(\.enhancedLocation)
                .eraseToAnyPublisher(),
            routeProgress: mapboxNavigation.navigation()
                .routeProgress.map(\.?.routeProgress)
                .eraseToAnyPublisher(),
            predictiveCacheManager: mapboxNavigationProvider.predictiveCacheManager
        )
        navigationMapView.mapView.mapboxMap.loadStyle(StyleURI(rawValue: Self.styleUrl)!)
        navigationMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        navigationMapView.delegate = self
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

        startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
            .isActive = true
        startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
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

    @objc
    func tappedButton(sender: UIButton) {
        guard let navigationRoutes else { return }

        let navigationOptions = NavigationOptions(
            mapboxNavigation: mapboxNavigation,
            voiceController: mapboxNavigationProvider.routeVoiceController,
            eventsManager: mapboxNavigationProvider.eventsManager(),
            styles: [StandardDayStyle(), StandardNightStyle()],
            predictiveCacheManager: mapboxNavigationProvider.predictiveCacheManager,
            // Replace default `NavigationMapView` instance with instance that is used in preview mode.
            navigationMapView: navigationMapView
        )

        // Shows the alternative route duration close to the first maneuver starting the alternative route.
        navigationMapView.showsRelativeDurationsOnAlternativeManuever = true
        let navigationViewController = NavigationViewController(
            navigationRoutes: navigationRoutes,
            navigationOptions: navigationOptions
        )
        // Enables the dark/light appearance switch.
        navigationViewController.usesNightStyleInDarkMode = true
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
            navigationViewController.navigationView.bottomBannerContainerView.show(
                duration: duration,
                animations: {
                    navigationViewController.navigationView.wayNameView.alpha = 1.0
                    navigationViewController.navigationView.floatingStackView.alpha = 1.0
                    navigationViewController.navigationView.speedLimitView.alpha = 1.0
                }
            )
            navigationViewController.navigationView.topBannerContainerView.show(duration: duration)
        }
    }

    private func requestRoute(destination: CLLocationCoordinate2D) {
        guard let userLocation = navigationMapView.mapView.location.latestLocation else { return }

        let location = CLLocation(
            latitude: userLocation.coordinate.latitude,
            longitude: userLocation.coordinate.longitude
        )

        let userWaypoint = Waypoint(
            location: location,
            name: "user"
        )

        let destinationWaypoint = Waypoint(coordinate: destination)

        let navigationRouteOptions = NavigationRouteOptions(waypoints: [userWaypoint, destinationWaypoint])

        let task = mapboxNavigation.routingProvider().calculateRoutes(options: navigationRouteOptions)

        Task { [weak self] in
            switch await task.result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let response):
                guard let self else { return }

                navigationRoutes = response
                startButton?.isHidden = false
            }
        }
    }
}

extension AdvancedViewController: NavigationMapViewDelegate {
    func navigationMapView(_ navigationMapView: NavigationMapView, userDidLongTap mapPoint: MapPoint) {
        requestRoute(destination: mapPoint.coordinate)
    }

    func navigationMapView(_ navigationMapView: NavigationMapView, userDidTap mapPoint: MapPoint) {
        requestRoute(destination: mapPoint.coordinate)
    }

    // Delegate method called when the user selects a route
    func navigationMapView(_ navigationMapView: NavigationMapView, didSelect alternativeRoute: AlternativeRoute) {
        Task {
            guard let selectedRoutes = await self.navigationRoutes?.selecting(alternativeRoute: alternativeRoute)
            else { return }
            self.navigationRoutes = selectedRoutes
        }
    }
}

extension AdvancedViewController: NavigationViewControllerDelegate {
    func navigationViewControllerDidDismiss(
        _ navigationViewController: NavigationViewController,
        byCanceling canceled: Bool
    ) {
        let duration = 1.0
        navigationViewController.navigationView.topBannerContainerView.hide(duration: duration)
        navigationViewController.navigationView.bottomBannerContainerView.hide(
            duration: duration,
            animations: {
                navigationViewController.navigationView.wayNameView.alpha = 0.0
                navigationViewController.navigationView.floatingStackView.alpha = 0.0
                navigationViewController.navigationView.speedLimitView.alpha = 0.0
            },
            completion: { [weak self] _ in
                navigationViewController.dismiss(animated: false) {
                    guard let self else { return }

                    // Show previously hidden button that allows to start active navigation.
                    self.startButton.isHidden = false

                    // Since `NavigationViewController` assigns `NavigationMapView`'s delegate to itself,
                    // delegate should be re-assigned back to `NavigationMapView` that is used in preview mode.
                    self.navigationMapView.delegate = self

                    // Replace `NavigationMapView` instance with instance that was used in active navigation.
                    self.navigationMapView = navigationViewController.navigationMapView

                    // Re-start Free drive
                    self.mapboxNavigation.tripSession().startFreeDrive()

                    // Showcase originally requested routes.
                    self.showCurrentRoute()
                }
            }
        )
    }
}
