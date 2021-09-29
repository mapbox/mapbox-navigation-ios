import MapboxMaps

/**
 Protocol, which is used to execute camera related transitions, based on data provided
 via `CameraOptions` in `ViewportDataSource`.
 
 By default Navigation SDK for iOS provides default implementation of `CameraStateTransition`
 in `NavigationCameraStateTransition`.
 */
public protocol CameraStateTransition: AnyObject {
    
    // MARK: Updating the Camera
    
    var mapView: MapView? { get }
    
    /**
     Initializer of `NavigationViewportDataSource` object.
     
     - parameter mapView: `MapView` object, on instance of which camera related transitions will be performed.
     */
    init(_ mapView: MapView)
    
    /**
     Method, which performs camera transition to the `NavigationCameraState.following` state.
     
     - parameter cameraOptions: Instance of `CameraOptions`, which describes viewpoint of the `MapView`.
     - parameter completion: Completion handler, which is called after performing transition.
     */
    func transitionToFollowing(_ cameraOptions: CameraOptions, completion: @escaping (() -> Void))
    
    /**
     Method, which performs camera transition to the `NavigationCameraState.overview` state.
     
     - parameter cameraOptions: Instance of `CameraOptions`, which describes viewpoint of the `MapView`.
     - parameter completion: Completion handler, which is called after performing transition.
     */
    func transitionToOverview(_ cameraOptions: CameraOptions, completion: @escaping (() -> Void))
    
    /**
     Method, which performs camera update, when already in the `NavigationCameraState.overview` state or `NavigationCameraState.following` state.
     
     - parameter cameraOptions: Instance of `CameraOptions`, which describes viewpoint of the `MapView`.
     - parameter state: Instance of `NavigationCameraState`, which describes the current state of `NavigationCamera`.
     */
    func update(to cameraOptions: CameraOptions, state: NavigationCameraState)
    
    /**
     Method, which cancels current transition.
     */
    func cancelPendingTransition()
}
