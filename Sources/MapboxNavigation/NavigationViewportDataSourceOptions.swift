import Foundation

/**
 Options, which give the ability to control whether certain `CameraOptions` will be generated
 by `NavigationViewportDataSource` or can be provided by user directly.
 */
public struct NavigationViewportDataSourceOptions {
    
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
}
