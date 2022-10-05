import UIKit

extension NavigationCamera {
    
    func move(to cameraMode: Preview.CameraMode) {
        switch cameraMode {
        case .idle:
            stop()
        case .centered:
            fallthrough
        case .following:
            update(to: cameraMode)
            follow()
        }
    }
    
    func update(to cameraMode: Preview.CameraMode) {
        let navigationViewportDataSource = viewportDataSource as? NavigationViewportDataSource
        let passiveLocationProvider = mapView?.location.locationProvider as? PassiveLocationProvider
        let location = passiveLocationProvider?.locationManager.location
        
        switch cameraMode {
        case .idle:
            break
        case .centered:
            navigationViewportDataSource?.options.followingCameraOptions.bearingUpdatesAllowed = false
            navigationViewportDataSource?.options.followingCameraOptions.pitchUpdatesAllowed = false
            navigationViewportDataSource?.options.followingCameraOptions.zoomUpdatesAllowed = false
            navigationViewportDataSource?.options.followingCameraOptions.centerUpdatesAllowed = false
            navigationViewportDataSource?.options.followingCameraOptions.paddingUpdatesAllowed = false
            
            navigationViewportDataSource?.followingMobileCamera.center = location?.coordinate
            navigationViewportDataSource?.followingMobileCamera.padding = UIEdgeInsets(floatLiteral: 10.0)
            navigationViewportDataSource?.followingMobileCamera.bearing = 0.0
            navigationViewportDataSource?.followingMobileCamera.pitch = 0.0
            navigationViewportDataSource?.followingMobileCamera.zoom = 14.0
        case .following:
            navigationViewportDataSource?.options.followingCameraOptions.centerUpdatesAllowed = true
            navigationViewportDataSource?.options.followingCameraOptions.bearingUpdatesAllowed = false
            navigationViewportDataSource?.options.followingCameraOptions.pitchUpdatesAllowed = false
            navigationViewportDataSource?.options.followingCameraOptions.paddingUpdatesAllowed = false
            navigationViewportDataSource?.options.followingCameraOptions.zoomUpdatesAllowed = false
            
            let topInset: CGFloat = UIScreen.main.bounds.height - 150.0 - (mapView?.safeAreaInsets.bottom ?? 0.0)
            let bottomInset: CGFloat = 149.0 + (mapView?.safeAreaInsets.bottom ?? 0.0)
            let leftInset: CGFloat = 50.0
            let rightInset: CGFloat = 50.0
            
            let padding = UIEdgeInsets(top: topInset,
                                       left: leftInset,
                                       bottom: bottomInset,
                                       right: rightInset)
            
            navigationViewportDataSource?.followingMobileCamera.bearing = location?.course
            navigationViewportDataSource?.followingMobileCamera.pitch = 40.0
            navigationViewportDataSource?.followingMobileCamera.padding = padding
            navigationViewportDataSource?.followingMobileCamera.zoom = 14.0
        }
    }
}
