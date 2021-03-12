import MapboxMaps
import Turf

public class NavigationCameraStateTransition: CameraStateTransition {

    public weak var mapView: MapView?
    
    public var cameraView: CameraView!
    
    let followingWithoutRouteZoomLevel = 16.0
    let maxPitch = 60.0
    let bearingDiffForEasing = 60.0
    
    let bezierParamsCenter = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.0, y: 0.0), controlPoint2: CGPoint(x: 1.0, y: 1.0))
    let bezierParamsUserLocation = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.0, y: 0.0), controlPoint2: CGPoint(x: 1.0, y: 1.0))
    let bezierParamsZoom = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.0, y: 0.0), controlPoint2: CGPoint(x: 1.0, y: 1.0))
    let bezierParamsEasedZoom = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.4, y: 0.0), controlPoint2: CGPoint(x: 0.6, y: 1.0))
    let bezierParamsBearing = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.0, y: 0.0), controlPoint2: CGPoint(x: 1.0, y: 1.0))
    let bezierParamsEasedBearing = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.4, y: 0.0), controlPoint2: CGPoint(x: 0.6, y: 1.0))
    let bezierParamsPitch = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.0, y: 0.0), controlPoint2: CGPoint(x: 1.0, y: 1.0))
    let bezierParamsEasedPitch = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.4, y: 0.0), controlPoint2: CGPoint(x: 0.6, y: 1.0))
    
    var animatorCenter: UIViewPropertyAnimator!
    var animatorUserLocation: UIViewPropertyAnimator!
    var animatorZoom: UIViewPropertyAnimator!
    var animatorEasedZoom: UIViewPropertyAnimator!
    var animatorBearing: UIViewPropertyAnimator!
    var animatorEasedBearing: UIViewPropertyAnimator!
    var animatorPitch: UIViewPropertyAnimator!
    var animatorEasedPitch: UIViewPropertyAnimator!
    
    var cameraParametersInTransition: CameraParameters = []
    var cameraParameters: CameraParameters = []
    
    required public init(_ mapView: MapView) {
        self.mapView = mapView
        
        cameraView = CameraView(mapView: mapView)
        mapView.addSubview(cameraView)
        
        setUpAnimatorsForFollowing()
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
        
        stopAnimators()
        cameraView.isActive = true
        
        if transitionDestinationIsOffScreen(location, edgeInsets: padding) {
            let midPointPitchAndScreenCoordinate = getPitchAndScreenCenterPoint(pitchEffectPercentage: 0,
                                                                                maxPitch: 0,
                                                                                bounds: mapView.bounds,
                                                                                edgeInsets: padding)
            
            let lineString = LineString([cameraView.centerCoordinate, location])
            let inputCamera = mapView.cameraManager.camera(fitting: .lineString(lineString))
            inputCamera.bearing = cameraView.bearing
            inputCamera.pitch = 0
            guard let midPointZoom = inputCamera.zoom else { return }

            let cameraOptions = CameraOptions(center: location,
                                              anchor: midPointPitchAndScreenCoordinate.screenCenterPoint,
                                              zoom: CGFloat(midPointZoom),
                                              bearing: bearing,
                                              pitch: 0.0)
            
            transitionFromHighZoomToMidpoint(cameraOptions) {
                self.stopAnimators()
                let cameraOptions = CameraOptions(center: location,
                                                  anchor: anchor,
                                                  zoom: CGFloat(zoom),
                                                  bearing: bearing,
                                                  pitch: CGFloat(pitch))
                
                self.transitionFromLowZoomToHighZoom(cameraOptions) {
                    completion()
                }
            }
            
        } else {
            if cameraView.zoomLevel < zoom {
                transitionFromLowZoomToHighZoom(cameraOptions) {
                    self.setUpAnimatorsForFollowing()
                    completion()
                }
            } else {
                transitionFromHighZoomToLowZoom(cameraOptions) {
                    self.setUpAnimatorsForFollowing()
                    completion()
                }
            }
        }
    }
    
    public func transitionToOverview(_ cameraOptions: CameraOptions, completion: @escaping (() -> Void)) {
        guard let zoom = cameraOptions.zoom else {
            completion()
            return
        }
        
        cameraOptions.pitch = 0
        
        if cameraView.zoomLevel < zoom {
            transitionFromLowZoomToHighZoom(cameraOptions) {
                completion()
            }
        } else {
            transitionFromHighZoomToLowZoom(cameraOptions) {
                completion()
            }
        }
    }
    
    public func updateForFollowing(_ cameraOptions: CameraOptions, completion: (() -> Void)?) {
        update(cameraOptions) {
            completion?()
        }
    }
    
    public func updateForOverview(_ cameraOptions: CameraOptions, completion: (() -> Void)?) {
        update(cameraOptions) {
            completion?()
        }
    }
    
    func update(_ cameraOptions: CameraOptions, completion: (() -> Void)?) {
        guard let zoom = cameraOptions.zoom,
              let location = cameraOptions.center,
              let bearing = cameraOptions.bearing,
              let pitch = cameraOptions.pitch,
              let anchor = cameraOptions.anchor else { return }
        
        cameraView.isActive = true
        
        let numberOfAnimators = 4
        var animatorsComplete = 0
        let completion = {
            animatorsComplete += 1
            if animatorsComplete == numberOfAnimators {
                completion?()
                self.cameraView.isActive = false
            }
        }

        if cameraParameters.contains(.center) {
            if animatorCenter.state == .inactive || animatorCenter.state == .stopped {
                animatorCenter.startAnimation(afterDelay: 0)
            }
            
            animatorCenter.addAnimations {
                self.cameraView.centerCoordinate = location
            }
            
            animatorCenter.addCompletion { _ in
                completion()
            }
        }
        
        // TODO: Clarify whether zoom, bearing and pitch should only be eased in following mode.
        if cameraParameters.contains(.zoom),
           let animator = shouldEaseZoom(Double(zoom)) ? animatorEasedZoom : animatorZoom {
            if animator.state == .inactive || animator.state == .stopped {
                animator.startAnimation(afterDelay: 0)
            }
            
            animator.addAnimations {
                self.cameraView.zoomLevel = zoom
            }
            
            animator.addCompletion { _ in
                completion()
            }
        }
        
        if cameraParameters.contains(.bearing),
           let animator = shouldEaseBearing(bearing) ? animatorEasedBearing : animatorBearing {
            if animator.state == .inactive || animator.state == .stopped {
                animator.startAnimation(afterDelay: 0)
            }
            
            animator.addAnimations {
                self.cameraView.bearing = bearing
            }
            
            animator.addCompletion { _ in
                completion()
            }
        }
        
        if cameraParameters.contains(.pitch),
           let animator = shouldEasePitch(Double(pitch)) ? animatorEasedPitch : animatorPitch {
            if animator.state == .inactive || animator.state == .stopped {
                animator.startAnimation(afterDelay: 0)
            }
            
            animator.addAnimations {
                self.cameraView.pitch = pitch
                self.cameraView.anchorPoint = anchor
            }
            
            animator.addCompletion { _ in
                completion()
            }
        }
    }
    
    public func cancelPendingTransition() {
        stopAnimators()
    }
    
    func setUpAnimatorsForFollowing() {
        if !cameraParametersInTransition.contains(.center) && !cameraParameters.contains(.center) {
            animatorCenter = UIViewPropertyAnimator(duration: 1.0, timingParameters: bezierParamsCenter)
            cameraParameters.insert(.center)
        }
        
        if !cameraParametersInTransition.contains(.zoom) && !cameraParameters.contains(.zoom) {
            animatorZoom = UIViewPropertyAnimator(duration: 1.0, timingParameters: bezierParamsZoom)
            animatorEasedZoom = UIViewPropertyAnimator(duration: 1.4, timingParameters: bezierParamsEasedZoom)
            cameraParameters.insert(.zoom)
        }
        
        if !cameraParametersInTransition.contains(.bearing) && !cameraParameters.contains(.bearing) {
            animatorBearing = UIViewPropertyAnimator(duration: 1.0, timingParameters: bezierParamsBearing)
            animatorEasedBearing = UIViewPropertyAnimator(duration: 1.4, timingParameters: bezierParamsEasedBearing)
            cameraParameters.insert(.bearing)
        }
        
        if !cameraParametersInTransition.contains(.pitch) && !cameraParameters.contains(.pitch) {
            animatorPitch = UIViewPropertyAnimator(duration: 1.0, timingParameters: bezierParamsPitch)
            animatorEasedPitch = UIViewPropertyAnimator(duration: 1.4, timingParameters: bezierParamsEasedPitch)
            cameraParameters.insert(.pitch)
        }
    }
    
    func stopAnimators() {
        let animators = [
            animatorCenter,
            animatorZoom,
            animatorEasedZoom,
            animatorBearing,
            animatorEasedBearing,
            animatorPitch,
            animatorEasedPitch
        ]
        
        animators.forEach {
            $0?.stopAnimation(true)
        }
    }
    
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
    
    func transitionFromLowZoomToHighZoom(_ cameraOptions: CameraOptions, completion: @escaping (() -> Void)) {
        guard let _ = mapView,
              let zoom = cameraOptions.zoom,
              let location = cameraOptions.center,
              let bearing = cameraOptions.bearing else { return }
        
        let currentCenter = cameraView.centerCoordinate
        let point1 = CLLocation(latitude: currentCenter.latitude, longitude: currentCenter.longitude)
        let point2 = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let centerTranslationDistance = point1.distance(from: point2)
        let metersPerSecondMaxCenterAnimation: Double = 1500.0
        let centerAnimationDuration: TimeInterval = max(min(centerTranslationDistance / metersPerSecondMaxCenterAnimation, 1.6), 0.6)
        let centerAnimationDelay: TimeInterval = 0
        
        let currentZoom = Double(cameraView.zoomLevel)
        let zoomLevelDistance: Double = fabs(Double(zoom) - currentZoom)
        let levelsPerSecondMaxZoomAnimation: Double = 3.0
        let zoomAnimationDuration: TimeInterval = max(min(zoomLevelDistance / levelsPerSecondMaxZoomAnimation, 1.6), 0.6)
        let zoomAnimationDelay: TimeInterval = centerAnimationDuration * 0.5
        let endZoomAnimation: TimeInterval = zoomAnimationDuration + zoomAnimationDelay
        
        let currentBearing = cameraView.bearing
        let newBearing: CLLocationDirection = cameraView.bearing + shortestRotationDiff(angle: bearing, anchorAngle: cameraView.bearing)
        let bearingDegreesChange: CLLocationDirection = fabs(newBearing - currentBearing)
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
        guard let _ = mapView,
              let zoom = cameraOptions.zoom,
              let location = cameraOptions.center,
              let bearing = cameraOptions.bearing else { return }

        let currentZoomLevel = Double(cameraView.zoomLevel)
        let newZoomLevel: CLLocationDistance = CLLocationDistance(zoom)
        let zoomLevelDistance: CLLocationDistance = fabs(newZoomLevel - currentZoomLevel)
        let levelsPerSecondMaxZoomAnimation: Double = 0.6
        let zoomAnimationDuration: TimeInterval = max(min(zoomLevelDistance / levelsPerSecondMaxZoomAnimation, 0.8), 0.2)
        let zoomAnimationDelay: TimeInterval = 0
        let endZoomAnimation: TimeInterval = zoomAnimationDuration + zoomAnimationDelay
        
        let currentCenter = cameraView.centerCoordinate
        let newCenter: CLLocationCoordinate2D = location
        let point1 = CLLocation(latitude: currentCenter.latitude, longitude: currentCenter.longitude)
        let point2 = CLLocation(latitude: newCenter.latitude, longitude: newCenter.longitude)
        let centerTranslationDistance = point1.distance(from: point2)
        let metersPerSecondMaxCenterAnimation: Double = 1000.0
        let centerAnimationDuration: TimeInterval = max(min(centerTranslationDistance / metersPerSecondMaxCenterAnimation, 1.4), 0.6)
        let centerAnimationDelay: TimeInterval = max(endZoomAnimation - centerAnimationDuration, 0)
        
        let currentBearing = cameraView.bearing
        let newBearing: CLLocationDirection = cameraView.bearing + shortestRotationDiff(angle: bearing, anchorAngle: cameraView.bearing)
        let bearingDegreesChange: CLLocationDirection = fabs(newBearing - currentBearing)
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
        guard let _ = mapView,
              let zoom = cameraOptions.zoom,
              let location = cameraOptions.center,
              let pitch = cameraOptions.pitch,
              let anchor = cameraOptions.anchor,
              let bearing = cameraOptions.bearing else { return }
        
        let numberOfAnimators = 4
        var animatorsComplete: Int = 0
        
        cameraParametersInTransition = [.center, .zoom, .bearing, .pitch]
        cameraParameters = []
        
        cameraView.isActive = true
        
        let completion = {
            self.setUpAnimatorsForFollowing()
            animatorsComplete += 1
            if animatorsComplete == numberOfAnimators {
                completion()
                self.cameraView.isActive = false
            }
        }
        
        let currentZoomLevel = Double(cameraView.zoomLevel)
        let newZoomLevel: CLLocationDistance = CLLocationDistance(zoom)
        let zoomLevelDistance: CLLocationDistance = fabs(newZoomLevel - currentZoomLevel)
        let levelsPerSecondMaxZoomAnimation: Double = 0.6
        let durationZoomAnimation: TimeInterval = max(min(zoomLevelDistance / levelsPerSecondMaxZoomAnimation, 0.8), 0.2)
        let delayZoomAnimation: TimeInterval = 0
        let endZoomAnimation: TimeInterval = durationZoomAnimation + delayZoomAnimation
        
        let currentCenter = cameraView.centerCoordinate
        let newCenter: CLLocationCoordinate2D = location
        let point1 = CLLocation(latitude: currentCenter.latitude, longitude: currentCenter.longitude)
        let point2 = CLLocation(latitude: newCenter.latitude, longitude: newCenter.longitude)
        let centerTranslationDistance = point1.distance(from: point2)
        let metersPerSecondMaxCenterAnimation: Double = 1000.0
        let durationCenterAnimation: TimeInterval = max(min(centerTranslationDistance / metersPerSecondMaxCenterAnimation, 1.4), 0.8)
        let delayCenterAnimation: TimeInterval = max(endZoomAnimation - durationCenterAnimation, 0)
        
        let newBearing: CLLocationDirection = cameraView.bearing + shortestRotationDiff(angle: bearing, anchorAngle: cameraView.bearing)
        let currentBearing = cameraView.bearing
        let bearingDegreesChange: CLLocationDirection = fabs(newBearing - currentBearing)
        let degreesPerSecondMaxBearingAnimation: Double = 60
        let durationBearingAnimation: TimeInterval = max(min(bearingDegreesChange / degreesPerSecondMaxBearingAnimation, 1.2), 0.8)
        let delayBearingAnimation: TimeInterval = max(endZoomAnimation - durationBearingAnimation - 0.4, 0)
        
        let durationPitchAnchorAnimation: TimeInterval = 0.6
        let delayPitchAnchorAnimation: TimeInterval = 0
        
        let bezierParamsCenter = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.6, y: 0.0), controlPoint2: CGPoint(x: 1.0, y: 1.0))
        animatorCenter = UIViewPropertyAnimator(duration: durationCenterAnimation, timingParameters: bezierParamsCenter)
        animatorCenter.addAnimations {
            self.cameraView.centerCoordinate = location
        }
        animatorCenter.addCompletion { _ in
            self.cameraParametersInTransition.remove(.center)
            completion()
        }
        
        let bezierParamsZoom = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.2, y: 0.0), controlPoint2: CGPoint(x: 0.6, y: 1.0))
        animatorZoom = UIViewPropertyAnimator(duration: durationZoomAnimation, timingParameters: bezierParamsZoom)
        animatorZoom.addAnimations {
            self.cameraView.zoomLevel = CGFloat(zoom)
        }
        animatorZoom.addCompletion { _ in
            self.cameraParametersInTransition.remove(.zoom)
            completion()
        }
        
        let bezierParamsBearing = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.6, y: 0.0), controlPoint2: CGPoint(x: 0.4, y: 1.0))
        animatorBearing = UIViewPropertyAnimator(duration: durationBearingAnimation, timingParameters: bezierParamsBearing)
        animatorBearing.addAnimations {
            self.cameraView.bearing = newBearing
        }
        animatorBearing.addCompletion { _ in
            self.cameraParametersInTransition.remove(.bearing)
            completion()
        }
        
        let bezierParamsPitch = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.6, y: 0.0), controlPoint2: CGPoint(x: 0.4, y: 1.0))
        animatorPitch = UIViewPropertyAnimator(duration: durationPitchAnchorAnimation, timingParameters: bezierParamsPitch)
        animatorPitch.addAnimations {
            self.cameraView.pitch = CGFloat(pitch)
            self.cameraView.anchorPoint = anchor
        }
        animatorPitch.addCompletion { _ in
            self.cameraParametersInTransition.remove(.pitch)
            completion()
        }
        
        animatorCenter.startAnimation(afterDelay: fmax(delayCenterAnimation, 0))
        animatorZoom.startAnimation(afterDelay: fmax(delayZoomAnimation, 0))
        animatorBearing.startAnimation(afterDelay: fmax(delayBearingAnimation, 0))
        animatorPitch.startAnimation(afterDelay: fmax(delayPitchAnchorAnimation, 0))
    }
    
    func transition(_ transitionParameters: TransitionParameters, completion: @escaping (() -> Void)) {
        guard let zoom = transitionParameters.cameraOptions.zoom,
              let location = transitionParameters.cameraOptions.center,
              let bearing = transitionParameters.cameraOptions.bearing,
              let pitch = transitionParameters.cameraOptions.pitch,
              let anchor = transitionParameters.cameraOptions.anchor else { return }
        
        let numberOfAnimators = 4
        var animatorsComplete: Int = 0
        let completion = {
            self.setUpAnimatorsForFollowing()
            animatorsComplete += 1
            if animatorsComplete == numberOfAnimators {
                completion()
                self.cameraView.isActive = false
            }
        }
        
        cameraParametersInTransition = [.center, .zoom, .bearing, .pitch]
        cameraParameters = []
        
        let bezierParamsCenter = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.4, y: 0.0), controlPoint2: CGPoint(x: 0.6, y: 1.0))
        animatorCenter = UIViewPropertyAnimator(duration: transitionParameters.centerAnimationDuration, timingParameters: bezierParamsCenter)
        animatorCenter.addAnimations {
            self.cameraView.centerCoordinate = location
        }
        animatorCenter.addCompletion { _ in
            self.cameraParametersInTransition.remove(.center)
            completion()
        }
        
        // TODO: When transitioning to high zoom following `UICubicTimingParameters` should be used.
        // let bezierParamsZoom = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.6, y: 0.0), controlPoint2: CGPoint(x: 0.4, y: 1.0))

        let bezierParamsZoom = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.2, y: 0.0), controlPoint2: CGPoint(x: 0.6, y: 1.0))
        animatorZoom = UIViewPropertyAnimator(duration: transitionParameters.zoomAnimationDuration, timingParameters: bezierParamsZoom)
        animatorZoom.addAnimations {
            self.cameraView.zoomLevel = zoom
        }
        animatorZoom.addCompletion { _ in
            self.cameraParametersInTransition.remove(.zoom)
            completion()
        }
        
        let bezierParamsBearing = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.4, y: 0.0), controlPoint2: CGPoint(x: 0.6, y: 1.0))
        animatorBearing = UIViewPropertyAnimator(duration: transitionParameters.bearingAnimationDuration, timingParameters: bezierParamsBearing)
        animatorBearing.addAnimations {
            self.cameraView.bearing = bearing
        }
        animatorBearing.addCompletion { _ in
            self.cameraParametersInTransition.remove(.bearing)
            completion()
        }
        
        let bezierParamsPitch = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.6, y: 0.0), controlPoint2: CGPoint(x: 0.4, y: 1.0))
        animatorPitch = UIViewPropertyAnimator(duration: transitionParameters.pitchAndAnchorAnimationDuration, timingParameters: bezierParamsPitch)
        animatorPitch.addAnimations {
            self.cameraView.pitch = CGFloat(pitch)
            self.cameraView.anchorPoint = anchor
        }
        animatorPitch.addCompletion { _ in
            self.cameraParametersInTransition.remove(.pitch)
            completion()
        }
        
        animatorCenter.startAnimation(afterDelay: fmax(transitionParameters.centerAnimationDelay, 0))
        animatorZoom.startAnimation(afterDelay: fmax(transitionParameters.zoomAnimationDelay, 0))
        animatorBearing.startAnimation(afterDelay: fmax(transitionParameters.bearingAnimationDelay, 0))
        animatorPitch.startAnimation(afterDelay: fmax(transitionParameters.pitchAndAnchorAnimationDelay, 0))
    }
    
    func normalizeAngle(angle: CLLocationDirection, anchorAngle: CLLocationDirection) -> CLLocationDirection {
        guard !angle.isNaN && !anchorAngle.isNaN else { return 0.0 }
        
        var localAngle = angle.wrap(min: 0.0, max: 360.0)
        let diff = abs(localAngle - anchorAngle)
        if abs(localAngle - 360.0 - anchorAngle) < diff {
            localAngle -= 360.0
        }
        if abs(localAngle + 360.0 - anchorAngle) < diff {
            localAngle += 360.0
        }
        return localAngle
    }
    
    func transitionDestinationIsOffScreen(_ transitionDestination: CLLocationCoordinate2D, edgeInsets: UIEdgeInsets = .zero) -> Bool {
        guard let mapView = mapView else { return false }
        
        let halo = UIEdgeInsets(top: edgeInsets.top - 40, left: -40, bottom: edgeInsets.bottom - 40, right: -40)
        return !halo.rectValue(mapView.bounds).contains(mapView.point(for: transitionDestination))
    }
    
    func getPitchAndScreenCenterPoint(pitchEffectPercentage: Double,
                                      maxPitch: Double,
                                      bounds: CGRect,
                                      edgeInsets: UIEdgeInsets) -> (pitch: Double, screenCenterPoint: CGPoint) {
        let xCenter = max(((bounds.size.width - edgeInsets.left - edgeInsets.right) / 2.0) + edgeInsets.left, 0.0)
        let height = (bounds.size.height - edgeInsets.top - edgeInsets.bottom)
        let yCenter = max((height / 2.0) + edgeInsets.top, 0.0)
        let yOffsetCenter = max((height / 2.0) - 7.0, 0.0) * CGFloat(pitchEffectPercentage) + yCenter
        return (pitch: maxPitch * pitchEffectPercentage, screenCenterPoint: CGPoint(x: xCenter, y: yOffsetCenter))
    }
    
    func shortestRotationDiff(angle: CLLocationDirection, anchorAngle: CLLocationDirection) -> CLLocationDirection {
        guard !angle.isNaN && !anchorAngle.isNaN else { return 0.0 }
        return (angle - anchorAngle).wrap(min: -180.0, max: 180.0)
    }
    
    func shouldEaseBearing(_ newBearing: CLLocationDirection) -> Bool {
        if let mapView = mapView,
           fabs(shortestRotationDiff(angle: newBearing, anchorAngle: CLLocationDirection(mapView.cameraView.bearing))) >= bearingDiffForEasing {
            return true
        }
        
        return false
    }
    
    func shouldEaseZoom(_ newZoom: Double) -> Bool {
        if let mapView = mapView,
           newZoom < floor(Double(mapView.zoom) * 10) / 10 {
            return true
        }
        
        return false
    }
    
    func shouldEasePitch(_ newPitch: Double) -> Bool {
        if let mapView = mapView,
           CGFloat(newPitch) > mapView.cameraView.pitch {
            return true
        }
        
        return false
    }
}
