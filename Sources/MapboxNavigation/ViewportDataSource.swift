import MapboxMaps

/**
 Protocol, which is used to fill and store `CameraOptions` which will be used by
 `NavigationCamera` for execution of transitions and continuous updates.
 
 By default Navigation SDK for iOS provides default implementation of `ViewportDataSource`
 in `NavigationViewportDataSource`.
 */
public protocol ViewportDataSource: AnyObject {
    
    /**
     Delegate, which is used to notify `NavigationCamera` regarding upcoming `CameraOptions`
     related changes.
     */
    var delegate: ViewportDataSourceDelegate? { get set }
    
    /**
     `CameraOptions`, which are used on iOS when transitioning to `NavigationCameraState.following` or
     for continuous updates when already in `NavigationCameraState.following` state.
     */
    var followingMobileCamera: CameraOptions { get }
    
    /**
     `CameraOptions`, which are used on CarPlay when transitioning to `NavigationCameraState.following` or
     for continuous updates when already in `NavigationCameraState.following` state.
     */
    var followingCarPlayCamera: CameraOptions { get }
    
    /**
     `CameraOptions`, which are used on iOS when transitioning to `NavigationCameraState.overview` or
     for continuous updates when already in `NavigationCameraState.overview` state.
     */
    var overviewMobileCamera: CameraOptions { get }
    
    /**
     `CameraOptions`, which are used on CarPlay when transitioning to `NavigationCameraState.overview` or
     for continuous updates when already in `NavigationCameraState.overview` state.
     */
    var overviewCarPlayCamera: CameraOptions { get }
}

/**
 Delegate, which is used to notify `NavigationCamera` regarding upcoming `CameraOptions`
 related changes.
 */
public protocol ViewportDataSourceDelegate: AnyObject {
    
    /**
     Notifies `NavigationCamera` that the camera options have changed in response to a location update.
     
     - parameter dataSource: Object, which conforms to `ViewportDataSource` protocol.
     - parameter cameraOptions: Dictionary, which contains `CameraOptions` objects for both iOS and CarPlay.
     */
    func viewportDataSource(_ dataSource: ViewportDataSource, didUpdate cameraOptions: [String: CameraOptions])
}
