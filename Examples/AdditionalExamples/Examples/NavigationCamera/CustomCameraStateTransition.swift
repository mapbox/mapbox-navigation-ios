import MapboxMaps
import MapboxNavigationCore

/// Custom implementation of Navigation Camera transitions, which conforms to `CameraStateTransition` protocol.
///
/// To be able to use custom camera transitions user has to create instance of `CustomCameraStateTransition` and then
/// override with it default implementation, by modifying `NavigationMapView.navigationCamera.cameraStateTransition` or
/// `NavigationViewController.navigationMapView.navigationCamera.cameraStateTransition` properties.
///
/// By default Navigation SDK for iOS provides default implementation of `CameraStateTransition` in
/// `NavigationCameraStateTransition`.
class CustomCameraStateTransition: CameraStateTransition {
    weak var mapView: MapView?

    required init(_ mapView: MapView) {
        self.mapView = mapView
    }

    func transitionTo(_ cameraOptions: CameraOptions, completion: @escaping (() -> Void)) {
        mapView?.camera.ease(to: cameraOptions, duration: 0.5, curve: .linear, completion: { _ in
            completion()
        })
    }

    func update(to cameraOptions: CameraOptions, state: NavigationCameraState) {
        mapView?.camera.ease(to: cameraOptions, duration: 0.5, curve: .linear, completion: nil)
    }

    func cancelPendingTransition() {
        mapView?.camera.cancelAnimations()
    }
}
