
import Foundation
import MapboxMaps
import MapboxNavigationCore
import MapboxNavigationUIKit
import UIKit

final class CustomDestinationMarkerController: UIViewController {
    static let customMarkerImage = "marker"

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
    private var startNavigationButton: UIButton!

    private var navigationRoutes: NavigationRoutes?

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
        navigationMapView.delegate = self
        navigationMapView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(navigationMapView)

        NSLayoutConstraint.activate([
            navigationMapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationMapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationMapView.topAnchor.constraint(equalTo: view.topAnchor),
            navigationMapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        self.navigationMapView = navigationMapView
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
        navigationViewController.delegate = self
        navigationViewController.modalPresentationStyle = .fullScreen

        present(navigationViewController, animated: true) {
            self.navigationMapView = nil
        }
    }

    private func requestRoute() {
        let origin = CLLocationCoordinate2DMake(37.77440680146262, -122.43539772352648)
        let destination = CLLocationCoordinate2DMake(37.76556957793795, -122.42409811526268)
        let options = NavigationRouteOptions(coordinates: [origin, destination])

        navigationMapView.navigationCamera.stop()
        navigationMapView.mapView.mapboxMap.setCamera(to: CameraOptions(center: destination, zoom: 13.0))

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

// MARK: - NavigationMapViewDelegate methods

extension CustomDestinationMarkerController: NavigationMapViewDelegate {
    // Delegate method, which is called whenever final destination `PointAnnotation` is added to `NavigationMapView`.
    func navigationMapView(
        _ navigationMapView: NavigationMapView,
        didAdd finalDestinationAnnotation: PointAnnotation,
        pointAnnotationManager: PointAnnotationManager
    ) {
        customize(
            navigationMapView: navigationMapView,
            finalDestinationAnnotation: finalDestinationAnnotation,
            pointAnnotationManager: pointAnnotationManager
        )
    }
}

// MARK: - NavigationViewControllerDelegate methods

extension CustomDestinationMarkerController: NavigationViewControllerDelegate {
    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didAdd finalDestinationAnnotation: PointAnnotation,
        pointAnnotationManager: PointAnnotationManager
    ) {
        guard let navigationMapView = navigationViewController.navigationMapView else { return }
        customize(
            navigationMapView: navigationMapView,
            finalDestinationAnnotation: finalDestinationAnnotation,
            pointAnnotationManager: pointAnnotationManager
        )
    }

    func navigationViewControllerDidDismiss(
        _ navigationViewController: NavigationViewController,
        byCanceling canceled: Bool
    ) {
        dismiss(animated: true)
    }
}

extension CustomDestinationMarkerController {
    private func customize(
        navigationMapView: NavigationMapView,
        finalDestinationAnnotation: PointAnnotation,
        pointAnnotationManager: PointAnnotationManager
    ) {
        var finalDestinationAnnotation = finalDestinationAnnotation
        if let image = UIImage(named: "marker") {
            // Adds the image to be used in the map style.
            try? navigationMapView.mapView.mapboxMap.addImage(image, id: Self.customMarkerImage)
            finalDestinationAnnotation.image = .init(image: image, name: Self.customMarkerImage)
            finalDestinationAnnotation.iconAnchor = .center
            finalDestinationAnnotation.iconOffset = [0, 0]
        }

        // `PointAnnotationManager` is used to manage `PointAnnotation`s and is also exposed as
        // a property in `NavigationMapView.pointAnnotationManager`. After any modifications to the
        // `PointAnnotation` changes must be applied to `PointAnnotationManager.annotations`
        // array. To remove all annotations for specific `PointAnnotationManager`, set an empty array.
        pointAnnotationManager.annotations = [finalDestinationAnnotation]
    }
}
