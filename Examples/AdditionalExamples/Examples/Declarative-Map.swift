/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios
 To learn more about the SDK, see our docs: https://docs.mapbox.com/ios/navigation
 */

import Combine
import MapboxDirections
import MapboxMaps
@_spi(ExperimentalMapboxAPI) import MapboxNavigationCore
import MapboxNavigationUIKit
import UIKit

final class DeclarativeMapViewController: UIViewController {
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

    private var navigationMapView: NavigationMapView!
    private var startButton: UIButton!

    private var subscriptions: [AnyCancellable] = []

    private var destination: CLLocationCoordinate2D? {
        didSet {
            updateMapContent()
        }
    }

    private var navigationContent: NavigationStyleContent? {
        didSet {
            // you need to call `setMapStyleContent()` for each NavigationStyleContent update
            updateMapContent()
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

    // MARK: - UIViewController lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()

        createMapView()
        configureMapView()
        configureStartButton()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        startButton.layer.cornerRadius = startButton.bounds.midY
        startButton.clipsToBounds = true
        startButton.setNeedsDisplay()
    }

    @objc
    func onStartNavigationClicked(sender: UIButton) {
        guard let navigationRoutes else { return }

        let navigationOptions = NavigationOptions(
            mapboxNavigation: mapboxNavigation,
            voiceController: mapboxNavigationProvider.routeVoiceController,
            eventsManager: mapboxNavigationProvider.eventsManager(),
            styles: [StandardDayStyle(), StandardNightStyle()],
            predictiveCacheManager: mapboxNavigationProvider.predictiveCacheManager,
            navigationMapView: navigationMapView
        )

        let navigationViewController = NavigationViewController(
            navigationRoutes: navigationRoutes,
            navigationOptions: navigationOptions
        )
        navigationViewController.usesNightStyleInDarkMode = true
        navigationViewController.delegate = self
        navigationViewController.modalPresentationStyle = .fullScreen

        present(navigationViewController, animated: true, completion: nil)
    }

    private func updateMapContent() {
        guard let mapView = navigationMapView?.mapView else { return }

        let id = "blue-layer"
        let sourceId = "\(id)-source"

        mapView.mapboxMap.setMapStyleContent {
            // Add navigation map content to your map style content
            if let navigationContent {
                navigationContent
            }

            if let destination {
                GeoJSONSource(id: sourceId)
                    .data(.geometry(.polygon(Polygon(center: destination, radius: 200, vertices: 60))))

                FillLayer(id: id, source: sourceId)
                    .fillColor(.blue)
                    .fillOpacity(0.3)
                LineLayer(id: "\(id)-border", source: sourceId)
                    .lineColor(.darkGray)
                    .lineOpacity(0.4)
                    .lineWidth(2)
            }
        }
    }

    private func requestRoute(destination: CLLocationCoordinate2D) {
        guard let userLocation = navigationMapView.mapView.location.latestLocation else { return }

        self.destination = destination

        let location = CLLocation(
            latitude: userLocation.coordinate.latitude,
            longitude: userLocation.coordinate.longitude
        )

        let userWaypoint = Waypoint(location: location)
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

extension DeclarativeMapViewController: NavigationMapViewDelegate {
    func navigationMapView(_ navigationMapView: NavigationMapView, userDidLongTap mapPoint: MapPoint) {
        requestRoute(destination: mapPoint.coordinate)
    }

    func navigationMapView(_ navigationMapView: NavigationMapView, userDidTap mapPoint: MapPoint) {
        requestRoute(destination: mapPoint.coordinate)
    }

    func navigationMapView(_ navigationMapView: NavigationMapView, didSelect alternativeRoute: AlternativeRoute) {
        Task {
            guard let selectedRoutes = await self.navigationRoutes?.selecting(alternativeRoute: alternativeRoute)
            else { return }
            self.navigationRoutes = selectedRoutes
        }
    }
}

extension DeclarativeMapViewController: NavigationViewControllerDelegate {
    func navigationViewControllerDidDismiss(
        _ navigationViewController: NavigationViewController,
        byCanceling canceled: Bool
    ) {
        configureMapView()
        navigationViewController.dismiss(animated: true)
    }
}

extension DeclarativeMapViewController {
    private func createMapView() {
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
        navigationMapView.automaticallySetDeclarativeMapContent = false
        navigationMapView.useLegacyManualLayersOrderApproach = false

        navigationMapView.navigationStyleContent
            .sink { [weak self] navigationContent in
                self?.navigationContent = navigationContent
            }
            .store(in: &subscriptions)
    }

    private func configureMapView() {
        navigationMapView.delegate = self

        view.addSubview(navigationMapView)

        navigationMapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            navigationMapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationMapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationMapView.topAnchor.constraint(equalTo: view.topAnchor),
            navigationMapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func configureStartButton() {
        startButton = UIButton()
        startButton.setTitle("Start Navigation", for: .normal)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.backgroundColor = .blue
        startButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        startButton.addTarget(self, action: #selector(onStartNavigationClicked(sender:)), for: .touchUpInside)
        startButton.isHidden = true
        view.addSubview(startButton)

        startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
            .isActive = true
        startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        view.setNeedsLayout()

        mapboxNavigation.tripSession().startFreeDrive()
    }
}
