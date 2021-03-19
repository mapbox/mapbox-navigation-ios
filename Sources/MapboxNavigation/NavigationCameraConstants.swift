import Foundation
import MapboxMaps

extension CameraOptions {
    
    public static let followingMobileCameraKey = "FollowingMobileCamera"
    
    public static let overviewMobileCameraKey = "OverviewMobileCamera"
    
    public static let followingHeadUnitCameraKey = "FollowingHeadUnitCamera"
    
    public static let overviewHeadUnitCameraKey = "OverviewHeadUnitCamera"
}

public extension Notification.Name {

    static let navigationCameraStateDidChange: Notification.Name = .init(rawValue: "NavigationCameraStateDidChange")
    
    static let navigationCameraViewportDidChange: Notification.Name = .init(rawValue: "NavigationViewportDidChange")
}

extension NavigationCamera {

    public struct NotificationUserInfoKey: Hashable, Equatable, RawRepresentable {
        public typealias RawValue = String

        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        public static let stateKey: NotificationUserInfoKey = .init(rawValue: "state")
        
        public static let cameraOptionsKey: NotificationUserInfoKey = .init(rawValue: "cameraOptions")
    }
}
