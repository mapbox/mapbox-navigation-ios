import Foundation
import MapboxMaps
import MapboxNavigationCore
import MapboxNavigationUIKit
import UIKit

final class CustomFinalWaypointController: UIViewController {
    private let mapboxNavigationProvider = MapboxNavigationProvider(
        coreConfig: .init(
            locationSource: simulationIsEnabled ? .simulation(
                initialLocation: .init(
                    latitude: 37.77440680146262,
                    longitude: -122.43539772352648
                )
            ) : .live
        )
    )
    private var mapboxNavigation: MapboxNavigation {
        mapboxNavigationProvider.mapboxNavigation
    }

    private var navigationMapView: NavigationMapView!
    private var navigationMapViewStyleLoadedCancelable: Cancelable?
    private var navigationViewControllerStyleLoadedCancelable: Cancelable?
    private var startNavigationButton: UIButton!

    private var navigationRoutes: NavigationRoutes?
    private let customFinalWaypointDelegate = CustomFinalWaypointDelegate()

    // MARK: - UIViewController lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationMapView()
        setupStartNavigationButton()
        requestRoute()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        startNavigationButton.layer.cornerRadius = startNavigationButton.bounds.midY
        startNavigationButton.clipsToBounds = true
        startNavigationButton.setNeedsDisplay()
    }

    // MARK: - Setting-up methods

    private func setupNavigationMapView() {
        let navigationMapView = NavigationMapView(
            location: mapboxNavigation.navigation()
                .locationMatching.map(\.enhancedLocation)
                .eraseToAnyPublisher(),
            routeProgress: mapboxNavigation.navigation()
                .routeProgress.map(\.?.routeProgress)
                .eraseToAnyPublisher(),
            predictiveCacheManager: mapboxNavigationProvider.predictiveCacheManager
        )
        navigationMapView.puckType = .puck2D(.navigationDefault)
        navigationMapView.delegate = customFinalWaypointDelegate
        navigationMapView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(navigationMapView)

        NSLayoutConstraint.activate([
            navigationMapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationMapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationMapView.topAnchor.constraint(equalTo: view.topAnchor),
            navigationMapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        self.navigationMapView = navigationMapView
        navigationMapViewStyleLoadedCancelable = navigationMapView.mapView.mapboxMap.onStyleLoaded
            .observe { [weak self] _ in
                self?.navigationMapView.addFinalWaypointImage()
            }
    }

    private func setupStartNavigationButton() {
        startNavigationButton = UIButton()
        startNavigationButton.setTitle("Start Navigation", for: .normal)
        startNavigationButton.translatesAutoresizingMaskIntoConstraints = false
        startNavigationButton.backgroundColor = .white
        startNavigationButton.setTitleColor(.black, for: .highlighted)
        startNavigationButton.setTitleColor(.darkGray, for: .normal)
        startNavigationButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        startNavigationButton.addTarget(self, action: #selector(tappedButton(_:)), for: .touchUpInside)
        startNavigationButton.isHidden = true
        view.addSubview(startNavigationButton)

        startNavigationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
            .isActive = true
        startNavigationButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        view.setNeedsLayout()
    }

    @objc
    private func tappedButton(_ sender: UIButton) {
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
        navigationViewController.delegate = customFinalWaypointDelegate
        customFinalWaypointDelegate.navigationViewControllerDidDismiss = { [weak self] in
            self?.dismiss(animated: true)
        }
        navigationViewController.modalPresentationStyle = .fullScreen
        navigationViewControllerStyleLoadedCancelable = navigationViewController.navigationMapView?.mapView.mapboxMap
            .onStyleLoaded.observe { [weak navigationViewController] _ in
                navigationViewController?.navigationMapView?.addFinalWaypointImage()
            }

        present(navigationViewController, animated: true) {
            self.navigationMapView = nil
        }
    }

    private func requestRoute() {
        let origin = CLLocationCoordinate2DMake(37.77440680146262, -122.43539772352648)
        let firstWaypoint = CLLocationCoordinate2DMake(37.763252389415186, -122.40061448679577)
        let secondWaypoint = CLLocationCoordinate2DMake(37.76556957793795, -122.42409811526268)
        let options = NavigationRouteOptions(coordinates: [origin, firstWaypoint, secondWaypoint])

        navigationMapView.navigationCamera.stop()
        navigationMapView.mapView.mapboxMap.setCamera(to: CameraOptions(center: secondWaypoint, zoom: 13.0))

        Task { [weak self] in
            guard let self else { return }
            switch await mapboxNavigation.routingProvider().calculateRoutes(options: options).result {
            case .failure(let error):
                print("Failed to request route with error: \(error.localizedDescription)")
            case .success(let routes):
                navigationRoutes = routes

                startNavigationButton?.isHidden = false
                navigationMapView.showcase(routes)
            }
        }
    }
}

extension NavigationMapView {
    fileprivate func addFinalWaypointImage() {
        addImageIfNotExists(
            withId: CustomFinalWaypointDelegate.finalWaypointImageId,
            image: UIImage(named: "final_waypoint")!
        )
    }
}

extension MapboxMaps.Expression {
    private static func routeLineWidthExpression(_ multiplier: Double = 1.0) -> MapboxMaps.Expression {
        return Exp(.interpolate) {
            Exp(.linear)
            Exp(.zoom)
            RouteLineWidthByZoomLevel.multiplied(by: multiplier)
        }
    }

    fileprivate static func routeCasingLineWidthExpression(_ multiplier: Double = 1.0) -> MapboxMaps.Expression {
        routeLineWidthExpression(multiplier * 1.5)
    }
}

private final class CustomFinalWaypointDelegate {
    static let finalWaypointImageId = "final_waypoint_id"
    var navigationViewControllerDidDismiss: (() -> Void)?

    private func shapeForWaypoints(_ waypoints: [Waypoint], legIndex: Int) -> FeatureCollection? {
        var features = [Turf.Feature]()
        for (waypointIndex, waypoint) in waypoints.enumerated() {
            var feature = Feature(geometry: .point(Point(waypoint.coordinate)))
            var properties: [String: JSONValue] = [:]
            let isFinalWaypoint = waypointIndex == waypoints.count - 1
            let isCompletedWaypoint = waypointIndex <= legIndex
            properties["completedOrFinal"] = .boolean(isCompletedWaypoint || isFinalWaypoint)
            properties["completed"] = .boolean(isCompletedWaypoint)
            properties["imageId"] = isFinalWaypoint ? .string(Self.finalWaypointImageId) : nil
            feature.properties = properties
            features.append(feature)
        }

        return FeatureCollection(features: features)
    }

    private func waypointCircleLayerWithIdentifier(_ identifier: String, sourceIdentifier: String) -> CircleLayer? {
        var circleLayer = CircleLayer(id: identifier, source: sourceIdentifier)
        let opacity = Exp(.switchCase) {
            Exp(.any) {
                Exp(.get) {
                    "completedOrFinal"
                }
            }
            0
            1
        }
        circleLayer.circleColor = .constant(StyleColor(.white))
        circleLayer.circleOpacity = .expression(opacity)
        circleLayer.circleEmissiveStrength = .constant(1)
        circleLayer.circleRadius = .expression(.routeCasingLineWidthExpression(0.5))
        circleLayer.circleStrokeColor = .constant(StyleColor(#colorLiteral(red: 0.23, green: 0.26, blue: 0.33, alpha: 1)))
        circleLayer.circleStrokeWidth = .expression(.routeCasingLineWidthExpression(0.14))
        circleLayer.circleStrokeOpacity = .expression(opacity)
        circleLayer.circlePitchAlignment = .constant(.map)
        circleLayer.circleOpacity = .expression(opacity)
        return circleLayer
    }

    private func waypointSymbolLayerWithIdentifier(_ identifier: String, sourceIdentifier: String) -> SymbolLayer? {
        var symbolLayer = SymbolLayer(id: identifier, source: sourceIdentifier)
        symbolLayer.iconImage = .expression(Exp(.get) { "imageId" })
        symbolLayer.iconAnchor = .constant(.bottom)
        symbolLayer.iconOffset = .constant([0, 15])
        let opacity = Exp(.switchCase) {
            Exp(.any) {
                Exp(.get) {
                    "completed"
                }
            }
            0
            1
        }
        symbolLayer.iconOpacity = .expression(opacity)
        return symbolLayer
    }
}

extension CustomFinalWaypointDelegate: NavigationMapViewDelegate {
    func navigationMapView(
        _ navigationMapView: NavigationMapView,
        shapeFor waypoints: [Waypoint],
        legIndex: Int
    ) -> FeatureCollection? {
        shapeForWaypoints(waypoints, legIndex: legIndex)
    }

    func navigationMapView(
        _ navigationMapView: NavigationMapView,
        waypointCircleLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> CircleLayer? {
        waypointCircleLayerWithIdentifier(identifier, sourceIdentifier: sourceIdentifier)
    }

    func navigationMapView(
        _ navigationMapView: NavigationMapView,
        waypointSymbolLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> SymbolLayer? {
        waypointSymbolLayerWithIdentifier(identifier, sourceIdentifier: sourceIdentifier)
    }
}

extension CustomFinalWaypointDelegate: NavigationViewControllerDelegate {
    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        shapeFor waypoints: [Waypoint],
        legIndex: Int
    ) -> FeatureCollection? {
        shapeForWaypoints(waypoints, legIndex: legIndex)
    }

    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        waypointCircleLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> CircleLayer? {
        waypointCircleLayerWithIdentifier(identifier, sourceIdentifier: sourceIdentifier)
    }

    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        waypointSymbolLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> SymbolLayer? {
        waypointSymbolLayerWithIdentifier(identifier, sourceIdentifier: sourceIdentifier)
    }

    func navigationViewControllerDidDismiss(
        _ navigationViewController: NavigationViewController,
        byCanceling canceled: Bool
    ) {
        navigationViewControllerDidDismiss?()
    }
}
