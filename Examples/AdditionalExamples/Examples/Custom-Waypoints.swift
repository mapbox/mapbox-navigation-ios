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

final class CustomWaypointsViewController: UIViewController {
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
            startButton.isEnabled = true
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
        startButton.setTitle("Request a route", for: .normal)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.backgroundColor = .blue
        startButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        startButton.addTarget(self, action: #selector(tappedButton(sender:)), for: .touchUpInside)
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
        guard let navigationRoutes else {
            requestRoute()
            startButton.setTitle("Start navigation", for: .normal)
            startButton.isEnabled = false
            return
        }

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

    private func requestRoute() {
        let origin = CLLocationCoordinate2DMake(37.773, -122.411)
        let firstWaypoint = CLLocationCoordinate2DMake(37.763252389415186, -122.40061448679577)
        let secondWaypoint = CLLocationCoordinate2DMake(37.76259647118012, -122.42072747880516)
        let navigationRouteOptions = NavigationRouteOptions(coordinates: [origin, firstWaypoint, secondWaypoint])

        let task = mapboxNavigation.routingProvider().calculateRoutes(options: navigationRouteOptions)

        Task { [weak self] in
            switch await task.result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let routes):
                guard let self else { return }

                navigationRoutes = routes
                startButton?.isHidden = false
            }
        }
    }

    // MARK: - Styling methods

    private func customCircleLayer(with identifier: String, sourceIdentifier: String) -> CircleLayer {
        var circleLayer = CircleLayer(id: identifier, source: sourceIdentifier)
        let opacity = Exp(.switchCase) {
            Exp(.any) {
                Exp(.get) {
                    "waypointCompleted"
                }
            }
            0.5
            1
        }
        circleLayer.circleColor = .constant(.init(UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)))
        circleLayer.circleOpacity = .expression(opacity)
        circleLayer.circleRadius = .constant(.init(10))
        circleLayer.circleStrokeColor = .constant(.init(UIColor.black))
        circleLayer.circleStrokeWidth = .constant(.init(1))
        circleLayer.circleStrokeOpacity = .expression(opacity)
        return circleLayer
    }

    private func customSymbolLayer(with identifier: String, sourceIdentifier: String) -> SymbolLayer {
        var symbolLayer = SymbolLayer(id: identifier, source: sourceIdentifier)
        symbolLayer.textField = .expression(Exp(.toString) {
            Exp(.get) {
                "name"
            }
        })
        symbolLayer.textSize = .constant(.init(10))
        symbolLayer.textOpacity = .expression(Exp(.switchCase) {
            Exp(.any) {
                Exp(.get) {
                    "waypointCompleted"
                }
            }
            0.5
            1
        })
        symbolLayer.textHaloWidth = .constant(.init(0.25))
        symbolLayer.textHaloColor = .constant(.init(UIColor.black))
        return symbolLayer
    }

    private func customWaypointShape(shapeFor waypoints: [Waypoint], legIndex: Int) -> FeatureCollection {
        var features = [Turf.Feature]()
        for (waypointIndex, waypoint) in waypoints.enumerated() {
            var feature = Feature(geometry: .point(Point(waypoint.coordinate)))
            feature.properties = [
                "waypointCompleted": .boolean(waypointIndex < legIndex),
                "name": .number(Double(waypointIndex + 1)),
            ]
            features.append(feature)
        }
        return FeatureCollection(features: features)
    }
}

// MARK: Delegate methods

extension CustomWaypointsViewController: NavigationMapViewDelegate {
    func navigationMapView(
        _ navigationMapView: NavigationMapView,
        waypointCircleLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> CircleLayer? {
        customCircleLayer(with: identifier, sourceIdentifier: sourceIdentifier)
    }

    func navigationMapView(
        _ navigationMapView: NavigationMapView,
        waypointSymbolLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> SymbolLayer? {
        customSymbolLayer(with: identifier, sourceIdentifier: sourceIdentifier)
    }

    func navigationMapView(
        _ navigationMapView: NavigationMapView,
        shapeFor waypoints: [Waypoint],
        legIndex: Int
    ) -> FeatureCollection? {
        customWaypointShape(shapeFor: waypoints, legIndex: legIndex)
    }
}

extension CustomWaypointsViewController: NavigationViewControllerDelegate {
    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        waypointCircleLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> CircleLayer? {
        customCircleLayer(with: identifier, sourceIdentifier: sourceIdentifier)
    }

    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        waypointSymbolLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> SymbolLayer? {
        customSymbolLayer(with: identifier, sourceIdentifier: sourceIdentifier)
    }

    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        shapeFor waypoints: [Waypoint],
        legIndex: Int
    ) -> FeatureCollection? {
        customWaypointShape(shapeFor: waypoints, legIndex: legIndex)
    }

    func navigationViewControllerDidDismiss(
        _ navigationViewController: NavigationViewController,
        byCanceling canceled: Bool
    ) {
        dismiss(animated: true, completion: nil)
    }
}
