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

final class BetaQueryViewController: UIViewController {
    private let mapboxNavigationProvider = MapboxNavigationProvider(
        coreConfig: .init(
            locationSource: simulationIsEnabled ? .simulation(
                initialLocation: nil
            ) : .live
        )
    )
    private var mapboxNavigation: MapboxNavigation {
        mapboxNavigationProvider.mapboxNavigation
    }

    private var navigationMapView: NavigationMapView!

    private var navigationRoutes: NavigationRoutes? {
        didSet {
            guard let navigationRoutes else {
                navigationMapView.removeRoutes()
                return
            }
            navigationMapView.showcase(navigationRoutes)
        }
    }

    private var startButton: UIButton!

    // MARK: - UIViewController lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationMapView = .init(
            location: mapboxNavigation.navigation()
                .locationMatching.map(\.enhancedLocation)
                .eraseToAnyPublisher(),
            routeProgress: mapboxNavigation.navigation()
                .routeProgress.map(\.?.routeProgress)
                .eraseToAnyPublisher(),
            predictiveCacheManager: mapboxNavigationProvider.predictiveCacheManager
        )
        navigationMapView.translatesAutoresizingMaskIntoConstraints = false
        navigationMapView.delegate = self

        view.addSubview(navigationMapView)

        NSLayoutConstraint.activate([
            navigationMapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationMapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationMapView.topAnchor.constraint(equalTo: view.topAnchor),
            navigationMapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        startButton = UIButton()
        startButton.setTitle("Start Navigation", for: .normal)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.backgroundColor = .blue
        startButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        startButton.addTarget(self, action: #selector(tappedStartButton(sender:)), for: .touchUpInside)
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
    private func tappedStartButton(sender: UIButton) {
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

        present(navigationViewController, animated: true, completion: nil)
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
        let navigationRouteOptions = MopedRouteOptions(
            waypoints: [userWaypoint, destinationWaypoint],
            // Pass your custom parameter value here.
            customParam: "custom_value"
        )

        let request = mapboxNavigation.routingProvider().calculateRoutes(options: navigationRouteOptions)

        Task {
            switch await request.result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let response):
                self.navigationRoutes = response
                self.startButton?.isHidden = false
            }
        }
    }
}

extension BetaQueryViewController: NavigationViewControllerDelegate {
    func navigationViewControllerDidDismiss(
        _ navigationViewController: NavigationViewController,
        byCanceling canceled: Bool
    ) {
        dismiss(animated: true, completion: nil)
    }
}

extension BetaQueryViewController: NavigationMapViewDelegate {
    func navigationMapView(_ navigationMapView: NavigationMapView, userDidLongTap mapPoint: MapPoint) {
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

final class MopedRouteOptions: NavigationRouteOptions, @unchecked Sendable {
    enum CodingKeys: String, CodingKey {
        case customParam = "custom_param"
    }

    var customParam: String?

    // Add departureTime to URLQueryItems
    override var urlQueryItems: [URLQueryItem] {
        var items = super.urlQueryItems
        let parameter = URLQueryItem(name: CodingKeys.customParam.rawValue, value: customParam)
        items.append(parameter)
        return items
    }

    // Create initializer to take in the custom request parameter.
    init(waypoints: [Waypoint], customParam: String) {
        self.customParam = customParam
        super.init(waypoints: waypoints)
    }

    // Implement decoding, so the custom parameter is preserved when copying the options
    required init(from decoder: any Decoder) throws {
        try super.init(from: decoder)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.customParam = try container.decodeIfPresent(String.self, forKey: .customParam)
    }

    // Implement encoding, so the custom parameter is preserved when copying the options
    override func encode(to encoder: any Encoder) throws {
        try super.encode(to: encoder)

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(customParam, forKey: .customParam)
    }

    // Set the custom parameter value from the queryItems parameter, so it is preserved on reroute requests
    required init(
        waypoints: [Waypoint],
        profileIdentifier: ProfileIdentifier? = .automobileAvoidingTraffic,
        queryItems: [URLQueryItem]? = nil
    ) {
        let mappedUrlItem = queryItems?.first(where: { $0.name == CodingKeys.customParam.stringValue })
        self.customParam = mappedUrlItem?.value

        super.init(waypoints: waypoints, profileIdentifier: profileIdentifier, queryItems: queryItems)
    }
}
