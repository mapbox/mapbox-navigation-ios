import MapboxMaps

public class NavigationCameraStateTransition: CameraStateTransition {

    weak public var mapView: MapView?
    
    var cameraView: CameraView!
    
    required public init(_ mapView: MapView) {
        self.mapView = mapView
        
        cameraView = CameraView(mapView: mapView)
        mapView.addSubview(cameraView)
    }
    
    public func transitionToFollowing(_ cameraOptions: CameraOptions, completion: (() -> Void)? = nil) {
        // TODO: Replace with specific set of animations.
        mapView?.cameraManager.setCamera(to: cameraOptions,
                                         animated: true,
                                         duration: 1.0,
                                         completion: { _ in
                                            completion?()
                                         })
    }

    public func transitionToOverview(_ cameraOptions: CameraOptions, completion: (() -> Void)? = nil) {
        // TODO: Replace with specific set of animations.
        mapView?.cameraManager.setCamera(to: cameraOptions,
                                         animated: true,
                                         duration: 1.0,
                                         completion: { _ in
                                            completion?()
                                         })
    }

    public func updateForFollowing(_ cameraOptions: CameraOptions, completion: (() -> Void)? = nil) {
        // TODO: Replace with specific set of animations.
        let numberOfAnimators = 4
        var animatorsComplete = 0
        
        var animatorCenter: UIViewPropertyAnimator? = nil
        var animatorZoom: UIViewPropertyAnimator? = nil
        var animatorBearing: UIViewPropertyAnimator? = nil
        var animatorPitch: UIViewPropertyAnimator? = nil
        
        let onCompletion = {
            animatorsComplete += 1
            if animatorsComplete == numberOfAnimators {
                self.cameraView.isActive = false
                completion?()
            }
        }
        
        cameraView.isActive = true
        if let centerCoordinate = cameraOptions.center {
            let bezierParamsCenter = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.4, y: 0.0), controlPoint2: CGPoint(x: 0.6, y: 1.0))
            animatorCenter = UIViewPropertyAnimator(duration: 1.0, timingParameters: bezierParamsCenter)
            animatorCenter?.addAnimations {
                self.cameraView.centerCoordinate = centerCoordinate
            }
            
            animatorCenter?.addCompletion { _ in
                onCompletion()
            }
        }
        
        if let zoom = cameraOptions.zoom {
            let bezierParamsZoom = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.6, y: 0.0), controlPoint2: CGPoint(x: 0.4, y: 1.0))
            animatorZoom = UIViewPropertyAnimator(duration: 1.0, timingParameters: bezierParamsZoom)
            animatorZoom?.addAnimations {
                self.cameraView.zoomLevel = zoom
            }
            
            animatorZoom?.addCompletion { _ in
                onCompletion()
            }
        }
        
        if let bearing = cameraOptions.bearing {
            let bezierParamsBearing = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.4, y: 0.0), controlPoint2: CGPoint(x: 0.6, y: 1.0))
            animatorBearing = UIViewPropertyAnimator(duration: 1.0, timingParameters: bezierParamsBearing)
            animatorBearing?.addAnimations {
                self.cameraView.bearing = bearing
            }
            
            animatorBearing?.addCompletion { _ in
                onCompletion()
            }
        }
        
        if let pitch = cameraOptions.pitch {
            let bezierParamsPitch = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.6, y: 0.0), controlPoint2: CGPoint(x: 0.4, y: 1.0))
            animatorPitch = UIViewPropertyAnimator(duration: 1.0, timingParameters: bezierParamsPitch)
            animatorPitch?.addAnimations {
                self.cameraView.pitch = pitch
            }
            
            animatorPitch?.addCompletion { _ in
                onCompletion()
            }
        }
        
        animatorCenter?.startAnimation(afterDelay: 0.0)
        animatorZoom?.startAnimation(afterDelay: 0.0)
        animatorBearing?.startAnimation(afterDelay: 0.0)
        animatorPitch?.startAnimation(afterDelay: 0.0)
    }

    public func updateForOverview(_ cameraOptions: CameraOptions, completion: (() -> Void)? = nil) {
        // TODO: Replace with specific set of animations.
        mapView?.cameraManager.setCamera(to: cameraOptions,
                                         animated: true,
                                         duration: 1.0,
                                         completion: { _ in
                                            completion?()
                                         })
    }
    
    public func cancelPendingTransition() {
        mapView?.cameraManager.cancelTransitions()
    }
}
