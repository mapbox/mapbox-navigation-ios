import MapboxMaps
import MapboxNavigation
import MapboxCoreNavigation

class CustomViewportDataSource: ViewportDataSource {
    
    public var delegate: ViewportDataSourceDelegate?
    
    public var followingMobileCamera: CameraOptions = CameraOptions()
    
    public var followingHeadUnitCamera: CameraOptions = CameraOptions()

    public var overviewMobileCamera: CameraOptions = CameraOptions()
    
    public var overviewHeadUnitCamera: CameraOptions = CameraOptions()
    
    var previousLocation: CLLocation?
    
    weak var mapView: MapView?
    
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
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(progressDidChange(_:)),
                                               name: .passiveLocationDataSourceDidUpdate,
                                               object: nil)
    }
    
    func unsubscribeFromNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .routeControllerProgressDidChange,
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: .passiveLocationDataSourceDidUpdate,
                                                  object: nil)
    }
    
    @objc func progressDidChange(_ notification: NSNotification) {
        let activeLocation = notification.userInfo?[RouteController.NotificationUserInfoKey.locationKey] as? CLLocation
        let routeProgress = notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress
        let passiveLocation = notification.userInfo?[PassiveLocationDataSource.NotificationUserInfoKey.locationKey] as? CLLocation
        let cameraOptions = self.cameraOptions(passiveLocation ?? activeLocation, routeProgress: routeProgress)
        delegate?.viewportDataSource(self, didUpdate: cameraOptions)
    }
    
    func cameraOptions(_ location: CLLocation?, routeProgress: RouteProgress? = nil) -> [String: CameraOptions] {
        followingMobileCamera.center = location?.coordinate
        followingMobileCamera.bearing = location?.course
        followingMobileCamera.padding = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        followingMobileCamera.zoom = 14.0
        followingMobileCamera.pitch = 0.0
        
        overviewMobileCamera.center = location?.coordinate
        overviewMobileCamera.bearing = 0.0
        overviewMobileCamera.padding = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        overviewMobileCamera.zoom = 10.0
        overviewMobileCamera.pitch = 0.0
        
        let cameraOptions = [
            CameraOptions.followingMobileCameraKey: followingMobileCamera,
            CameraOptions.overviewMobileCameraKey: overviewMobileCamera,
            CameraOptions.followingHeadUnitCameraKey: followingHeadUnitCamera,
            CameraOptions.overviewHeadUnitCameraKey: overviewHeadUnitCamera
        ]
        
        return cameraOptions
    }
}

extension CustomViewportDataSource: LocationConsumer {
    
    var shouldTrackLocation: Bool {
        get {
            return true
        }
        set(newValue) {
            self.shouldTrackLocation = newValue
        }
    }

    func locationUpdate(newLocation: Location) {
        let cameraOptions = self.cameraOptions(newLocation.internalLocation)
        delegate?.viewportDataSource(self, didUpdate: cameraOptions)
    }
}
