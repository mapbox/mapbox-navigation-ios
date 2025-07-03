import MapboxNavigationCore
import MapboxNavigationUIKit
import SwiftUI
import UIKit

class NavigationMapViewController: UIViewController {
    let navigationMapView: NavigationMapView
    let mapboxNavigation: MapboxNavigationProvider
    let loader: NavigationLoader

    init(mapboxNavigation: MapboxNavigationProvider) {
        self.mapboxNavigation = mapboxNavigation
        self.loader = NavigationLoader(mapboxNavigation: mapboxNavigation)
        self.navigationMapView = NavigationMapView(
            location: mapboxNavigation.navigation()
                .locationMatching.map(\.enhancedLocation)
                .eraseToAnyPublisher(),
            routeProgress: mapboxNavigation.navigation()
                .routeProgress.map(\.?.routeProgress)
                .eraseToAnyPublisher(),
            predictiveCacheManager: mapboxNavigation.predictiveCacheManager
        )
        super.init(nibName: nil, bundle: nil)
        navigationMapView.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addConstrained(child: navigationMapView)
        navigationMapView.viewportPadding = UIEdgeInsets(top: 20, left: 20, bottom: 100, right: 20)
    }

    fileprivate func requestRoute(to mapPoint: MapPoint) async {
        guard let routes = try? await loader.requestRoutes(to: mapPoint.coordinate) else {
            // handle error
            return
        }

        let navigationOptions = NavigationOptions(
            mapboxNavigation: mapboxNavigation,
            voiceController: mapboxNavigation.routeVoiceController,
            eventsManager: mapboxNavigation.eventsManager(),
            styles: [StandardDayStyle(), StandardNightStyle()],
            predictiveCacheManager: mapboxNavigation.predictiveCacheManager,
            // Reuse the NavigationMapView.
            navigationMapView: navigationMapView
        )
        // start active guidance
        let activeNavigationController = NavigationViewController(
            navigationRoutes: routes,
            navigationOptions: navigationOptions
        )
        activeNavigationController.delegate = self
        navigationController?.pushViewController(activeNavigationController, animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareNavigationViewReuse()
    }

    fileprivate func prepareNavigationViewReuse() {
        navigationMapView.delegate = self
        view.addConstrained(child: navigationMapView)
        // Re-start Free drive
        mapboxNavigation.tripSession().startFreeDrive()
    }
}

extension NavigationMapViewController: NavigationMapViewDelegate {
    func navigationMapView(_ navigationMapView: NavigationMapView, userDidTap mapPoint: MapPoint) {
        Task { await requestRoute(to: mapPoint) }
    }

    func navigationMapView(_ navigationMapView: NavigationMapView, userDidLongTap mapPoint: MapPoint) {
        Task { await requestRoute(to: mapPoint) }
    }
}

extension NavigationMapViewController: NavigationViewControllerDelegate {
    func navigationViewControllerDidDismiss(
        _ navigationViewController: NavigationViewController,
        byCanceling canceled: Bool
    ) {
        navigationController?.popViewController(animated: false)
        prepareNavigationViewReuse()
    }
}
