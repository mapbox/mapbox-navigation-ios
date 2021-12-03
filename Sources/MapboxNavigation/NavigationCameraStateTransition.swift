import MapboxMaps
import Turf

/**
 Class, which conforms to `CameraStateTransition` protocol and provides default implementation of
 camera related transitions by using `CameraAnimator` functionality provided by Mapbox Maps SDK.
 */
public class NavigationCameraStateTransition: CameraStateTransition {

    // MARK: Transitioning State
    
    /**
     A map view to which corresponding camera is related.
     */
    public weak var mapView: MapView?
    
    var animatorCenter: BasicCameraAnimator?
    var animatorZoom: BasicCameraAnimator?
    var animatorBearing: BasicCameraAnimator?
    var animatorPitch: BasicCameraAnimator?
    var animatorAnchor: BasicCameraAnimator?
    var animatorPadding: BasicCameraAnimator?
    
    var previousAnchor: CGPoint = .zero
    
    typealias TransitionParameters = (
        cameraOptions: CameraOptions,
        centerAnimationDuration: TimeInterval,
        centerAnimationDelay: TimeInterval,
        zoomAnimationDuration: TimeInterval,
        zoomAnimationDelay: TimeInterval,
        bearingAnimationDuration: TimeInterval,
        bearingAnimationDelay: TimeInterval,
        pitchAndAnchorAnimationDuration: TimeInterval,
        pitchAndAnchorAnimationDelay: TimeInterval
    )
    
    required public init(_ mapView: MapView) {
        self.mapView = mapView
    }
    
    public func transitionToFollowing(_ cameraOptions: CameraOptions, completion: @escaping (() -> Void)) {
        guard let mapView = mapView,
              let zoom = cameraOptions.zoom else {
            completion()
            return
        }
  
        if mapView.cameraState.zoom < zoom {
            transitionFromLowZoomToHighZoom(cameraOptions) {
                completion()
            }
        } else {
            transitionFromHighZoomToLowZoom(cameraOptions) {
                completion()
            }
        }
    }
    
    public func transitionToOverview(_ cameraOptions: CameraOptions, completion: @escaping (() -> Void)) {
        guard let mapView = mapView,
              let zoom = cameraOptions.zoom else {
            completion()
            return
        }
        
        var cameraOptions = cameraOptions
        cameraOptions.pitch = 0.0
        
        if mapView.cameraState.zoom < zoom {
            transitionFromLowZoomToHighZoom(cameraOptions) {
                completion()
            }
        } else {
            transitionFromHighZoomToLowZoom(cameraOptions) {
                completion()
            }
        }
    }
    
    public func cancelPendingTransition() {
        stopAnimators()
    }
    
