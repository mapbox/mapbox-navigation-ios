import Combine
import MapboxMaps
import MapboxNavigationCore
import MapboxNavigationUIKit
import UIKit

/// Custom implementation of Navigation Camera data source, which is used to fill and store `CameraOptions` which will
/// be later used by `CustomCameraStateTransition` for execution of transitions and continuous camera updates.
///
/// To be able to use custom camera data source user has to create instance of `CustomCameraStateTransition`and then
/// override with it default implementation, by modifying `NavigationMapView.navigationCamera.viewportDataSource` or
/// `navigationViewController.navigationMapView.navigationCamera.viewportDataSource` properties.
///
/// By default Navigation SDK for iOS provides default implementation of `ViewportDataSource` in
/// `NavigationViewportDataSource`.
class CustomViewportDataSource: ViewportDataSource {
    var options: MapboxNavigationCore.NavigationViewportDataSourceOptions = .init()

    var navigationCameraOptions: AnyPublisher<NavigationCameraOptions, Never> {
        _navigationCameraOptions.eraseToAnyPublisher()
    }

    var currentNavigationCameraOptions: NavigationCameraOptions {
        get { _navigationCameraOptions.value }
        set { _navigationCameraOptions.value = newValue }
    }

    private var _navigationCameraOptions: CurrentValueSubject<NavigationCameraOptions, Never> = .init(.init())

    weak var mapView: MapView?

    // MARK: - Initializer methods

    public required init(_ mapView: MapView) {
        self.mapView = mapView
    }

    public func update(using viewportState: MapboxNavigationCore.ViewportState) {
        let newOptions = NavigationCameraOptions(
            followingCamera: newFollowingCamera(with: viewportState),
            overviewCamera: newOverviewCamera(with: viewportState)
        )
        if newOptions != currentNavigationCameraOptions {
            _navigationCameraOptions.send(newOptions)
        }
    }

    private func newFollowingCamera(with state: MapboxNavigationCore.ViewportState) -> CameraOptions {
        var followingMobileCamera = currentNavigationCameraOptions.followingCamera

        followingMobileCamera.center = state.location.coordinate
        // Set the bearing of the `MapView` (measured in degrees clockwise from true north).
        followingMobileCamera.bearing = state.location.course
        followingMobileCamera.padding = .zero
        followingMobileCamera.zoom = 15.0
        followingMobileCamera.pitch = 45.0

        return followingMobileCamera
    }

    private func newOverviewCamera(with state: MapboxNavigationCore.ViewportState) -> CameraOptions {
        guard let mapView else { return .init() }

        var overviewCameraOptions = currentNavigationCameraOptions.overviewCamera
        let initialCameraOptions = CameraOptions(
            padding: .zero,
            bearing: 0.0,
            pitch: 0.0
        )

        if let shape = state.routeProgress?.route.shape, let cameraOptions = try? mapView.mapboxMap.camera(
            for: shape.coordinates.compactMap { $0 },
            camera: initialCameraOptions,
            coordinatesPadding: UIEdgeInsets(
                top: 150.0,
                left: 10.0,
                bottom: 150.0,
                right: 10.0
            ),
            maxZoom: nil,
            offset: nil
        ) {
            overviewCameraOptions = cameraOptions
        }

        return overviewCameraOptions
    }
}
