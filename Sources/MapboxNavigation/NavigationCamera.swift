import Foundation
import MapboxMaps

public class NavigationCamera: NSObject, ViewportDataSourceDelegate {
    
    public private(set) var state: NavigationCameraState = .idle {
        didSet {
            NotificationCenter.default.post(name: .navigationCameraStateDidChange,
                                            object: self,
                                            userInfo: [
                                                NavigationCamera.NotificationUserInfoKey.stateKey: state
                                            ])
        }
    }
    
    public var viewportDataSource: ViewportDataSource {
        didSet {
            viewportDataSource.delegate = self
        }
    }
    
    public var cameraStateTransition: CameraStateTransition
    
    weak var mapView: MapView?
    
    var navigationCameraType: NavigationCameraType = .mobile
    
    public required init(_ mapView: MapView, navigationCameraType: NavigationCameraType = .mobile) {
        self.mapView = mapView
        self.viewportDataSource = NavigationViewportDataSource(mapView)
        self.cameraStateTransition = NavigationCameraStateTransition(mapView)
        self.navigationCameraType = navigationCameraType
        
        super.init()
        
        self.viewportDataSource.delegate = self
        
        setupGestureRegonizers()
    }
    
    // MARK: - Setting-up methods
    
    func setupGestureRegonizers() {
        makeGestureRecognizersRespectCourseTracking()
    }
    
    // MARK: - ViewportDataSourceDelegate methods
    
    public func viewportDataSource(_ dataSource: ViewportDataSource, didUpdate cameraOptions: [String: CameraOptions]) {
        switch state {
        case .following:
            switch navigationCameraType {
            case .headUnit:
                if let followingHeadUnitCamera = cameraOptions[CameraOptions.followingHeadUnitCameraKey] {
                    cameraStateTransition.updateForFollowing(followingHeadUnitCamera, completion: nil)
                }
            case .mobile:
                if let followingMobileCamera = cameraOptions[CameraOptions.followingMobileCameraKey] {
                    cameraStateTransition.updateForFollowing(followingMobileCamera, completion: nil)
                }
            }
            break

        case .overview:
            switch navigationCameraType {
            case .headUnit:
                if let overviewHeadUnitCamera = cameraOptions[CameraOptions.overviewHeadUnitCameraKey] {
                    cameraStateTransition.updateForOverview(overviewHeadUnitCamera, completion: nil)
                }
            case .mobile:
                if let overviewMobileCamera = cameraOptions[CameraOptions.overviewMobileCameraKey] {
                    cameraStateTransition.updateForOverview(overviewMobileCamera, completion: nil)
                }
            }
            break

        case .idle, .transitionToFollowing, .transitionToOverview:
            break
        }
    }
    
    // MARK: - NavigationCamera state related methods
    
    public func requestNavigationCameraToFollowing() {
        switch state {
        case .transitionToFollowing, .following:
            return
            
        case .idle, .transitionToOverview, .overview:
            state = .transitionToFollowing
            
            var cameraOptions: CameraOptions
            switch navigationCameraType {
            case .mobile:
                cameraOptions = viewportDataSource.followingMobileCamera
            case .headUnit:
                cameraOptions = viewportDataSource.followingHeadUnitCamera
            }
            
            cameraStateTransition.transitionToFollowing(cameraOptions) { 
                self.state = .following
            }
            
            break
        }
    }
    
    public func requestNavigationCameraToOverview() {
        switch state {
        case .transitionToOverview, .overview:
            return
            
        case .idle, .transitionToFollowing, .following:
            state = .transitionToOverview
            
            var cameraOptions: CameraOptions
            switch navigationCameraType {
            case .mobile:
                cameraOptions = viewportDataSource.overviewMobileCamera
            case .headUnit:
                cameraOptions = viewportDataSource.overviewHeadUnitCamera
            }
            
            cameraStateTransition.transitionToOverview(cameraOptions) { 
                self.state = .overview
            }
            
            break
        }
    }
    
    @objc public func requestNavigationCameraToIdle() {
        if state == .idle { return }
        
        cameraStateTransition.cancelPendingTransition()
        
        if let navigationCameraStateTransition = self.cameraStateTransition as? NavigationCameraStateTransition {
            navigationCameraStateTransition.cameraView.isActive = false
        }
        
        state = .idle
    }
    
    /**
     Modifies `MapView` gesture recognizers to disable follow mode and move `NavigationCamera` to
     `NavigationCameraState.idle` state.
     */
    func makeGestureRecognizersRespectCourseTracking() {
        for gestureRecognizer in mapView?.gestureRecognizers ?? []
        where gestureRecognizer is UIPanGestureRecognizer || gestureRecognizer is UIRotationGestureRecognizer {
            gestureRecognizer.addTarget(self, action: #selector(requestNavigationCameraToIdle))
        }
    }
}
