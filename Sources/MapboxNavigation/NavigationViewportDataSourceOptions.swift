import Foundation

/**
 Options, which give the ability to control whether certain `CameraOptions` will be generated
 by `NavigationViewportDataSource` or can be provided by user directly.
 */
public struct NavigationViewportDataSourceOptions: Equatable {
    
    /**
     Options, which are used to control what `CameraOptions` parameters will be modified by
     `NavigationViewportDataSource` in `NavigationCameraState.following` state.
     */
    public var followingCameraOptions = FollowingCameraOptions()
    
    /**
     Options, which are used to control what `CameraOptions` parameters will be modified by
     `NavigationViewportDataSource` in `NavigationCameraState.overview` state.
     */
    public var overviewCameraOptions = OverviewCameraOptions()
    
    /**
     Initializes `NavigationViewportDataSourceOptions` instance.
     */
    public init() {
        // No-op
    }
    
    /**
     Initializes `NavigationViewportDataSourceOptions` instance.
     
     - parameter followingCameraOptions: `FollowingCameraOptions` instance, which contains
     `CameraOptions` parameters, which in turn will be used by `NavigationViewportDataSource` in
     `NavigationCameraState.following` state.
     - parameter overviewCameraOptions: `OverviewCameraOptions` instance, which contains
     `CameraOptions` parameters, which it turn will be used by `NavigationViewportDataSource` in
     `NavigationCameraState.overview` state.
     */
    public init(_ followingCameraOptions: FollowingCameraOptions, overviewCameraOptions: OverviewCameraOptions) {
        self.followingCameraOptions = followingCameraOptions
        self.overviewCameraOptions = overviewCameraOptions
    }
    
    public static func == (lhs: NavigationViewportDataSourceOptions, rhs: NavigationViewportDataSourceOptions) -> Bool {
        return lhs.followingCameraOptions == rhs.followingCameraOptions &&
            lhs.overviewCameraOptions == rhs.overviewCameraOptions
    }
}
