import MapboxMaps
import Turf
import UIKit

/// The class, which conforms to ``CameraStateTransition`` protocol and provides default implementation of
/// camera-related transitions by using `CameraAnimator` functionality provided by Mapbox Maps SDK.
@MainActor
public class NavigationCameraStateTransition: CameraStateTransition {
    // MARK: Transitioning State

    /// A map view to which corresponding camera is related.
    public weak var mapView: MapView?

    var animatorCenter: BasicCameraAnimator?
    var animatorZoom: BasicCameraAnimator?
    var animatorBearing: BasicCameraAnimator?
    var animatorPitch: BasicCameraAnimator?
    var animatorAnchor: BasicCameraAnimator?
    var animatorPadding: BasicCameraAnimator?

    var previousAnchor: CGPoint = .zero

    /// Initializer of ``NavigationCameraStateTransition`` object.
    /// - Parameter mapView: `MapView` to which corresponding camera is related.
    public required init(_ mapView: MapView) {
        self.mapView = mapView
    }

    /// Performs a camera transition to new camera options.
    ///
    /// - parameter cameraOptions: An instance of `CameraOptions`, which describes a viewpoint of the `MapView`.
    /// - parameter completion: A completion handler, which is called after performing the transition.
    public func transitionTo(
        _ cameraOptions: CameraOptions,
        completion: @escaping () -> Void
    ) {
        guard let mapView,
              let zoom = cameraOptions.zoom
        else {
            completion()
            return
        }

        if let center = cameraOptions.center, !CLLocationCoordinate2DIsValid(center) {
            completion()
            return
        }

        stopAnimators()
        let duration: TimeInterval = mapView.mapboxMap.cameraState.zoom < zoom ? 0.5 : 0.25
        mapView.camera.fly(to: cameraOptions, duration: duration) { _ in
            completion()
        }
    }

    ///  Cancels the current transition.
    public func cancelPendingTransition() {
        stopAnimators()
    }

    /// Performs a camera update, when already in the ``NavigationCameraState/overview`` state
    /// or ``NavigationCameraState/following`` state.
    ///
    /// - parameter cameraOptions: An instance of `CameraOptions`, which describes a viewpoint of the `MapView`.
    ///  - parameter state: An instance of ``NavigationCameraState``, which describes the current state of
    /// ``NavigationCamera``.
    public func update(to cameraOptions: CameraOptions, state: NavigationCameraState) {
        guard let mapView,
              let center = cameraOptions.center,
              CLLocationCoordinate2DIsValid(center),
              let zoom = cameraOptions.zoom,
              let bearing = (state == .overview) ? 0.0 : cameraOptions.bearing,
              let pitch = cameraOptions.pitch,
              let anchor = cameraOptions.anchor,
              let padding = cameraOptions.padding else { return }

        let duration = 1.0
        let minimumCenterCoordinatePixelThreshold = 2.0
        let minimumPitchThreshold: CGFloat = 1.0
        let minimumBearingThreshold: CLLocationDirection = 1.0
        let timingParameters = UICubicTimingParameters(
            controlPoint1: CGPoint(x: 0.0, y: 0.0),
            controlPoint2: CGPoint(x: 1.0, y: 1.0)
        )

        // Check whether the location change is larger than a certain threshold when current camera state is following.
        var updateCameraCenter = true
        if state == .following {
            let metersPerPixel = getMetersPerPixelAtLatitude(center.latitude, Double(zoom))
            let centerUpdateThreshold = minimumCenterCoordinatePixelThreshold * metersPerPixel
            updateCameraCenter = (mapView.mapboxMap.cameraState.center.distance(to: center) > centerUpdateThreshold)
        }

        if updateCameraCenter {
            if let animatorCenter, animatorCenter.isRunning {
                animatorCenter.stopAnimation()
            }

            animatorCenter = mapView.camera.makeAnimator(
                duration: duration,
                timingParameters: timingParameters
            ) { transition in
                transition.center.toValue = center
            }

            animatorCenter?.startAnimation()
        }

        if let animatorZoom, animatorZoom.isRunning {
            animatorZoom.stopAnimation()
        }

        animatorZoom = mapView.camera.makeAnimator(
            duration: duration,
            timingParameters: timingParameters
        ) { transition in
            transition.zoom.toValue = zoom
        }

        animatorZoom?.startAnimation()

        // Check whether the bearing change is larger than a certain threshold when current camera state is following.
        let updateCameraBearing = (state == .following) ?
            (abs(mapView.mapboxMap.cameraState.bearing - bearing) >= minimumBearingThreshold) : true

        if updateCameraBearing {
            if let animatorBearing, animatorBearing.isRunning {
                animatorBearing.stopAnimation()
            }

            animatorBearing = mapView.camera.makeAnimator(
                duration: duration,
                timingParameters: timingParameters
            ) { transition in
                transition.bearing.toValue = bearing
            }

            animatorBearing?.startAnimation()
        }

        // Check whether the pitch change is larger than a certain threshold when current camera state is following.
        let updateCameraPitch = (state == .following) ?
            (abs(mapView.mapboxMap.cameraState.pitch - pitch) >= minimumPitchThreshold) : true

        if updateCameraPitch {
            if let animatorPitch, animatorPitch.isRunning {
                animatorPitch.stopAnimation()
            }

            animatorPitch = mapView.camera.makeAnimator(
                duration: duration,
                timingParameters: timingParameters
            ) { transition in
                transition.pitch.toValue = pitch
            }

            animatorPitch?.startAnimation()
        }

        // In case if anchor did not change - do not perform animation.
        let updateCameraAnchor = previousAnchor != anchor
        previousAnchor = anchor

        if updateCameraAnchor {
            if let animatorAnchor, animatorAnchor.isRunning {
                animatorAnchor.stopAnimation()
            }

            animatorAnchor = mapView.camera.makeAnimator(
                duration: duration,
                timingParameters: timingParameters
            ) { transition in
                transition.anchor.toValue = anchor
            }

            animatorAnchor?.startAnimation()
        }

        if let animatorPadding, animatorPadding.isRunning {
            animatorPadding.stopAnimation()
        }

        animatorPadding = mapView.camera.makeAnimator(
            duration: duration,
            timingParameters: timingParameters
        ) { transition in
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
            animatorPadding,
        ]
        mapView?.camera.cancelAnimations()
        animators.compactMap { $0 }.forEach {
            if $0.isRunning {
                $0.stopAnimation()
            }
        }
    }
}
