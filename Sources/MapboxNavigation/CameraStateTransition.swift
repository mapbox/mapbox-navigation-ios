import MapboxMaps

public protocol CameraStateTransition {
    
    var mapView: MapView? { get }
    
    init(_ mapView: MapView)
    
    func transitionToFollowing(_ cameraOptions: CameraOptions, completion: (() -> Void)?)
    
    func transitionToOverview(_ cameraOptions: CameraOptions, completion: (() -> Void)?)
    
    func updateForFollowing(_ cameraOptions: CameraOptions, completion: (() -> Void)?)
    
    func updateForOverview(_ cameraOptions: CameraOptions, completion: (() -> Void)?)
    
    func cancelPendingTransition()
}
