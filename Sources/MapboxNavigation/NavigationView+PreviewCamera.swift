import UIKit

extension NavigationView {
    
    func moveCamera(to cameraMode: Preview.CameraMode) {
        let navigationCamera = navigationMapView.navigationCamera
        let navigationViewportDataSource = navigationCamera?.viewportDataSource as? NavigationViewportDataSource
        
        switch cameraMode {
        case .idle:
            break
        case .centered:
            navigationViewportDataSource?.options.followingCameraOptions.centerUpdatesAllowed = true
            navigationViewportDataSource?.options.followingCameraOptions.bearingUpdatesAllowed = false
            navigationViewportDataSource?.options.followingCameraOptions.pitchUpdatesAllowed = false
            navigationViewportDataSource?.options.followingCameraOptions.zoomUpdatesAllowed = false
            navigationViewportDataSource?.options.followingCameraOptions.paddingUpdatesAllowed = false
            navigationViewportDataSource?.options.followingCameraOptions.followsLocationCourse = false
            
            navigationViewportDataSource?.followingMobileCamera.bearing = 0.0
            navigationViewportDataSource?.followingMobileCamera.padding = UIEdgeInsets(floatLiteral: 10.0)
            navigationViewportDataSource?.followingMobileCamera.pitch = 0.0
            navigationViewportDataSource?.followingMobileCamera.zoom = 14.0
            
            navigationCamera?.follow()
        case .following:
            navigationViewportDataSource?.options.followingCameraOptions.centerUpdatesAllowed = true
            navigationViewportDataSource?.options.followingCameraOptions.bearingUpdatesAllowed = true
            navigationViewportDataSource?.options.followingCameraOptions.pitchUpdatesAllowed = false
            navigationViewportDataSource?.options.followingCameraOptions.zoomUpdatesAllowed = false
            navigationViewportDataSource?.options.followingCameraOptions.paddingUpdatesAllowed = false
            navigationViewportDataSource?.options.followingCameraOptions.followsLocationCourse = true
            
            let topInset: CGFloat = UIScreen.main.bounds.height - 150.0 - (navigationMapView.mapView?.safeAreaInsets.bottom ?? 0.0)
            let bottomInset: CGFloat = 149.0 + (navigationMapView.mapView?.safeAreaInsets.bottom ?? 0.0)
            let leftInset: CGFloat = 50.0
            let rightInset: CGFloat = 50.0
            
            let padding = UIEdgeInsets(top: topInset,
                                       left: leftInset,
                                       bottom: bottomInset,
                                       right: rightInset)
            
            navigationViewportDataSource?.followingMobileCamera.padding = padding
            navigationViewportDataSource?.followingMobileCamera.pitch = 40.0
            navigationViewportDataSource?.followingMobileCamera.zoom = 14.0
            
            navigationCamera?.follow()
        }
    }
}
