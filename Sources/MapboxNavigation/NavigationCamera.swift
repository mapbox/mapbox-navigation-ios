import Foundation
import MapboxMaps

/**
 `NavigationCamera` class provides functionality, which allows to manage camera related states
 and transitions in a typical navigation scenarios. It's fed with `CameraOptions` via the `ViewportDataSource`
 protocol and executes transitions using `CameraStateTransition` protocol.
 */
public class NavigationCamera: NSObject, ViewportDataSourceDelegate {
    
    /**
     Initializer of `NavigationCamera` object.
     
     - parameter mapView: Instance of `MapView`, on which camera related transitions will be executed.
     - parameter navigationCameraType: Type of camera, which is used to perform camera transition (either iOS or CarPlay).
     */
    public required init(_ mapView: MapView, navigationCameraType: NavigationCameraType = .mobile) {
        self.mapView = mapView
        viewportDataSource = NavigationViewportDataSource(mapView)
        cameraStateTransition = NavigationCameraStateTransition(mapView)
        type = navigationCameraType
        
        super.init()
        
        viewportDataSource.delegate = self
        
        setupGestureRecognizers()
        
        // Uncomment to be able to see `NavigationCameraDebugView`.
        // setupDebugView(mapView,
        //                navigationCameraType: navigationCameraType,
        //                navigationViewportDataSource: self.viewportDataSource as? NavigationViewportDataSource)
    }
    
    func setupGestureRecognizers() {
        makeGestureRecognizersDisableCameraFollowing()
        makeTapGestureRecognizerStopAnimatedTransitions()
    }
    
    // MARK: Reacting to ViewportDataSourceDelegate Updates
    
    public func viewportDataSource(_ dataSource: ViewportDataSource, didUpdate cameraOptions: [String: CameraOptions]) {
        switch state {
        case .following:
            switch type {
            case .carPlay:
                if let followingCarPlayCamera = cameraOptions[CameraOptions.followingCarPlayCamera] {
                    cameraStateTransition.update(to: followingCarPlayCamera, state: .following)
                }
            case .mobile:
                if let followingMobileCamera = cameraOptions[CameraOptions.followingMobileCamera] {
                    cameraStateTransition.update(to: followingMobileCamera, state: .following)
                }
            }
            break

        case .overview:
            switch type {
            case .carPlay:
                if let overviewCarPlayCamera = cameraOptions[CameraOptions.overviewCarPlayCamera] {
                    cameraStateTransition.update(to: overviewCarPlayCamera, state: .overview)
                }
            case .mobile:
                if let overviewMobileCamera = cameraOptions[CameraOptions.overviewMobileCamera] {
                    cameraStateTransition.update(to: overviewMobileCamera, state: .overview)
                }
            }
            break

        case .idle, .transitionToFollowing, .transitionToOverview:
            break
        }
    }
    
    // MARK: Changing NavigationCamera State
    
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
     Current state of `NavigationCamera`. Defaults to `NavigationCameraState.idle`.
     */
    public private(set) var state: NavigationCameraState = .idle {
        didSet {
            NotificationCenter.default.post(name: .navigationCameraStateDidChange,
                                            object: self,
                                            userInfo: [
                                                NavigationCamera.NotificationUserInfoKey.state: state
                                            ])
        }
    }
    
    /**
     Protocol, which is used to execute camera transitions. By default `NavigationMapView` uses
     `NavigationCameraStateTransition`.
     */
    public var cameraStateTransition: CameraStateTransition
    
    /**
     `MapView` instance, which will be used for performing camera related transitions.
     */
    weak var mapView: MapView?
    
    /**
     Type of `NavigationCamera`. Used to decide on which platform (iOS or CarPlay) transitions and updates should be executed.
     */
    var type: NavigationCameraType = .mobile
    
    /**
     Instance of `NavigationCameraDebugView`, which is drawn on `MapView` surface for debugging purposes.
     */
    var debugView: NavigationCameraDebugView? = nil
    
    /**
     Call to this method executes a transition to `NavigationCameraState.following` state.
     When started, state will first change to `NavigationCameraState.transitionToFollowing` and then
     to the final `NavigationCameraState.following` when ended.
     
     - parameter completion: Completion handler, which is called whenever transition ends or doesn't
     occur at all (e.g. in case if already in `NavigationCameraState.transitionToFollowing` or
     `NavigationCameraState.following` state).
     */
    public func follow(_ completion: (() -> Void)? = nil) {
        switch state {
        case .transitionToFollowing, .following:
            completion?()
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
                completion?()
            }
            
            break
        }
    }
    
    /**
     Call to this method executes a transition to `NavigationCameraState.overview` state.
     When started, state will first change to `NavigationCameraState.transitionToOverview` and then
     to the final `NavigationCameraState.overview` when ended.
     
     - parameter completion: Completion handler, which is called whenever transition ends or doesn't
     occur at all (e.g. in case if already in `NavigationCameraState.transitionToOverview` or
     `NavigationCameraState.overview` state).
     */
    public func moveToOverview(_ completion: (() -> Void)? = nil) {
        switch state {
        case .transitionToOverview, .overview:
            completion?()
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
                completion?()
            }
            
            break
        }
    }
    
    /**
     Call to this method immediately moves `NavigationCamera` to `NavigationCameraState.idle` state
     and stops all pending transitions.
     */
    @objc public func stop() {
        stopTransition(ignoring: .idle)
    }
    
    @objc func stopNonFollowingTransition() {
        stopTransition(ignoring: .following)
    }
    
    private func stopTransition(ignoring state: NavigationCameraState) {
        if self.state == state { return }

        cameraStateTransition.cancelPendingTransition()

        self.state = .idle
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
            gestureRecognizer.addTarget(self, action: #selector(stop))
        }
    }
    
    func makeTapGestureRecognizerStopAnimatedTransitions() {
        for gestureRecognizer in mapView?.gestureRecognizers ?? []
        where gestureRecognizer is UITapGestureRecognizer
        {
            gestureRecognizer.addTarget(self, action: #selector(stopNonFollowingTransition))
        }
    }
    
    func setupDebugView(_ mapView: MapView,
                        navigationCameraType: NavigationCameraType,
                        navigationViewportDataSource: NavigationViewportDataSource?) {
        debugView = NavigationCameraDebugView(mapView,
                                              frame: mapView.frame,
                                              navigationCameraType: navigationCameraType,
                                              navigationViewportDataSource: navigationViewportDataSource)
        mapView.addSubview(debugView!)
    }
}
