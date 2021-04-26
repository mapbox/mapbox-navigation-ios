import MapboxMaps
import Turf

/**
 Class, which conforms to `CameraStateTransition` protocol and provides default implementation of
 camera related transitions by using `CameraAnimator` functionality provided by Mapbox Maps SDK.
 */
public class NavigationCameraStateTransition: CameraStateTransition {

    public weak var mapView: MapView?
    
    var animatorCenter: CameraAnimator?
    var animatorZoom: CameraAnimator?
    var animatorBearing: CameraAnimator?
    var animatorPitch: CameraAnimator?
    
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
              let zoom = cameraOptions.zoom,
              let location = cameraOptions.center,
              let bearing = cameraOptions.bearing,
              let pitch = cameraOptions.pitch,
              let padding = cameraOptions.padding,
              let anchor = cameraOptions.anchor else {
            completion()
            return
        }
        
        if transitionDestinationIsOffScreen(location, edgeInsets: padding) {
            let screenCenterPoint = self.screenCenterPoint(0.0, bounds: mapView.bounds, edgeInsets: padding)
            let lineString = LineString([mapView.centerCoordinate, location])
            var camera = mapView.camera.camera(fitting: .lineString(lineString))
            camera.bearing = CLLocationDirection(mapView.bearing)
            camera.pitch = 0.0
            if let midPointZoom = camera.zoom {
                let cameraOptions = CameraOptions(center: location,
                                                  anchor: screenCenterPoint,
                                                  zoom: CGFloat(midPointZoom),
                                                  bearing: bearing,
                                                  pitch: 0.0)
                
                transitionFromHighZoomToMidpoint(cameraOptions) {
                    let cameraOptions = CameraOptions(center: location,
                                                      anchor: anchor,
                                                      zoom: CGFloat(zoom),
                                                      bearing: bearing,
                                                      pitch: CGFloat(pitch))
                    
                    self.transitionFromLowZoomToHighZoom(cameraOptions) {
                        completion()
                    }
                }
            }
        } else {
            if mapView.zoom < zoom {
                transitionFromLowZoomToHighZoom(cameraOptions) {
                    completion()
                }
            } else {
                transitionFromHighZoomToLowZoom(cameraOptions) {
                    completion()
                }
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
        
        if mapView.zoom < zoom {
            transitionFromLowZoomToHighZoom(cameraOptions) {
                completion()
            }
        } else {
            transitionFromHighZoomToLowZoom(cameraOptions) {
                completion()
            }
        }
    }
    
    public func updateForFollowing(_ cameraOptions: CameraOptions) {
        update(cameraOptions)
    }
    
    public func updateForOverview(_ cameraOptions: CameraOptions) {
        var cameraOptions = cameraOptions
        cameraOptions.bearing = 0.0
        update(cameraOptions)
    }
    
    public func cancelPendingTransition() {
        stopAnimators()
    }
    
    func update(_ cameraOptions: CameraOptions) {
        guard let mapView = mapView,
              let center = cameraOptions.center,
              let zoom = cameraOptions.zoom,
              let bearing = cameraOptions.bearing,
              let pitch = cameraOptions.pitch,
              let anchor = cameraOptions.anchor,
              let padding = cameraOptions.padding else { return }
        
        let duration = 1.0
        
        if let animatorCenter = animatorCenter, animatorCenter.isRunning {
            animatorCenter.stopAnimation()
        }
        
        let centerTimingParameters = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.0, y: 0.0), controlPoint2: CGPoint(x: 1.0, y: 1.0))
        animatorCenter = mapView.camera.makeAnimator(duration: duration, timingParameters: centerTimingParameters) { (transition) in
            transition.center.toValue = center
        }
        
        animatorCenter?.startAnimation()
        
        if let animatorZoom = animatorZoom, animatorZoom.isRunning {
            animatorZoom.stopAnimation()
        }
        
