import Foundation
import MapboxMaps

/**
 `NavigationCamera` class provides functionality, which allows to manage camera related states
 and transitions in a typical navigation scenarios. It's fed with `CameraOptions` via the `ViewportDataSource`
 protocol and executes transitions using `CameraStateTransition` protocol.
 */
public class NavigationCamera: NSObject, ViewportDataSourceDelegate {
    
    /**
     Current state of `NavigationCamera`. Defaults to `NavigationCameraState.idle`.
     */
    public private(set) var state: NavigationCameraState = .idle {
        didSet {
            NotificationCenter.default.post(name: .navigationCameraStateDidChange,
                                            object: self,
                                            userInfo: [
                                                NavigationCamera.NotificationUserInfoKey.stateKey: state
                                            ])
        }
    }
    
    /**
     Protocol, which is used to provide location related data to continuously perform camera related updates.
     By default `NavigationMapView` uses `NavigationViewportDataSource`.
     */
    public var viewportDataSource: ViewportDataSource {
        didSet {
            viewportDataSource.delegate = self
            
            debugView?.navigationViewportDataSource = viewportDataSource as? NavigationViewportDataSource
        }
    }
    
    /**
     Protocol, which is used to execute camera transitions. By default `NavigationMapView` uses
     `NavigationCameraStateTransition`.
     */
    public var cameraStateTransition: CameraStateTransition
    
    weak var mapView: MapView?
    
    var type: NavigationCameraType = .mobile
    
    var debugView: NavigationCameraDebugView? = nil
    
    /**
     Initializer of `NavigationCamera` object.
     
     - parameter mapView: Instance of `MapView`, on which camera related transitions will be executed.
     - parameter navigationCameraType: Type of camera, which is used to perform camera transition (either iOS or CarPlay).
     */
    public required init(_ mapView: MapView, navigationCameraType: NavigationCameraType = .mobile) {
        self.mapView = mapView
        self.viewportDataSource = NavigationViewportDataSource(mapView)
        self.cameraStateTransition = NavigationCameraStateTransition(mapView)
        self.type = navigationCameraType
        
        super.init()
        
        self.viewportDataSource.delegate = self
        
        setupGestureRegonizers()
        
        setupNavigationCameraDebugView(mapView,
                                       navigationCameraType: navigationCameraType,
                                       navigationViewportDataSource: self.viewportDataSource as? NavigationViewportDataSource)
    }
    
    // MARK: - Setting-up methods
    
    func setupGestureRegonizers() {
        makeGestureRecognizersDisableCameraFollowing()
    }
    
    // MARK: - ViewportDataSourceDelegate methods
    
    public func viewportDataSource(_ dataSource: ViewportDataSource, didUpdate cameraOptions: [String: CameraOptions]) {
        switch state {
        case .following:
            switch type {
            case .carPlay:
                if let followingCarPlayCamera = cameraOptions[CameraOptions.followingCarPlayCameraKey] {
                    cameraStateTransition.updateForFollowing(followingCarPlayCamera)
                }
            case .mobile:
                if let followingMobileCamera = cameraOptions[CameraOptions.followingMobileCameraKey] {
                    cameraStateTransition.updateForFollowing(followingMobileCamera)
                }
            }
            break

        case .overview:
            switch type {
            case .carPlay:
                if let overviewCarPlayCamera = cameraOptions[CameraOptions.overviewCarPlayCameraKey] {
                    cameraStateTransition.updateForOverview(overviewCarPlayCamera)
                }
            case .mobile:
                if let overviewMobileCamera = cameraOptions[CameraOptions.overviewMobileCameraKey] {
                    cameraStateTransition.updateForOverview(overviewMobileCamera)
                }
            }
            break

        case .idle, .transitionToFollowing, .transitionToOverview:
            break
        }
    }
    
    // MARK: - NavigationCamera state related methods
    
    /**
     Call to this method executes a transition to `NavigationCameraState.following` state.
     When started, state will first change to `NavigationCameraState.transitionToFollowing` and then
     to the final `NavigationCameraState.following` when ended.
     */
    public func requestNavigationCameraToFollowing() {
        switch state {
        case .transitionToFollowing, .following:
            return
            
        case .idle, .transitionToOverview, .overview:
            state = .transitionToFollowing
            
            var cameraOptions: CameraOptions
            switch type {
            case .mobile:
                cameraOptions = viewportDataSource.followingMobileCamera
            case .carPlay:
                cameraOptions = viewportDataSource.followingCarPlayCamera
            }
            
            cameraStateTransition.transitionToFollowing(cameraOptions) { 
                self.state = .following
            }
            
            break
        }
    }
    
    /**
     Call to this method executes a transition to `NavigationCameraState.overview` state.
     When started, state will first change to `NavigationCameraState.transitionToOverview` and then
     to the final `NavigationCameraState.overview` when ended.
     */
    public func requestNavigationCameraToOverview() {
        switch state {
        case .transitionToOverview, .overview:
            return
            
        case .idle, .transitionToFollowing, .following:
            state = .transitionToOverview
            
            var cameraOptions: CameraOptions
            switch type {
            case .mobile:
                cameraOptions = viewportDataSource.overviewMobileCamera
            case .carPlay:
                cameraOptions = viewportDataSource.overviewCarPlayCamera
            }
            
            cameraStateTransition.transitionToOverview(cameraOptions) { 
                self.state = .overview
            }
            
            break
        }
    }
    
    /**
     Call to this method immediately moves `NavigationCamera` to `NavigationCameraState.idle` state
     and stops all pending transitions.
     */
    @objc public func requestNavigationCameraToIdle() {
        if state == .idle { return }
        
        cameraStateTransition.cancelPendingTransition()
        
        state = .idle
    }
    
    /**
     Modifies `MapView` gesture recognizers to disable follow mode and move `NavigationCamera` to
     `NavigationCameraState.idle` state.
     */
    func makeGestureRecognizersDisableCameraFollowing() {
        for gestureRecognizer in mapView?.gestureRecognizers ?? []
        where gestureRecognizer is UIPanGestureRecognizer
            || gestureRecognizer is UIRotationGestureRecognizer
            || gestureRecognizer is UIPinchGestureRecognizer {
            gestureRecognizer.addTarget(self, action: #selector(requestNavigationCameraToIdle))
        }
    }
    
    func setupNavigationCameraDebugView(_ mapView: MapView,
                                        navigationCameraType: NavigationCameraType,
                                        navigationViewportDataSource: NavigationViewportDataSource?) {
        debugView = NavigationCameraDebugView(mapView,
                                              frame: mapView.frame,
                                              navigationCameraType: navigationCameraType,
                                              navigationViewportDataSource: navigationViewportDataSource)
        mapView.addSubview(debugView!)
    }
}
