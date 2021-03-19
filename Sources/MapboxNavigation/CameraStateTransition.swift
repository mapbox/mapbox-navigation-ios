import MapboxMaps

public protocol CameraStateTransition {
    
    var mapView: MapView? { get }
    
    init(_ mapView: MapView)
    
    func transitionToFollowing(_ cameraOptions: CameraOptions, completion: @escaping (() -> Void))
    
    func transitionToOverview(_ cameraOptions: CameraOptions, completion: @escaping (() -> Void))
    
    func updateForFollowing(_ cameraOptions: CameraOptions)
    
    func updateForOverview(_ cameraOptions: CameraOptions)
    
    func cancelPendingTransition()
}
