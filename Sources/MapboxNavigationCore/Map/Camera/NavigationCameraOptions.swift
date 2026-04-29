import Foundation
import MapboxMaps

/// Represents calculated navigation camera options.
public struct NavigationCameraOptions: Equatable, Sendable {
    /// `CameraOptions`, which are used when transitioning to ``NavigationCameraState/following`` or for continuous
    /// updates when already in ``NavigationCameraState/following`` state.
    public var followingCamera: CameraOptions

    /// `CameraOptions`, which are used when transitioning to ``NavigationCameraState/overview`` or for continuous
    /// updates when already in ``NavigationCameraState/overview`` state.
    public var overviewCamera: CameraOptions

    /// Creates a new ``NavigationCameraOptions`` instance.
    /// - Parameters:
    ///   - followingCamera: `CameraOptions` used in the ``NavigationCameraState/following`` state.
    ///   - overviewCamera: `CameraOptions` used in  the``NavigationCameraState/overview`` state.
    public init(followingCamera: CameraOptions = .init(), overviewCamera: CameraOptions = .init()) {
        self.followingCamera = followingCamera
        self.overviewCamera = overviewCamera
    }
}
