import MapboxMaps
import Turf

public class NavigationCameraStateTransition: CameraStateTransition {

    public weak var mapView: MapView?
    
    let bezierParamsCenter = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.0, y: 0.0), controlPoint2: CGPoint(x: 1.0, y: 1.0))
    let bezierParamsUserLocation = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.0, y: 0.0), controlPoint2: CGPoint(x: 1.0, y: 1.0))
    let bezierParamsZoom = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.0, y: 0.0), controlPoint2: CGPoint(x: 1.0, y: 1.0))
    let bezierParamsBearing = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.0, y: 0.0), controlPoint2: CGPoint(x: 1.0, y: 1.0))
    let bezierParamsPitch = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.0, y: 0.0), controlPoint2: CGPoint(x: 1.0, y: 1.0))
    
    var animatorCenter: UIViewPropertyAnimator!
    var animatorZoom: UIViewPropertyAnimator!
    var animatorBearing: UIViewPropertyAnimator!
    var animatorPitch: UIViewPropertyAnimator!
    
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
        
        resetAnimators()
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
            let lineString = LineString([mapView.cameraView.centerCoordinate, location])
            let camera = mapView.cameraManager.camera(fitting: .lineString(lineString))
            camera.bearing = CLLocationDirection(mapView.cameraView.bearing)
            camera.pitch = 0
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
            if mapView.cameraView.zoom < zoom {
                transitionFromLowZoomToHighZoom(cameraOptions) {
                    self.resetAnimators()
                    completion()
                }
            } else {
                transitionFromHighZoomToLowZoom(cameraOptions) {
                    self.resetAnimators()
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
        
        cameraOptions.pitch = 0
        
        if mapView.cameraView.zoom < zoom {
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
        cameraOptions.bearing = 0.0
        update(cameraOptions)
    }
    
    public func cancelPendingTransition() {
        stopAnimators()
    }
    
    func update(_ cameraOptions: CameraOptions) {
        guard let zoom = cameraOptions.zoom,
              let location = cameraOptions.center,
              let bearing = cameraOptions.bearing,
              let pitch = cameraOptions.pitch,
              let anchor = cameraOptions.anchor else { return }
        
        if animatorCenter.state == .inactive || animatorCenter.state == .stopped {
            animatorCenter.startAnimation(afterDelay: 0)
        }
        
        animatorCenter.addAnimations {
            self.mapView?.cameraView.centerCoordinate = location
        }
        
        if animatorZoom.state == .inactive || animatorZoom.state == .stopped {
            animatorZoom.startAnimation(afterDelay: 0)
        }
        
        animatorZoom.addAnimations {
            self.mapView?.cameraView.zoom = zoom
        }
        
        if animatorBearing.state == .inactive || animatorBearing.state == .stopped {
            animatorBearing.startAnimation(afterDelay: 0)
        }
        
        animatorBearing.addAnimations {
            self.mapView?.cameraView.bearing = CGFloat(bearing)
        }

        if animatorPitch.state == .inactive || animatorPitch.state == .stopped {
            animatorPitch.startAnimation(afterDelay: 0)
        }
        
        animatorPitch.addAnimations {
            self.mapView?.cameraView.pitch = pitch
            self.mapView?.cameraView.anchor = anchor
        }
    }
    
    func resetAnimators() {
        animatorCenter = UIViewPropertyAnimator(duration: 1.0, timingParameters: bezierParamsCenter)
        animatorZoom = UIViewPropertyAnimator(duration: 1.0, timingParameters: bezierParamsZoom)
        animatorBearing = UIViewPropertyAnimator(duration: 1.0, timingParameters: bezierParamsBearing)
        animatorPitch = UIViewPropertyAnimator(duration: 1.0, timingParameters: bezierParamsPitch)
    }
    
    func stopAnimators() {
        let animators = [
            animatorCenter,
            animatorZoom,
            animatorBearing,
            animatorPitch
        ]
        
        animators.forEach {
            $0?.stopAnimation(true)
        }
    }
    
    func transitionFromLowZoomToHighZoom(_ cameraOptions: CameraOptions, completion: @escaping (() -> Void)) {
        guard let mapView = mapView,
              let zoom = cameraOptions.zoom,
              let location = cameraOptions.center,
              let bearing = cameraOptions.bearing else { return }
        
        let centerTranslationDistance = CLLocation.distance(from: mapView.cameraView.centerCoordinate, to: location)
        let metersPerSecondMaxCenterAnimation: Double = 1500.0
        let centerAnimationDuration: TimeInterval = max(min(centerTranslationDistance / metersPerSecondMaxCenterAnimation, 1.6), 0.6)
        let centerAnimationDelay: TimeInterval = 0
        
        let zoomLevelDistance = CLLocationDistance(abs(mapView.cameraView.zoom - zoom))
        let levelsPerSecondMaxZoomAnimation: Double = 3.0
        let zoomAnimationDuration: TimeInterval = max(min(zoomLevelDistance / levelsPerSecondMaxZoomAnimation, 1.6), 0.6)
        let zoomAnimationDelay: TimeInterval = centerAnimationDuration * 0.5
        let endZoomAnimation: TimeInterval = zoomAnimationDuration + zoomAnimationDelay
        
        let currentBearing = mapView.cameraView.bearing
        let newBearing: CLLocationDirection = Double(mapView.cameraView.bearing) + bearing.shortestRotation(angle: CLLocationDirection(mapView.cameraView.bearing))
        let bearingDegreesChange: CLLocationDirection = fabs(newBearing - Double(currentBearing))
        let degreesPerSecondMaxBearingAnimation: Double = 60
        let bearingAnimationDuration: TimeInterval = max(min(bearingDegreesChange / degreesPerSecondMaxBearingAnimation, 1.2), 0.6)
        let bearingAnimationDelay: TimeInterval = max(endZoomAnimation - bearingAnimationDuration - 0.2, 0)
        
        let pitchAndAnchorAnimationDuration: TimeInterval = 0.8
        let pitchAndAnchorAnimationDelay: TimeInterval = max(endZoomAnimation - pitchAndAnchorAnimationDuration, 0)
        
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
              let bearing = cameraOptions.bearing else { return }
        
        let zoomLevelDistance = CLLocationDistance(abs(mapView.cameraView.zoom - zoom))
        let levelsPerSecondMaxZoomAnimation: Double = 0.6
        let zoomAnimationDuration: TimeInterval = max(min(zoomLevelDistance / levelsPerSecondMaxZoomAnimation, 0.8), 0.2)
        let zoomAnimationDelay: TimeInterval = 0
        let endZoomAnimation: TimeInterval = zoomAnimationDuration + zoomAnimationDelay
        
        let centerTranslationDistance = CLLocation.distance(from: mapView.cameraView.centerCoordinate, to: location)
        let metersPerSecondMaxCenterAnimation: Double = 1000.0
        let centerAnimationDuration: TimeInterval = max(min(centerTranslationDistance / metersPerSecondMaxCenterAnimation, 1.4), 0.6)
        let centerAnimationDelay: TimeInterval = max(endZoomAnimation - centerAnimationDuration, 0)
        
        let bearingDegreesChange: CLLocationDirection = bearing.shortestRotation(angle: CLLocationDirection(mapView.cameraView.bearing))
        let degreesPerSecondMaxBearingAnimation: Double = 60
        let bearingAnimationDuration: TimeInterval = max(min(bearingDegreesChange / degreesPerSecondMaxBearingAnimation, 1.2), 0.8)
        let bearingAnimationDelay: TimeInterval = max(endZoomAnimation - bearingAnimationDuration - 0.4, 0)
        
        let pitchAndAnchorAnimationDuration: TimeInterval = 0.6
        let pitchAndAnchorAnimationDelay: TimeInterval = 0
        
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
              let bearing = cameraOptions.bearing else { return }
        
        let zoomLevelDistance = CLLocationDistance(abs(mapView.cameraView.zoom - zoom))
        let levelsPerSecondMaxZoomAnimation: Double = 0.6
        let zoomAnimationDuration: TimeInterval = max(min(zoomLevelDistance / levelsPerSecondMaxZoomAnimation, 0.8), 0.2)
        let zoomAnimationDelay: TimeInterval = 0
        let endZoomAnimation: TimeInterval = zoomAnimationDuration + zoomAnimationDelay
        
        let centerTranslationDistance = CLLocation.distance(from: mapView.cameraView.centerCoordinate, to: location)
        let metersPerSecondMaxCenterAnimation: Double = 1000.0
        let centerAnimationDuration: TimeInterval = max(min(centerTranslationDistance / metersPerSecondMaxCenterAnimation, 1.4), 0.8)
        let centerAnimationDelay: TimeInterval = max(endZoomAnimation - centerAnimationDuration, 0)
        
        let bearingDegreesChange: CLLocationDirection = bearing.shortestRotation(angle: CLLocationDirection(mapView.cameraView.bearing))
        let degreesPerSecondMaxBearingAnimation: Double = 60
        let bearingAnimationDuration: TimeInterval = max(min(bearingDegreesChange / degreesPerSecondMaxBearingAnimation, 1.2), 0.8)
        let bearingAnimationDelay: TimeInterval = max(endZoomAnimation - bearingAnimationDuration - 0.4, 0)
        
        let pitchAndAnchorAnimationDuration: TimeInterval = 0.6
        let pitchAndAnchorAnimationDelay: TimeInterval = 0
        
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
              let zoom = transitionParameters.cameraOptions.zoom,
              let location = transitionParameters.cameraOptions.center,
              let bearing = transitionParameters.cameraOptions.bearing,
              let pitch = transitionParameters.cameraOptions.pitch,
              let anchor = transitionParameters.cameraOptions.anchor else { return }
        
        stopAnimators()
        
        let animationsGroup = DispatchGroup()
        
        let bezierParamsCenter = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.4, y: 0.0), controlPoint2: CGPoint(x: 0.6, y: 1.0))
        animatorCenter = UIViewPropertyAnimator(duration: transitionParameters.centerAnimationDuration, timingParameters: bezierParamsCenter)
        animatorCenter.addAnimations {
            mapView.cameraView.centerCoordinate = location
        }
        animatorCenter.addCompletion { _ in
            animationsGroup.leave()
        }

        let bezierParamsZoom = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.2, y: 0.0), controlPoint2: CGPoint(x: 0.6, y: 1.0))
        animatorZoom = UIViewPropertyAnimator(duration: transitionParameters.zoomAnimationDuration, timingParameters: bezierParamsZoom)
        animatorZoom.addAnimations {
            mapView.cameraView.zoom = zoom
        }
        animatorZoom.addCompletion { _ in
            animationsGroup.leave()
        }
        
        let bezierParamsBearing = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.4, y: 0.0), controlPoint2: CGPoint(x: 0.6, y: 1.0))
        animatorBearing = UIViewPropertyAnimator(duration: transitionParameters.bearingAnimationDuration, timingParameters: bezierParamsBearing)
        animatorBearing.addAnimations {
            mapView.cameraView.bearing = CGFloat(bearing)
        }
        animatorBearing.addCompletion { _ in
            animationsGroup.leave()
        }
        
        let bezierParamsPitch = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.6, y: 0.0), controlPoint2: CGPoint(x: 0.4, y: 1.0))
        animatorPitch = UIViewPropertyAnimator(duration: transitionParameters.pitchAndAnchorAnimationDuration, timingParameters: bezierParamsPitch)
        animatorPitch.addAnimations {
            mapView.cameraView.pitch = CGFloat(pitch)
            mapView.cameraView.anchor = anchor
        }
        animatorPitch.addCompletion { _ in
            animationsGroup.leave()
        }
        
        let animations: [(UIViewPropertyAnimator, TimeInterval)] = [
            (animatorCenter, transitionParameters.centerAnimationDelay),
            (animatorZoom, transitionParameters.zoomAnimationDelay),
            (animatorBearing, transitionParameters.bearingAnimationDelay),
            (animatorPitch, transitionParameters.pitchAndAnchorAnimationDelay),
        ]

        animations.forEach { (animator, delay) in
            animationsGroup.enter()
            animator.startAnimation(afterDelay: fmax(delay, 0))
        }

        animationsGroup.notify(queue: .main) {
            self.resetAnimators()
            completion()
        }
    }
    
    func transitionDestinationIsOffScreen(_ transitionDestination: CLLocationCoordinate2D, edgeInsets: UIEdgeInsets = .zero) -> Bool {
        guard let mapView = mapView else { return false }
        let halo = UIEdgeInsets(top: edgeInsets.top - 40, left: -40, bottom: edgeInsets.bottom - 40, right: -40)
        
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
