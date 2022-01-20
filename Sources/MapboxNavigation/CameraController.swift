import MapboxDirections
import MapboxCoreNavigation
import MapboxMaps

/// A component to ease camera manipulation logic.
///
/// This class manages various scenarious from moving camera to a specific region on demand and handling device rotation, up to reacting to active guidance events.
class CameraController: NavigationComponent, NavigationComponentDelegate {
    
    // MARK: Properties
    
    weak private(set) var navigationViewData: NavigationViewData!
    
    private var navigationMapView: NavigationMapView {
        return navigationViewData.navigationView.navigationMapView
    }
    private var router: Router {
        navigationViewData.router
    }
    private var topBannerContainerView: BannerContainerView {
        return navigationViewData.navigationView.topBannerContainerView
    }
    
    private var bottomBannerContainerView: BannerContainerView {
        return navigationViewData.navigationView.bottomBannerContainerView
    }
    
    // MARK: Methods
    
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
    }
    
    @objc func recenter(_ sender: AnyObject) {
        recenter(sender, completion: nil)
    }
    
    func recenter(_ sender: AnyObject, completion: ((CameraController, CLLocation) -> ())?) {
        guard let location = navigationMapView.mostRecentUserCourseViewLocation else { return }

        navigationMapView.moveUserLocation(to: location)
        completion?(self, location)

        navigationMapView.navigationCamera.follow()
        navigationMapView.addArrow(route: router.route,
                                   legIndex: router.routeProgress.legIndex,
                                   stepIndex: router.routeProgress.currentLegProgress.stepIndex + 1)
        
        let navigationViewController = navigationViewData.containerViewController as? NavigationViewController
        navigationViewController?.navigationComponents.compactMap({ $0 as? NavigationMapInteractionObserver }).forEach { $0.navigationViewController(didCenterOn: location) }
    }
    
    func center(on step: RouteStep,
                route: Route,
                legIndex: Int,
                stepIndex: Int,
                animated: Bool = true,
                completion: CompletionHandler? = nil) {
        navigationMapView.navigationCamera.stop()
        
        let edgeInsets = navigationMapView.safeArea + UIEdgeInsets.centerEdgeInsets
        let cameraOptions = CameraOptions(center: step.maneuverLocation,
                                          padding: edgeInsets,
                                          zoom: navigationMapView.mapView.cameraState.zoom,
                                          bearing: step.initialHeading ?? navigationMapView.mapView.cameraState.bearing)
        
        navigationMapView.mapView.camera.ease(to: cameraOptions,
                                              duration: animated ? 1.0 : 0.0) { (animatingPosition) in
            if animatingPosition == .end {
                completion?()
            }
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
            if let _ = navigationViewData.navigationView.wayNameView.text?.nonEmptyString {
                navigationViewData.navigationView.wayNameView.containerView.isHidden = false
            }
            break
        case .idle, .transitionToOverview, .overview:
            navigationViewData.navigationView.overviewButton.isHidden = true
            navigationViewData.navigationView.resumeButton.isHidden = false
            navigationViewData.navigationView.wayNameView.containerView.isHidden = true
            break
        }
    }
    
    private func updateNavigationCameraViewport() {
        if let navigationViewportDataSource = navigationMapView.navigationCamera.viewportDataSource as? NavigationViewportDataSource {
            navigationViewportDataSource.viewportPadding = viewportPadding
        }
    }

    private var viewportPadding: UIEdgeInsets {
        let courseViewMinimumInsets = UIEdgeInsets(top: 75.0, left: 75.0, bottom: 75.0, right: 75.0)
        var insets = navigationMapView.mapView.safeArea
        insets += courseViewMinimumInsets
        
        switch navigationViewData.navigationView.traitCollection.verticalSizeClass {
        case .unspecified:
            fallthrough
        case .regular:
            insets.top += topBannerContainerView.bounds.height
            insets.bottom += bottomBannerContainerView.bounds.height + 10.0
        case .compact:
            let inset = navigationViewData.navigationView.topBannerContainerView.frame.width + 10.0
            if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
                insets.right += inset
            } else {
                insets.left += inset
            }
        @unknown default:
            break
        }
    
        return insets
    }
    
    // MARK: NavigationComponent Implementation
    
    func navigationService(_ service: NavigationService, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        updateNavigationCameraViewport()
    }
    
    // MARK: NavigationComponentDelegate Implementation
    
    func navigationViewDidLoad(_: UIView) {
        navigationViewData.navigationView.overviewButton.addTarget(self, action: #selector(overview(_:)), for: .touchUpInside)
        navigationViewData.navigationView.resumeButton.addTarget(self, action: #selector(recenter(_:)), for: .touchUpInside)
        
        navigationMapView.userLocationStyle = .courseView()
        navigationViewData.navigationView.resumeButton.isHidden = true
    }
    
    func navigationViewWillAppear(_: Bool) {
        resumeNotifications()
        
        navigationMapView.mapView.ornaments.options.compass.visibility = .hidden
        
        navigationMapView.navigationCamera.follow()
    }
    
    func navigationViewDidDisappear(_: Bool) {
        suspendNotifications()
    }
}
