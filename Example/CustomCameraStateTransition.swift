import MapboxMaps
import MapboxNavigation

class CustomCameraStateTransition: CameraStateTransition {
    weak var mapView: MapView?
    
    required init(_ mapView: MapView) {
        self.mapView = mapView
    }
    
    func transitionToFollowing(_ cameraOptions: CameraOptions, completion: ((Bool) -> Void)?) {
        mapView?.cameraManager.setCamera(to: cameraOptions,
                                         animated: true,
                                         duration: 0.5,
                                         completion: completion)
    }
    
    func transitionToOverview(_ cameraOptions: CameraOptions, completion: ((Bool) -> Void)?) {
        mapView?.cameraManager.setCamera(to: cameraOptions,
                                         animated: true,
                                         duration: 0.5,
                                         completion: completion)
    }
    
    func updateForFollowing(_ cameraOptions: CameraOptions, completion: ((Bool) -> Void)?) {
        mapView?.cameraManager.setCamera(to: cameraOptions,
                                         animated: true,
                                         duration: 0.5,
                                         completion: completion)
    }
    
    func updateForOverview(_ cameraOptions: CameraOptions, completion: ((Bool) -> Void)?) {
        mapView?.cameraManager.setCamera(to: cameraOptions,
                                         animated: true,
                                         duration: 0.5,
                                         completion: completion)
    }
}
