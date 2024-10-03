/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios
 To learn more about the SDK, see our docs: https://docs.mapbox.com/ios/navigation
 */

import MapboxMaps
import MapboxNavigationCore
import MapboxNavigationUIKit
import UIKit

final class CustomNavigationCameraViewController: UIViewController {
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

    private var navigationMapView: NavigationMapView! {
        didSet {
            if oldValue != nil {
                oldValue.removeFromSuperview()
            }

            navigationMapView.translatesAutoresizingMaskIntoConstraints = false
            navigationMapView.delegate = self

            view.insertSubview(navigationMapView, at: 0)

            NSLayoutConstraint.activate([
                navigationMapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                navigationMapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                navigationMapView.topAnchor.constraint(equalTo: view.topAnchor),
                navigationMapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }
    }

    private var startNavigationButton: UIButton!

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

    // MARK: - UIViewController lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationMapView()
        setupStartNavigationButton()

        mapboxNavigation.tripSession().startFreeDrive()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        startNavigationButton.layer.cornerRadius = startNavigationButton.bounds.midY
        startNavigationButton.clipsToBounds = true
        startNavigationButton.setNeedsDisplay()
    }

    // MARK: - Setting-up methods

    private func setupNavigationMapView() {
        navigationMapView = .init(
            location: mapboxNavigation.navigation().locationMatching.map(\.enhancedLocation)
                .eraseToAnyPublisher(),
            routeProgress: mapboxNavigation.navigation().routeProgress.map(\.?.routeProgress).eraseToAnyPublisher(),
            predictiveCacheManager: mapboxNavigationProvider.predictiveCacheManager
        )

        // Modify default `NavigationViewportDataSource` and `NavigationCameraStateTransition` to change
        // `NavigationCamera` behavior during free drive and when locations are provided by Maps SDK directly.
        let navigationCamera = navigationMapView.navigationCamera
        navigationCamera.viewportDataSource = CustomViewportDataSource(navigationMapView.mapView)
        navigationCamera.cameraStateTransition = CustomCameraStateTransition(navigationMapView.mapView)
    }

    private func setupStartNavigationButton() {
        startNavigationButton = UIButton()
        startNavigationButton.setTitle("Start Navigation", for: .normal)
        startNavigationButton.translatesAutoresizingMaskIntoConstraints = false
        startNavigationButton.backgroundColor = .blue
        startNavigationButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        startNavigationButton.addTarget(self, action: #selector(startNavigationButtonPressed(_:)), for: .touchUpInside)
        startNavigationButton.isHidden = true

        view.addSubview(startNavigationButton)

        startNavigationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
            .isActive = true
        startNavigationButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }

    @objc
    private func startNavigationButtonPressed(_ sender: UIButton) {
        guard let navigationRoutes else { return }

        let navigationOptions = NavigationOptions(
            mapboxNavigation: mapboxNavigation,
            voiceController: mapboxNavigationProvider.routeVoiceController,
            eventsManager: mapboxNavigationProvider.eventsManager(),
            predictiveCacheManager: mapboxNavigationProvider.predictiveCacheManager,
            // Replace default `NavigationMapView` instance with instance that is used in preview mode.
            navigationMapView: navigationMapView
        )
        let navigationViewController = NavigationViewController(
            navigationRoutes: navigationRoutes,
            navigationOptions: navigationOptions
        )
        navigationViewController.delegate = self
        navigationViewController.modalPresentationStyle = .fullScreen

        startNavigationButton.isHidden = true
        present(navigationViewController, animated: true, completion: nil)
    }

    private func requestRoute(destination: CLLocationCoordinate2D) {
        guard let userLocation = navigationMapView.mapView.location.latestLocation else { return }

        let location = CLLocation(
            latitude: userLocation.coordinate.latitude,
            longitude: userLocation.coordinate.longitude
        )
        let userWaypoint = Waypoint(location: location, name: "user")
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
                startNavigationButton?.isHidden = false
            }
        }
    }
}

extension CustomNavigationCameraViewController: NavigationMapViewDelegate {
    func navigationMapView(_ navigationMapView: NavigationMapView, userDidLongTap mapPoint: MapPoint) {
        requestRoute(destination: mapPoint.coordinate)
    }
}

extension CustomNavigationCameraViewController: NavigationViewControllerDelegate {
    func navigationViewControllerDidDismiss(
        _ navigationViewController: NavigationViewController,
        byCanceling canceled: Bool
    ) {
        navigationViewController.dismiss(animated: false) { [weak self] in
            guard let self else { return }

            navigationMapView = navigationViewController.navigationMapView
            navigationMapView.removeRoutes()
            let ornaments = navigationMapView.mapView.ornaments
            ornaments?.options.logo.margins = .init(x: 8.0, y: 8.0)
            ornaments?.options.attributionButton.margins = .init(x: 8.0, y: 8.0)
        }
    }
}