        let zoomTimingParameters = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.0, y: 0.0), controlPoint2: CGPoint(x: 1.0, y: 1.0))
        animatorZoom = mapView.camera.makeAnimator(duration: duration, timingParameters: zoomTimingParameters) { (transition) in
            transition.zoom.toValue = zoom
        }
        
        animatorZoom?.startAnimation()
        
        if let animatorBearing = animatorBearing, animatorBearing.isRunning {
            animatorBearing.stopAnimation()
        }
        
        let bearingTimingParameters = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.0, y: 0.0), controlPoint2: CGPoint(x: 1.0, y: 1.0))
        animatorBearing = mapView.camera.makeAnimator(duration: duration, timingParameters: bearingTimingParameters) { (transition) in
            transition.bearing.toValue = bearing
        }
        
        animatorBearing?.startAnimation()
        
        if let animatorPitch = animatorPitch, animatorPitch.isRunning {
            animatorPitch.stopAnimation()
        }
        
        let pitchTimingParameters = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.0, y: 0.0), controlPoint2: CGPoint(x: 1.0, y: 1.0))
        animatorPitch = mapView.camera.makeAnimator(duration: duration, timingParameters: pitchTimingParameters) { (transition) in
            transition.pitch.toValue = pitch
            transition.anchor.toValue = anchor
            transition.padding.toValue = padding
        }
        
        animatorPitch?.startAnimation()
    }
    
    func stopAnimators() {
        let animators = [
            animatorCenter,
            animatorZoom,
            animatorBearing,
            animatorPitch
        ]
        
        animators.forEach {
            $0?.stopAnimation()
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
        
        let centerTranslationDistance = mapView.centerCoordinate.distance(to: location)
        let metersPerSecondMaxCenterAnimation: Double = 1500.0
        let centerAnimationDuration: TimeInterval = max(min(centerTranslationDistance / metersPerSecondMaxCenterAnimation, 1.6), 0.6)
        let centerAnimationDelay: TimeInterval = 0.0
        
        let zoomLevelDistance = CLLocationDistance(abs(mapView.zoom - zoom))
        let levelsPerSecondMaxZoomAnimation: Double = 3.0
        let zoomAnimationDuration: TimeInterval = max(min(zoomLevelDistance / levelsPerSecondMaxZoomAnimation, 1.6), 0.6)
        let zoomAnimationDelay: TimeInterval = centerAnimationDuration * 0.5
        let endZoomAnimation: TimeInterval = zoomAnimationDuration + zoomAnimationDelay
        
        let currentBearing = mapView.bearing
        let newBearing: CLLocationDirection = Double(mapView.bearing) + bearing.shortestRotation(angle: CLLocationDirection(mapView.bearing))
        let bearingDegreesChange: CLLocationDirection = fabs(newBearing - Double(currentBearing))
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
        
        let zoomLevelDistance = CLLocationDistance(abs(mapView.zoom - zoom))
        let levelsPerSecondMaxZoomAnimation: Double = 0.6
        let zoomAnimationDuration: TimeInterval = max(min(zoomLevelDistance / levelsPerSecondMaxZoomAnimation, 0.8), 0.2)
        let zoomAnimationDelay: TimeInterval = 0.0
        let endZoomAnimation: TimeInterval = zoomAnimationDuration + zoomAnimationDelay
        
        let centerTranslationDistance = mapView.centerCoordinate.distance(to: location)
        let metersPerSecondMaxCenterAnimation: Double = 1000.0
        let centerAnimationDuration: TimeInterval = max(min(centerTranslationDistance / metersPerSecondMaxCenterAnimation, 1.4), 0.6)
        let centerAnimationDelay: TimeInterval = max(endZoomAnimation - centerAnimationDuration, 0.0)
        
        let bearingDegreesChange: CLLocationDirection = bearing.shortestRotation(angle: CLLocationDirection(mapView.bearing))
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
    
    func transitionFromHighZoomToMidpoint(_ cameraOptions: CameraOptions, completion: @escaping (() -> Void)) {
        guard let mapView = mapView,
              let zoom = cameraOptions.zoom,
              let location = cameraOptions.center,
              let bearing = cameraOptions.bearing else {
            completion()
            return
        }
        
        let zoomLevelDistance = CLLocationDistance(abs(mapView.zoom - zoom))
        let levelsPerSecondMaxZoomAnimation: Double = 0.6
        let zoomAnimationDuration: TimeInterval = max(min(zoomLevelDistance / levelsPerSecondMaxZoomAnimation, 0.8), 0.2)
        let zoomAnimationDelay: TimeInterval = 0.0
        let endZoomAnimation: TimeInterval = zoomAnimationDuration + zoomAnimationDelay
        
        let centerTranslationDistance = mapView.centerCoordinate.distance(to: location)
        let metersPerSecondMaxCenterAnimation: Double = 1000.0
        let centerAnimationDuration: TimeInterval = max(min(centerTranslationDistance / metersPerSecondMaxCenterAnimation, 1.4), 0.8)
        let centerAnimationDelay: TimeInterval = max(endZoomAnimation - centerAnimationDuration, 0.0)
        
        let bearingDegreesChange: CLLocationDirection = bearing.shortestRotation(angle: CLLocationDirection(mapView.bearing))
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
        
        let centerTimingParameters = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.4, y: 0.0),
                                                             controlPoint2: CGPoint(x: 0.6, y: 1.0))
        animatorCenter = mapView.camera.makeAnimator(duration: transitionParameters.centerAnimationDuration,
                                                     timingParameters: centerTimingParameters,
                                                     animations: { (transition) in
                                                        transition.center.toValue = center
                                                     })
        animatorCenter?.addCompletion { (animatingPosition) in
            if animatingPosition == .end {
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
        animatorZoom?.addCompletion { (animatingPosition) in
            if animatingPosition == .end {
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
        
        animatorBearing?.addCompletion { (animatingPosition) in
            if animatingPosition == .end {
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
        animatorPitch?.addCompletion { (animatingPosition) in
            if animatingPosition == .end {
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

        let animations: [(CameraAnimator, TimeInterval)] = [
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
    
    func transitionDestinationIsOffScreen(_ transitionDestination: CLLocationCoordinate2D, edgeInsets: UIEdgeInsets = .zero) -> Bool {
        guard let mapView = mapView else { return false }
        let inset: CGFloat = 40.0
        let halo = UIEdgeInsets(top: edgeInsets.top - inset, left: -inset, bottom: edgeInsets.bottom - inset, right: -inset)
        
        return !halo.rectValue(mapView.bounds).contains(mapView.point(for: transitionDestination))
    }
    
    func screenCenterPoint(_ pitchEffectCoefficient: Double, bounds: CGRect, edgeInsets: UIEdgeInsets) -> CGPoint {
        let xCenter = max(((bounds.size.width - edgeInsets.left - edgeInsets.right) / 2.0) + edgeInsets.left, 0.0)
        let height = (bounds.size.height - edgeInsets.top - edgeInsets.bottom)
        let yCenter = max((height / 2.0) + edgeInsets.top, 0.0)
        let yOffsetCenter = max((height / 2.0) - 7.0, 0.0) * CGFloat(pitchEffectCoefficient) + yCenter
        
        return CGPoint(x: xCenter, y: yOffsetCenter)
    }
}
