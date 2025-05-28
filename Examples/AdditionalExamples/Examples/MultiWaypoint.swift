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

final class MultiWaypointViewController: UIViewController {
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

    private var waypoints: [Waypoint] = []
    private var navigationRoutes: NavigationRoutes? {
        didSet {
            let isButtonHidden = navigationRoutes == nil
            startButton.isHidden = isButtonHidden
            clearMapButton.isHidden = isButtonHidden
            waypoints = navigationRoutes?.mainRoute.route.legs.compactMap { $0.destination } ?? []
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
    private var clearMapButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        configureMapView()
        configureStartButton()
        configureClearMapButton()

        mapboxNavigation.tripSession().startFreeDrive()
    }

    @objc
    func onClearMapClicked(_: Any) {
        navigationRoutes = nil
    }

    @objc
    func onStartNavigationClicked(_: UIButton) {
        guard let navigationRoutes else { return }

        let navigationOptions = NavigationOptions(
            mapboxNavigation: mapboxNavigation,
            voiceController: mapboxNavigationProvider.routeVoiceController,
            eventsManager: mapboxNavigationProvider.eventsManager(),
            styles: [StandardDayStyle(), StandardNightStyle()],
            predictiveCacheManager: mapboxNavigationProvider.predictiveCacheManager
        )
        let navigationViewController = NavigationViewController(
            navigationRoutes: navigationRoutes,
            navigationOptions: navigationOptions
        )
        navigationViewController.usesNightStyleInDarkMode = true
        navigationViewController.delegate = self
        navigationViewController.modalPresentationStyle = .fullScreen

        self.navigationRoutes = nil

        present(navigationViewController, animated: true, completion: nil)
    }

    private func requestRoute(with mapPoint: MapPoint) {
        guard let userLocation = navigationMapView.mapView.location.latestLocation else { return }

        var requestWaypoints = waypoints
        let newWaypoint = Waypoint(coordinate: mapPoint.coordinate, name: mapPoint.name)
        requestWaypoints.append(newWaypoint)
        let userWaypoint = Waypoint(coordinate: userLocation.coordinate)
        requestWaypoints.insert(userWaypoint, at: 0)
        let navigationRouteOptions = NavigationRouteOptions(waypoints: requestWaypoints)

        let task = mapboxNavigation.routingProvider().calculateRoutes(options: navigationRouteOptions)

        Task { [weak self] in
            switch await task.result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let response):
                guard let self else { return }

                waypoints.append(newWaypoint)
                navigationRoutes = response
            }
        }
    }

    private func configureMapView() {
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

    private func createButton(title: String, action: Selector) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .blue
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.isHidden = true
        view.addSubview(button)
        return button
    }

    private func configureStartButton() {
        startButton = createButton(title: "Start Navigation", action: #selector(onStartNavigationClicked(_:)))

        NSLayoutConstraint.activate([
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            startButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
        ])
    }

    private func configureClearMapButton() {
        clearMapButton = createButton(title: "Clear Map", action: #selector(onClearMapClicked(_:)))

        NSLayoutConstraint.activate([
            clearMapButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            clearMapButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
        ])
    }
}

extension MultiWaypointViewController: NavigationMapViewDelegate {
    func navigationMapView(_ navigationMapView: NavigationMapView, userDidLongTap mapPoint: MapPoint) {
        requestRoute(with: mapPoint)
    }

    func navigationMapView(_ navigationMapView: NavigationMapView, userDidTap mapPoint: MapPoint) {
        requestRoute(with: mapPoint)
    }

    func navigationMapView(_ navigationMapView: NavigationMapView, didSelect alternativeRoute: AlternativeRoute) {
        Task {
            guard let selectedRoutes = await self.navigationRoutes?.selecting(alternativeRoute: alternativeRoute)
            else { return }
            self.navigationRoutes = selectedRoutes
        }
    }
}

extension MultiWaypointViewController: NavigationViewControllerDelegate {
    func navigationViewControllerDidDismiss(
        _ navigationViewController: NavigationViewController,
        byCanceling canceled: Bool
    ) {
        navigationViewController.dismiss(animated: true)
    }

    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didArriveAt waypoint: Waypoint
    ) {
        print("Arrived at waypoint: \(waypoint.name ?? "Unknown")")
    }
}
