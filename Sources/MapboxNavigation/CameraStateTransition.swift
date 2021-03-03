import MapboxMaps

public protocol CameraStateTransition {
    
    var mapView: MapView? { get }
    
    init(_ mapView: MapView)
    
    func transitionToFollowing(_ cameraOptions: CameraOptions, completion: ((Bool) -> Void)?)
    
    func transitionToOverview(_ cameraOptions: CameraOptions, completion: ((Bool) -> Void)?)
    
    func updateForFollowing(_ cameraOptions: CameraOptions, completion: ((Bool) -> Void)?)
    
    func updateForOverview(_ cameraOptions: CameraOptions, completion: ((Bool) -> Void)?)
}
