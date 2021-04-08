import Foundation
import MapboxMaps

extension CameraOptions {
    
    public static let followingMobileCameraKey = "FollowingMobileCamera"
    
    public static let overviewMobileCameraKey = "OverviewMobileCamera"
    
    public static let followingCarPlayCameraKey = "FollowingCarPlayCamera"
    
    public static let overviewCarPlayCameraKey = "OverviewCarPlayCamera"
}

extension Notification.Name {

    /**
     Posted when value of `NavigationCamera.state` property changes.
     
     The user info dictionary contains `NavigationCamera.NotificationUserInfoKey.stateKey` key.
     */
    public static let navigationCameraStateDidChange: Notification.Name = .init(rawValue: "NavigationCameraStateDidChange")
    
    /**
     Posted when `NavigationViewportDataSource` changes underlying `CameraOptions`, which will be used by
     `NavigationCameraStateTransition` when running camera related transitions on `iOS` and `CarPlay`.
     
     The user info dictionary contains `NavigationCamera.NotificationUserInfoKey.cameraOptionsKey` key.
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
        public static let stateKey: NotificationUserInfoKey = .init(rawValue: "state")
        
        /**
         A key in the user info dictionary of a `Notification.Name.navigationCameraViewportDidChange` notification. The corresponding value is a `[String: CameraOptions]` dictionary object.
         */
        public static let cameraOptionsKey: NotificationUserInfoKey = .init(rawValue: "cameraOptions")
    }
}
