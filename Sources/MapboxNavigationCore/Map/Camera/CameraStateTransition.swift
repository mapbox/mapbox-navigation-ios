import MapboxMaps
import UIKit

/// Protocol, which is used to execute camera-related transitions, based on data provided via `CameraOptions` in
/// ``ViewportDataSource``.
@MainActor
public protocol CameraStateTransition: AnyObject {
    // MARK: Updating the Camera

    /// A map view to which corresponding camera is related.
    var mapView: MapView? { get }

    /// Initializer of ``CameraStateTransition`` object.
    ///
    /// - parameter mapView: `MapView` to which corresponding camera is related.
    init(_ mapView: MapView)

    /// Performs a camera transition to new camera options.
    ///
    /// - parameter cameraOptions: An instance of `CameraOptions`, which describes a viewpoint of the `MapView`.
    /// - parameter completion: A completion handler, which is called after performing the transition.
    func transitionTo(_ cameraOptions: CameraOptions, completion: @escaping (() -> Void))

    /// Performs a camera update, when already in the ``NavigationCameraState/overview`` state or
    /// ``NavigationCameraState/following`` state.
    ///
    /// - parameter cameraOptions: An instance of `CameraOptions`, which describes a viewpoint of the `MapView`.
    /// - parameter state: An instance of ``NavigationCameraState``, which describes the current state of
    /// ``NavigationCamera``.
    func update(to cameraOptions: CameraOptions, state: NavigationCameraState)

    ///  Cancels the current transition.
    func cancelPendingTransition()
}
