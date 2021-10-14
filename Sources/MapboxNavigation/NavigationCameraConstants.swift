import Foundation
import MapboxMaps

extension CameraOptions {
    
    // MARK: Camera State Keys
    
    /**
     Key, which is used to access `CameraOptions` provided via `ViewportDataSourceDelegate`
     so that it can be consumed by `NavigationCamera` in `NavigationCameraState.transitionToFollowing`
     or `NavigationCameraState.following` states on iOS.
     */
    public static let followingMobileCamera = "FollowingMobileCamera"
    
    /**
     Key, which is used to access `CameraOptions` provided via `ViewportDataSourceDelegate`
     so that it can be consumed by `NavigationCamera` in `NavigationCameraState.transitionToOverview`
     or `NavigationCameraState.overview` states on iOS.
     */
    public static let overviewMobileCamera = "OverviewMobileCamera"
    
    /**
     Key, which is used to access `CameraOptions` provided via `ViewportDataSourceDelegate`
     so that it can be consumed by `NavigationCamera` in `NavigationCameraState.transitionToFollowing`
     or `NavigationCameraState.following` states on CarPlay.
     */
    public static let followingCarPlayCamera = "FollowingCarPlayCamera"
    
    /**
     Key, which is used to access `CameraOptions` provided via `ViewportDataSourceDelegate`
     so that it can be consumed by `NavigationCamera` in `NavigationCameraState.transitionToOverview`
     or `NavigationCameraState.overview` states on CarPlay.
     */
    public static let overviewCarPlayCamera = "OverviewCarPlayCamera"
}

extension Notification.Name {

    // MARK: Observing Camera Updates
    
    /**
     Posted when value of `NavigationCamera.state` property changes.
     
     The user info dictionary contains `NavigationCamera.NotificationUserInfoKey.state` key.
     */
    public static let navigationCameraStateDidChange: Notification.Name = .init(rawValue: "NavigationCameraStateDidChange")
    
    /**
     Posted when `NavigationViewportDataSource` changes underlying `CameraOptions`, which will be used by
     `NavigationCameraStateTransition` when running camera related transitions on `iOS` and `CarPlay`.
     
     The user info dictionary contains `NavigationCamera.NotificationUserInfoKey.cameraOptions` key.
     */
    public static let navigationCameraViewportDidChange: Notification.Name = .init(rawValue: "NavigationViewportDidChange")
}

extension NavigationCamera {

    public struct NotificationUserInfoKey: Hashable, Equatable, RawRepresentable {
        public typealias RawValue = String

        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        /**
         A key in the user info dictionary of a `Notification.Name.navigationCameraStateDidChange` notification. The corresponding value is a `NavigationCameraState` object.
         */
        public static let state: NotificationUserInfoKey = .init(rawValue: "state")
        
        /**
         A key in the user info dictionary of a `Notification.Name.navigationCameraViewportDidChange` notification. The corresponding value is a `[String: CameraOptions]` dictionary object.
         */
        public static let cameraOptions: NotificationUserInfoKey = .init(rawValue: "cameraOptions")
    }
}
