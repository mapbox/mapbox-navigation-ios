import MapboxMaps
import MapboxNavigation

class CustomCameraStateTransition: CameraStateTransition {
    
    weak var mapView: MapView?
    
    required init(_ mapView: MapView) {
        self.mapView = mapView
    }
    
    func transitionToFollowing(_ cameraOptions: CameraOptions, completion: (() -> Void)?) {
        mapView?.cameraManager.setCamera(to: cameraOptions,
                                         animated: true,
                                         duration: 0.5,
                                         completion: { _ in
                                            completion?()
                                         })
    }
    
    func transitionToOverview(_ cameraOptions: CameraOptions, completion: (() -> Void)?) {
        mapView?.cameraManager.setCamera(to: cameraOptions,
                                         animated: true,
                                         duration: 0.5,
                                         completion: { _ in
                                            completion?()
                                         })
    }
    
    func updateForFollowing(_ cameraOptions: CameraOptions, completion: (() -> Void)?) {
        mapView?.cameraManager.setCamera(to: cameraOptions,
                                         animated: true,
                                         duration: 0.5,
                                         completion: { _ in
                                            completion?()
                                         })
    }
    
    func updateForOverview(_ cameraOptions: CameraOptions, completion: (() -> Void)?) {
        mapView?.cameraManager.setCamera(to: cameraOptions,
                                         animated: true,
                                         duration: 0.5,
                                         completion: { _ in
                                            completion?()
                                         })
    }
    
    func cancelPendingTransition() {
        mapView?.cameraManager.cancelTransitions()
    }
}
