/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios
 To learn more about the SDK, see our docs: https://docs.mapbox.com/ios/navigation
 */

import MapboxDirections
import MapboxMaps
import MapboxNavigationCore
import MapboxNavigationUIKit
import Turf
import UIKit

final class RouteLinesStylingViewController: UIViewController {
    private let mapboxNavigationProvider = MapboxNavigationProvider(
        coreConfig: .init(
            locationSource: simulationIsEnabled ? .simulation(
                initialLocation: .init(latitude: 37.773, longitude: -122.411)
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

        navigationMapView = .init(
            location: mapboxNavigation.navigation()
                .locationMatching.map(\.enhancedLocation)
                .eraseToAnyPublisher(),
            routeProgress: mapboxNavigation.navigation()
                .routeProgress.map(\.?.routeProgress)
                .eraseToAnyPublisher(),
            predictiveCacheManager: mapboxNavigationProvider.predictiveCacheManager
        )
        navigationMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        navigationMapView.delegate = self

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
    private func tappedButton(sender: UIButton) {
        guard let navigationRoutes else { return }

        let navigationOptions = NavigationOptions(
            mapboxNavigation: mapboxNavigation,
            voiceController: mapboxNavigationProvider.routeVoiceController,
            eventsManager: mapboxNavigationProvider.eventsManager(),
            predictiveCacheManager: mapboxNavigationProvider.predictiveCacheManager
        )
        let navigationViewController = NavigationViewController(
            navigationRoutes: navigationRoutes,
            navigationOptions: navigationOptions
        )
        navigationViewController.delegate = self
        navigationViewController.modalPresentationStyle = .fullScreen

        startButton.isHidden = true
        present(navigationViewController, animated: true)
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
                startButton?.isHidden = false
            }
        }
    }

    // MARK: - Styling methods

    func customRouteLineLayer(with identifier: String, sourceIdentifier: String) -> LineLayer {
        var lineLayer = LineLayer(id: identifier, source: sourceIdentifier)

        // `identifier` parameter contains unique identifier of the route layer or its casing.
        // Such identifier consists of several parts: the framework prefix, whether route is
        // main or alternative, and whether route is casing or not.
        //
        // For example: identifier for the main route line will look like this: `com.mapbox.navigation.route_line.main`,
        // and for alternative route line casing will look like this:
        // `com.mapbox.navigation.route_line.alternative_0.casing`.
        lineLayer.lineColor = .constant(.init(identifier.contains("main") ? #colorLiteral(red: 0.01985955052, green: 0.6569676995, blue: 0.4195544124, alpha: 1) : #colorLiteral(red: 0.5445436835, green: 0.6098695397, blue: 0.5656256676, alpha: 1)))
        lineLayer.lineWidth = .expression(lineWidthExpression(1))
        lineLayer.lineJoin = .constant(.round)
        lineLayer.lineCap = .constant(.round)

        return lineLayer
    }

    func customRouteCasingLineLayer(with identifier: String, sourceIdentifier: String) -> LineLayer {
        var lineLayer = LineLayer(id: identifier, source: sourceIdentifier)

        // Based on information stored in `identifier` property (whether route line is main or not)
        // route line will be colored differently.
        lineLayer.lineColor = .constant(.init(identifier.contains("main") ? #colorLiteral(red: 0.01342471968, green: 0.3149059415, blue: 0.2209827304, alpha: 1) : #colorLiteral(red: 0.2922659814, green: 0.3427096307, blue: 0.3116717637, alpha: 1)))
        lineLayer.lineWidth = .expression(lineWidthExpression(1.2))
        lineLayer.lineJoin = .constant(.round)
        lineLayer.lineCap = .constant(.round)

        return lineLayer
    }

    func lineWidthExpression(_ multiplier: Double) -> MapboxMaps.Expression {
        let lineWidthExpression = Exp(.interpolate) {
            Exp(.linear)
            Exp(.zoom)
            // It's possible to change route line width depending on zoom level, by using expression
            // instead of constant. Navigation SDK for iOS also exposes `RouteLineWidthByZoomLevel`
            // public property, which contains default values for route lines on specific zoom levels.
            RouteLineWidthByZoomLevel.multiplied(by: multiplier)
        }

        return lineWidthExpression
    }
}

// MARK: Delegate methods

extension RouteLinesStylingViewController: NavigationMapViewDelegate {
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

    func navigationMapView(
        _ navigationMapView: NavigationMapView,
        routeLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer? {
        customRouteLineLayer(with: identifier, sourceIdentifier: sourceIdentifier)
    }

    func navigationMapView(
        _ navigationMapView: NavigationMapView,
        routeCasingLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer? {
        customRouteCasingLineLayer(with: identifier, sourceIdentifier: sourceIdentifier)
    }
}

extension RouteLinesStylingViewController: NavigationViewControllerDelegate {
    // Similarly to preview mode, when using `NavigationMapView`, it's possible to change
    // route line styling during active guidance in `NavigationViewController`.
    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        routeLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer? {
        customRouteLineLayer(with: identifier, sourceIdentifier: sourceIdentifier)
    }

    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        routeCasingLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer? {
        customRouteCasingLineLayer(with: identifier, sourceIdentifier: sourceIdentifier)
    }

    func navigationViewControllerDidDismiss(
        _ navigationViewController: NavigationViewController,
        byCanceling canceled: Bool
    ) {
        dismiss(animated: true, completion: nil)
    }
}
