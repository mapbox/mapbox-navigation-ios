import Combine
import CoreLocation
import Foundation
import MapboxMaps
import MapboxNavigationCore
import UIKit

@MainActor
final class MapViewController: UIViewController {
    private static let styleUrl = "mapbox://styles/mapbox-dash/standard-navigation"

    private let navigation: Navigation
    private let navigationMapView: NavigationMapView

    private var lifetimeSubscriptions: Set<AnyCancellable> = []

    init(navigation: Navigation) {
        self.navigation = navigation

        self.navigationMapView = NavigationMapView(
            location: navigation.$currentLocation.compactMap { $0 }.eraseToAnyPublisher(),
            routeProgress: navigation.$routeProgress.eraseToAnyPublisher(),
            predictiveCacheManager: navigation.predictiveCacheManager
        )

        // Customize viewport padding
        navigationMapView.viewportPadding = UIEdgeInsets(top: 20, left: 20, bottom: 80, right: 20)

        super.init(nibName: nil, bundle: nil)

        setupMapView()
        observePreviewRoute()
        observeCamera()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        Task {
            navigation.cameraState = .following
            navigation.startFreeDrive()
        }
    }

    override func loadView() {
        view = navigationMapView
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupMapView() {
        navigationMapView.mapView.mapboxMap.loadStyle(StyleURI(rawValue: Self.styleUrl)!)
        navigationMapView.mapView.ornaments.compassView.isHidden = true
        navigationMapView.delegate = self
        // Possible configuration
        navigationMapView.showsTrafficOnRouteLine = true
    }

    private func observePreviewRoute() {
        navigation.$currentPreviewRoutes
            .removeDuplicates()
            .combineLatest(navigation.$activeNavigationRoutes)
            .dropFirst()
            .sink { [weak self] previewRoutes, routes in
                guard let self else { return }
                if let previewRoutes {
                    navigationMapView.showcase(
                        previewRoutes,
                        routeAnnotationKinds: [.routeDurations],
                        animated: true
                    )
                } else if let routes {
                    navigationMapView.show(routes, routeAnnotationKinds: [.relativeDurationsOnAlternativeManuever])
                } else {
                    navigationMapView.removeRoutes()
                }
            }
            .store(in: &lifetimeSubscriptions)
    }

    func observeCamera() {
        navigation.$cameraState
            .removeDuplicates()
            .sink { [weak self] cameraState in
                self?.navigationMapView.update(navigationCameraState: cameraState)
            }.store(in: &lifetimeSubscriptions)
    }

    private func presentAlert(_ title: String? = nil, message: String? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            alertController.dismiss(animated: true, completion: nil)
        }))

        present(alertController, animated: true, completion: nil)
    }

    private func requestRoute(to mapPoint: MapPoint) async {
        do {
            try await navigation.requestRoutes(to: mapPoint)
        } catch {
            presentAlert(message: "Request failed: \(error.localizedDescription)")
        }
    }
}

extension MapViewController: NavigationMapViewDelegate {
    func navigationMapView(_ navigationMapView: NavigationMapView, didSelect alternativeRoute: AlternativeRoute) {
        Task {
            await navigation.selectAlternativeRoute(alternativeRoute)
        }
    }

    func navigationMapView(_ navigationMapView: NavigationMapView, userDidTap mapPoint: MapPoint) {
        Task { await requestRoute(to: mapPoint) }
    }

    func navigationMapView(_ navigationMapView: NavigationMapView, userDidLongTap mapPoint: MapPoint) {
        Task { await requestRoute(to: mapPoint) }
    }
}
