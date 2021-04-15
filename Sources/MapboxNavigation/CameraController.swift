import MapboxDirections
import MapboxCoreNavigation
import MapboxMaps

/// A component to ease camera manipulation logic.
///
/// This class manages various scenarious from moving camera to a specific region on demand and handling device rotation, up to reacting to active guidance events.
class CameraController: NavigationComponent, NavigationComponentDelegate {
    
    // MARK: - Properties
    
    weak private(set) var navigationViewData: NavigationViewData!
    
    private var navigationMapView: NavigationMapView {
        return navigationViewData.navigationView.navigationMapView
    }
    private var router: Router! {
        navigationViewData.navigationService.router
    }
    private var topBannerContainerView: BannerContainerView {
        return navigationViewData.navigationView.topBannerContainerView
    }
    
    private var bottomBannerContainerView: BannerContainerView {
        return navigationViewData.navigationView.bottomBannerContainerView
    }
    
    // MARK: - Methods
    
    init(_ navigationViewData: NavigationViewData) {
        self.navigationViewData = navigationViewData
        
    }
    
    private func resumeNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationDidChange(_:)),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(navigationCameraStateDidChange(_:)),
                                               name: .navigationCameraStateDidChange,
                                               object: navigationMapView.navigationCamera)
    }

    private func suspendNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIDevice.orientationDidChangeNotification,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: .navigationCameraStateDidChange,
                                                  object: nil)
    }
    
    @objc func overview(_ sender: Any) {
        navigationMapView.navigationCamera.moveToOverview()
//        navigationMapView.navigationCamera.requestNavigationCameraToOverview()
    }
    
    @objc func recenter(_ sender: AnyObject) {
        recenter(sender, completion: nil)
    }
    
    func recenter(_ sender: AnyObject, completion: ((CameraController, CLLocation)->())?) {
        guard let location = navigationMapView.mostRecentUserCourseViewLocation else { return }
        
        navigationMapView.updateUserCourseView(location)
        completion?(self, location)
        
        navigationMapView.navigationCamera.follow()
//        navigationMapView.navigationCamera.requestNavigationCameraToFollowing()
        navigationMapView.addArrow(route: router.route,
                                   legIndex: router.routeProgress.legIndex,
                                   stepIndex: router.routeProgress.currentLegProgress.stepIndex + 1)
    }
    
    func center(on step: RouteStep, route: Route, legIndex: Int, stepIndex: Int, animated: Bool = true, completion: CompletionHandler? = nil) {
        
        // TODO: Verify that camera is positioned correctly.
        let camera = CameraOptions(center: step.maneuverLocation,
                                   zoom: navigationMapView.mapView.zoom,
                                   bearing: step.initialHeading ?? CLLocationDirection(navigationMapView.mapView.bearing))
        
        navigationMapView.mapView.cameraManager.setCamera(to: camera,
                                                          animated: animated,
                                                          duration: animated ? 1 : 0) { _ in
            completion?()
        }
        
        navigationMapView.addArrow(route: router.routeProgress.route, legIndex: legIndex, stepIndex: stepIndex)
    }
    
    @objc func orientationDidChange(_ notification: Notification) {
        updateNavigationCameraViewport()
    }
    
    @objc func navigationCameraStateDidChange(_ notification: Notification) {
        guard let navigationCameraState = notification.userInfo?[NavigationCamera.NotificationUserInfoKey.state] as? NavigationCameraState else { return }
        
        updateNavigationCameraViewport()
        
        switch navigationCameraState {
        case .transitionToFollowing, .following:
            navigationViewData.navigationView.overviewButton.isHidden = false
            navigationViewData.navigationView.resumeButton.isHidden = true
            navigationViewData.navigationView.wayNameView.isHidden = false
            break
        case .idle, .transitionToOverview, .overview:
            navigationViewData.navigationView.overviewButton.isHidden = true
            navigationViewData.navigationView.resumeButton.isHidden = false
            navigationViewData.navigationView.wayNameView.isHidden = true
            break
        }
    }
    
    func updateNavigationCameraViewport() {
        if let navigationViewportDataSource = navigationMapView.navigationCamera.viewportDataSource as? NavigationViewportDataSource {
            navigationViewportDataSource.viewportPadding = viewportPadding
        }
    }

    var viewportPadding: UIEdgeInsets {
        let courseViewMinimumInsets = UIEdgeInsets(top: 75.0, left: 75.0, bottom: 75.0, right: 75.0)
        var insets = navigationMapView.mapView.safeArea
        insets += courseViewMinimumInsets
        insets.top += topBannerContainerView.bounds.height
        insets.bottom += bottomBannerContainerView.bounds.height
    
        return insets
    }
    
    // MARK: - NavigationComponent implementation
    
    func navigationService(_ service: NavigationService, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        updateNavigationCameraViewport()
    }
    
    // MARK: - NavigationComponentDelegate implementation
    
    func navigationViewDidLoad(_: UIView) {
        navigationViewData.navigationView.overviewButton.addTarget(self, action: #selector(overview(_:)), for: .touchUpInside)
        navigationViewData.navigationView.resumeButton.addTarget(self, action: #selector(recenter(_:)), for: .touchUpInside)
        
        self.navigationMapView.userCourseView.isHidden = false
        self.navigationViewData.navigationView.resumeButton.isHidden = true
    }
    
    func navigationViewWillAppear(_: Bool) {
        resumeNotifications()
        
        navigationMapView.mapView.update {
            $0.ornaments.showsCompass = false
        }

        navigationMapView.navigationCamera.follow()
//        navigationMapView.navigationCamera.requestNavigationCameraToFollowing()
    }
    
    func navigationViewDidDisappear(_: Bool) {
        suspendNotifications()
    }
}
