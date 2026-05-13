/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios
 To learn more about the SDK, see our docs: https://docs.mapbox.com/ios/navigation
 */

import Combine
import CoreLocation
@_spi(ExperimentalMapboxAPI) import MapboxDirections
@_spi(MapboxInternal) import MapboxNavigationCore
@_spi(ExperimentalMapboxAPI) import MapboxNavigationCppRoadCameras
import MapboxNavigationUIKit
import UIKit

final class RoadCamerasViewController: UIViewController {
    private let mapboxNavigationProvider = MapboxNavigationProvider(
        coreConfig: .init(
            locationSource: simulationIsEnabled ? .simulation(
                initialLocation: .init(
                    latitude: 40.77053971750702,
                    longitude: -73.9480517819519
                )
            ) : .live
        )
    )

    private var mapboxNavigation: MapboxNavigation {
        mapboxNavigationProvider.mapboxNavigation
    }

    private var roadCameraManager: RoadCamerasManager?
    private var roadCameraMapController: RoadCamerasMapController?
    private var subscriptions: [AnyCancellable] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        let origin = CLLocationCoordinate2DMake(40.77053971750702, -73.9480517819519)
        let destination = CLLocationCoordinate2DMake(40.78434130172868, -73.977347856413)
        let options = NavigationRouteOptions(coordinates: [origin, destination])
        // Request road camera data in the Directions API response.
        options.attributeOptions.insert(.roadCamera)

        let request = mapboxNavigation.routingProvider().calculateRoutes(options: options)

        Task { [weak self] in
            guard let self else { return }
            switch await request.result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let navigationRoutes):
                let navigationOptions = NavigationOptions(
                    mapboxNavigation: mapboxNavigation,
                    voiceController: mapboxNavigationProvider.routeVoiceController,
                    eventsManager: mapboxNavigationProvider.eventsManager()
                )
                let navigationViewController = NavigationViewController(
                    navigationRoutes: navigationRoutes,
                    navigationOptions: navigationOptions
                )
                navigationViewController.modalPresentationStyle = .fullScreen
                navigationViewController.routeLineTracksTraversal = true

                setupRoadCameras(on: navigationViewController)

                present(navigationViewController, animated: true, completion: nil)
            }
        }
    }

    @MainActor
    private func setupRoadCameras(on navigationViewController: NavigationViewController) {
        guard
            let mapboxMap = navigationViewController.navigationMapView?.mapView.mapboxMap,
            let manager = RoadCamerasManager(navigator: mapboxNavigationProvider.nativeNavigator)
        else {
            return
        }

        let config = RoadCamerasConfig(
            displayConfig: RoadCamerasDisplayConfig(
                startShowDistance: 1000,
            ),
            iconProvider: ExampleRoadCamerasIconProvider() // pass nil, for default behavior
        )

        let mapController = RoadCamerasMapController(
            map: mapboxMap,
            manager: manager,
            config: config
        )

        roadCameraManager = manager
        roadCameraMapController = mapController

        manager.camerasAppearing
            .sink { print("Road cameras distance \($0.first?.distance ?? 0).") }
            .store(in: &subscriptions)

        manager.camerasPassed
            .sink { _ in print("Road cameras passed.") }
            .store(in: &subscriptions)

        manager.camerasHidden
            .sink { _ in print("Road cameras should be hidden.") }
            .store(in: &subscriptions)

        manager.speedZoneProgress
            .sink { _ in print("Speed zone progress.") }
            .store(in: &subscriptions)

        manager.speedZoneExited
            .sink { _ in print("Speed zone exit.") }
            .store(in: &subscriptions)

        mapController.cameraClicked
            .sink { camera in print("Road camera clicked: \(camera.id)") }
            .store(in: &subscriptions)
    }
}

// MARK: - ExampleRoadCamerasIconProvider

private class ExampleRoadCamerasIconProvider: RoadCamerasIconProvider {
    func provideIcon(for roadCamera: MapboxNavigationCppRoadCameras.RoadCamera) -> RoadCameraStyle? {
        let icon = UIImage(named: "intermediate_waypoint") ?? UIImage()
        return RoadCameraStyle(image: icon, imageOffset: .init(x: 0, y: -17))
    }
}
