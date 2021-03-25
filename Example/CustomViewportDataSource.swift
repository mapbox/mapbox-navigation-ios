import MapboxMaps
import MapboxNavigation
import MapboxCoreNavigation

class CustomViewportDataSource: ViewportDataSource {
    
    public var delegate: ViewportDataSourceDelegate?
    
    public var followingMobileCamera: CameraOptions = CameraOptions()
    
    public var followingHeadUnitCamera: CameraOptions = CameraOptions()

    public var overviewMobileCamera: CameraOptions = CameraOptions()
    
    public var overviewHeadUnitCamera: CameraOptions = CameraOptions()
    
    weak var mapView: MapView?
    
    // MARK: - Initializer methods
    
    public required init(_ mapView: MapView) {
        self.mapView = mapView
        self.mapView?.locationManager.addLocationConsumer(newConsumer: self)
        
        subscribeForNotifications()
    }
    
    deinit {
        unsubscribeFromNotifications()
    }
    
    // MARK: - Notifications observer methods
    
    func subscribeForNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(progressDidChange(_:)),
                                               name: .routeControllerProgressDidChange,
                                               object: nil)
    }
    
    func unsubscribeFromNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .routeControllerProgressDidChange,
                                                  object: nil)
    }
    
    @objc func progressDidChange(_ notification: NSNotification) {
        let location = notification.userInfo?[RouteController.NotificationUserInfoKey.locationKey] as? CLLocation
        let routeProgress = notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress
        let cameraOptions = self.cameraOptions(location, routeProgress: routeProgress)
        
        delegate?.viewportDataSource(self, didUpdate: cameraOptions)
    }
    
    func cameraOptions(_ location: CLLocation?, routeProgress: RouteProgress? = nil) -> [String: CameraOptions] {
        followingMobileCamera.center = location?.coordinate
        followingMobileCamera.bearing = location?.course
        followingMobileCamera.padding = .zero
        followingMobileCamera.zoom = 14.0
        followingMobileCamera.pitch = 0.0
        
        overviewMobileCamera.center = location?.coordinate
        overviewMobileCamera.bearing = 0.0
        overviewMobileCamera.padding = .zero
        overviewMobileCamera.zoom = 10.0
        overviewMobileCamera.pitch = 0.0
        
        let cameraOptions = [
            CameraOptions.followingMobileCameraKey: followingMobileCamera,
            CameraOptions.overviewMobileCameraKey: overviewMobileCamera
        ]
        
        return cameraOptions
    }
}

// MARK: - LocationConsumer delegate

extension CustomViewportDataSource: LocationConsumer {
    
    var shouldTrackLocation: Bool {
        get {
            return true
        }
        set(newValue) {
            // No-op
        }
    }

    func locationUpdate(newLocation: Location) {
        let cameraOptions = self.cameraOptions(newLocation.internalLocation)
        delegate?.viewportDataSource(self, didUpdate: cameraOptions)
    }
}