    public func update(to cameraOptions: CameraOptions, state: NavigationCameraState) {
        guard let mapView = mapView,
              let center = cameraOptions.center,
              CLLocationCoordinate2DIsValid(center),
              let zoom = cameraOptions.zoom,
              let bearing = (state == .overview) ? 0.0 : cameraOptions.bearing,
              let pitch = cameraOptions.pitch,
              let anchor = cameraOptions.anchor,
              let padding = cameraOptions.padding else { return }
        
        let duration = 1.0
        let minimumCenterCoordinatePixelThreshold: Double = 2.0
        let minimumPitchThreshold: CGFloat = 1.0
        let minimumBearingThreshold: CLLocationDirection = 1.0
        let timingParameters = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.0, y: 0.0),
                                                       controlPoint2: CGPoint(x: 1.0, y: 1.0))
        
        // Check whether the location change is larger than a certain threshold when current camera state is following.
        var updateCameraCenter: Bool = true
        if state == .following {
            let metersPerPixel = getMetersPerPixelAtLatitude(center.latitude, Double(zoom))
            let centerUpdateThreshold = minimumCenterCoordinatePixelThreshold * metersPerPixel
            updateCameraCenter = (mapView.cameraState.center.distance(to: center) > centerUpdateThreshold)
        }
        
        if updateCameraCenter {
            if let animatorCenter = animatorCenter, animatorCenter.isRunning {
                animatorCenter.stopAnimation()
            }
            
            animatorCenter = mapView.camera.makeAnimator(duration: duration,
                                                         timingParameters: timingParameters) { (transition) in
                transition.center.toValue = center
            }
            
            animatorCenter?.startAnimation()
        }
        
        if let animatorZoom = animatorZoom, animatorZoom.isRunning {
            animatorZoom.stopAnimation()
        }
        
        animatorZoom = mapView.camera.makeAnimator(duration: duration,
                                                   timingParameters: timingParameters) { (transition) in
            transition.zoom.toValue = zoom
        }
        
        animatorZoom?.startAnimation()
        
        // Check whether the bearing change is larger than a certain threshold when current camera state is following.
        let updateCameraBearing = (state == .following) ? (abs(mapView.cameraState.bearing - bearing) >= minimumBearingThreshold) : true
        
        if updateCameraBearing {
            if let animatorBearing = animatorBearing, animatorBearing.isRunning {
                animatorBearing.stopAnimation()
            }
            
            animatorBearing = mapView.camera.makeAnimator(duration: duration,
                                                          timingParameters: timingParameters) { (transition) in
                transition.bearing.toValue = bearing
            }
            
            animatorBearing?.startAnimation()
        }
        
        // Check whether the pitch change is larger than a certain threshold when current camera state is following.
        let updateCameraPitch = (state == .following) ? (abs(mapView.cameraState.pitch - pitch) >= minimumPitchThreshold) : true
        
        if updateCameraPitch {
            if let animatorPitch = animatorPitch, animatorPitch.isRunning {
                animatorPitch.stopAnimation()
            }
            
            animatorPitch = mapView.camera.makeAnimator(duration: duration,
                                                        timingParameters: timingParameters) { (transition) in
                transition.pitch.toValue = pitch
            }
            
            animatorPitch?.startAnimation()
        }
        
        // In case if anchor did not change - do not perform animation.
        let updateCameraAnchor = previousAnchor != anchor
        previousAnchor = anchor
        
        if updateCameraAnchor {
            if let animatorAnchor = animatorAnchor, animatorAnchor.isRunning {
                animatorAnchor.stopAnimation()
            }
            
            animatorAnchor = mapView.camera.makeAnimator(duration: duration,
                                                         timingParameters: timingParameters) { (transition) in
                transition.anchor.toValue = anchor
            }
            
            animatorAnchor?.startAnimation()
        }
        
        if let animatorPadding = animatorPadding, animatorPadding.isRunning {
            animatorPadding.stopAnimation()
        }
        
        animatorPadding = mapView.camera.makeAnimator(duration: duration,
                                                      timingParameters: timingParameters) { (transition) in
            transition.padding.toValue = padding
        }
        
        animatorPadding?.startAnimation()
    }
    
    func stopAnimators() {
        let animators = [
            animatorCenter,
            animatorZoom,
            animatorBearing,
            animatorPitch,
            animatorAnchor,
            animatorPadding
        ]
        
        animators.compactMap({ $0 }).forEach {
            if $0.isRunning {
                $0.stopAnimation()
            }
        }
    }
    
    func transitionFromLowZoomToHighZoom(_ cameraOptions: CameraOptions, completion: @escaping (() -> Void)) {
        guard let mapView = mapView,
              let zoom = cameraOptions.zoom,
              let location = cameraOptions.center,
              let bearing = cameraOptions.bearing else {
            completion()
            return
        }
        
        let centerTranslationDistance: CLLocationDistance = mapView.cameraState.center.distance(to: location)
        let metersPerSecondMaxCenterAnimation: Double = 1500.0
        let centerAnimationDuration: TimeInterval = max(min(centerTranslationDistance / metersPerSecondMaxCenterAnimation, 1.6), 0.6)
        let centerAnimationDelay: TimeInterval = 0.0
        
        let zoomLevelDistance: CLLocationDistance = CLLocationDistance(abs(mapView.cameraState.zoom - zoom))
        let levelsPerSecondMaxZoomAnimation: Double = 3.0
        let zoomAnimationDuration: TimeInterval = max(min(zoomLevelDistance / levelsPerSecondMaxZoomAnimation, 1.6), 0.6)
        let zoomAnimationDelay: TimeInterval = centerAnimationDuration * 0.5
        let endZoomAnimation: TimeInterval = zoomAnimationDuration + zoomAnimationDelay
        
        let currentBearing: CLLocationDirection = mapView.cameraState.bearing
        let newBearing: CLLocationDirection = mapView.cameraState.bearing + bearing.shortestRotation(angle: mapView.cameraState.bearing)
        let bearingDegreesChange: CLLocationDirection = fabs(newBearing - currentBearing)
        let degreesPerSecondMaxBearingAnimation: Double = 60.0
        let bearingAnimationDuration: TimeInterval = max(min(bearingDegreesChange / degreesPerSecondMaxBearingAnimation, 1.2), 0.6)
        let bearingAnimationDelay: TimeInterval = max(endZoomAnimation - bearingAnimationDuration - 0.2, 0.0)
        
        let pitchAndAnchorAnimationDuration: TimeInterval = 0.8
        let pitchAndAnchorAnimationDelay: TimeInterval = max(endZoomAnimation - pitchAndAnchorAnimationDuration, 0.0)
        
        let transitionParameters = TransitionParameters(
            cameraOptions,
            centerAnimationDuration,
            centerAnimationDelay,
            zoomAnimationDuration,
            zoomAnimationDelay,
            bearingAnimationDuration,
            bearingAnimationDelay,
            pitchAndAnchorAnimationDuration,
            pitchAndAnchorAnimationDelay
        )
        
        transition(transitionParameters) {
            completion()
        }
    }
    
    func transitionFromHighZoomToLowZoom(_ cameraOptions: CameraOptions, completion: @escaping (() -> Void)) {
        guard let mapView = mapView,
              let zoom = cameraOptions.zoom,
              let location = cameraOptions.center,
              let bearing = cameraOptions.bearing else {
            completion()
            return
        }
        
        let zoomLevelDistance: CLLocationDistance = CLLocationDistance(abs(mapView.cameraState.zoom - zoom))
        let levelsPerSecondMaxZoomAnimation: Double = 0.6
        let zoomAnimationDuration: TimeInterval = max(min(zoomLevelDistance / levelsPerSecondMaxZoomAnimation, 0.8), 0.2)
        let zoomAnimationDelay: TimeInterval = 0.0
        let endZoomAnimation: TimeInterval = zoomAnimationDuration + zoomAnimationDelay
        
        let centerTranslationDistance: CLLocationDistance = mapView.cameraState.center.distance(to: location)
        let metersPerSecondMaxCenterAnimation: Double = 1000.0
        let centerAnimationDuration: TimeInterval = max(min(centerTranslationDistance / metersPerSecondMaxCenterAnimation, 1.4), 0.6)
        let centerAnimationDelay: TimeInterval = max(endZoomAnimation - centerAnimationDuration, 0.0)
        
        let bearingDegreesChange: CLLocationDirection = bearing.shortestRotation(angle: mapView.cameraState.bearing)
        let degreesPerSecondMaxBearingAnimation: Double = 60.0
        let bearingAnimationDuration: TimeInterval = max(min(bearingDegreesChange / degreesPerSecondMaxBearingAnimation, 1.2), 0.8)
        let bearingAnimationDelay: TimeInterval = max(endZoomAnimation - bearingAnimationDuration - 0.4, 0.0)
        
        let pitchAndAnchorAnimationDuration: TimeInterval = 0.6
        let pitchAndAnchorAnimationDelay: TimeInterval = 0.0
        
        let transitionParameters = TransitionParameters(
            cameraOptions,
            centerAnimationDuration,
            centerAnimationDelay,
            zoomAnimationDuration,
            zoomAnimationDelay,
            bearingAnimationDuration,
            bearingAnimationDelay,
            pitchAndAnchorAnimationDuration,
            pitchAndAnchorAnimationDelay
        )
        
        transition(transitionParameters) {
            completion()
        }
    }
    
    func transition(_ transitionParameters: TransitionParameters, completion: @escaping (() -> Void)) {
        guard let mapView = mapView,
              let center = transitionParameters.cameraOptions.center,
              CLLocationCoordinate2DIsValid(center),
              let zoom = transitionParameters.cameraOptions.zoom,
              let bearing = transitionParameters.cameraOptions.bearing,
              let pitch = transitionParameters.cameraOptions.pitch,
              let anchor = transitionParameters.cameraOptions.anchor,
              let padding = transitionParameters.cameraOptions.padding else {
            completion()
            return
        }
        
        stopAnimators()
        
        let animationsGroup = DispatchGroup()
        
        let cancellableAnimatingPositions: Set<UIViewAnimatingPosition> = [
            .end
        ]
        
        let centerTimingParameters = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.4, y: 0.0),
                                                             controlPoint2: CGPoint(x: 0.6, y: 1.0))
        animatorCenter = mapView.camera.makeAnimator(duration: transitionParameters.centerAnimationDuration,
                                                     timingParameters: centerTimingParameters,
                                                     animations: { (transition) in
                                                        transition.center.toValue = center
                                                     })
        animatorCenter?.addCompletion { animatingPosition in
            if cancellableAnimatingPositions.contains(animatingPosition) {
                animationsGroup.leave()
            }
        }
        
        let zoomTimingParameters = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.2, y: 0.0),
                                                           controlPoint2: CGPoint(x: 0.6, y: 1.0))
        animatorZoom = mapView.camera.makeAnimator(duration: transitionParameters.zoomAnimationDuration,
                                                   timingParameters: zoomTimingParameters,
                                                   animations: { (transition) in
                                                    transition.zoom.toValue = zoom
                                                   })
        animatorZoom?.addCompletion { animatingPosition in
            if cancellableAnimatingPositions.contains(animatingPosition) {
                animationsGroup.leave()
            }
        }
        
        let bearingTimingParameters = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.4, y: 0.0),
                                                              controlPoint2: CGPoint(x: 0.6, y: 1.0))
        animatorBearing = mapView.camera.makeAnimator(duration: transitionParameters.bearingAnimationDuration,
                                                      timingParameters: bearingTimingParameters,
                                                      animations: { (transition) in
                                                        transition.bearing.toValue = bearing
                                                      })
        animatorBearing?.addCompletion { animatingPosition in
            if cancellableAnimatingPositions.contains(animatingPosition) {
                animationsGroup.leave()
            }
        }
        
        let pitchTimingParameters = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.6, y: 0.0),
                                                            controlPoint2: CGPoint(x: 0.4, y: 1.0))
        animatorPitch = mapView.camera.makeAnimator(duration: transitionParameters.pitchAndAnchorAnimationDuration,
                                                    timingParameters: pitchTimingParameters,
                                                    animations: { (transition) in
                                                        transition.pitch.toValue = CGFloat(pitch)
                                                        transition.anchor.toValue = anchor
                                                        transition.padding.toValue = padding
                                                    })
        animatorPitch?.addCompletion { animatingPosition in
            if cancellableAnimatingPositions.contains(animatingPosition) {
                animationsGroup.leave()
            }
        }
        
        guard let animatorCenter = animatorCenter,
              let animatorZoom = animatorZoom,
              let animatorBearing = animatorBearing,
              let animatorPitch = animatorPitch else {
            completion()
            return
        }

        let animations: [(BasicCameraAnimator, TimeInterval)] = [
            (animatorCenter, transitionParameters.centerAnimationDelay),
            (animatorZoom, transitionParameters.zoomAnimationDelay),
            (animatorBearing, transitionParameters.bearingAnimationDelay),
            (animatorPitch, transitionParameters.pitchAndAnchorAnimationDelay),
        ]

        animations.forEach { (animator, delay) in
            animationsGroup.enter()
            animator.startAnimation(afterDelay: fmax(delay, 0.0))
        }

        animationsGroup.notify(queue: .main) {
            completion()
        }
    }
}
