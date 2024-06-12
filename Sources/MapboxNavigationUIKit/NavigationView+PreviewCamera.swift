import MapboxNavigationCore
import UIKit

extension NavigationView {
    func moveCamera(to cameraMode: Preview.CameraMode) {
        let navigationCamera = navigationMapView.navigationCamera
        guard let navigationViewportDataSource = navigationCamera.viewportDataSource as? MobileViewportDataSource else {
            return
        }

        switch cameraMode {
        case .idle:
            break
        case .centered:
            navigationViewportDataSource.options.followingCameraOptions.centerUpdatesAllowed = true
            navigationViewportDataSource.options.followingCameraOptions.bearingUpdatesAllowed = false
            navigationViewportDataSource.options.followingCameraOptions.pitchUpdatesAllowed = false
            navigationViewportDataSource.options.followingCameraOptions.zoomUpdatesAllowed = false
            navigationViewportDataSource.options.followingCameraOptions.paddingUpdatesAllowed = false
            navigationViewportDataSource.options.followingCameraOptions.followsLocationCourse = false

            navigationViewportDataSource.currentNavigationCameraOptions.followingCamera.bearing = 0.0
            navigationViewportDataSource.currentNavigationCameraOptions.followingCamera
                .padding = UIEdgeInsets(floatLiteral: 10.0)
            navigationViewportDataSource.currentNavigationCameraOptions.followingCamera.pitch = 0.0
            navigationViewportDataSource.currentNavigationCameraOptions.followingCamera.zoom = 14.0

            navigationCamera.update(cameraState: .following)
        case .following:
            navigationViewportDataSource.options.followingCameraOptions.centerUpdatesAllowed = true
            navigationViewportDataSource.options.followingCameraOptions.bearingUpdatesAllowed = true
            navigationViewportDataSource.options.followingCameraOptions.pitchUpdatesAllowed = false
            navigationViewportDataSource.options.followingCameraOptions.zoomUpdatesAllowed = false
            navigationViewportDataSource.options.followingCameraOptions.paddingUpdatesAllowed = false
            navigationViewportDataSource.options.followingCameraOptions.followsLocationCourse = true

            let topInset: CGFloat = UIScreen.main.bounds.height - 150.0 - navigationMapView.mapView.safeAreaInsets
                .bottom
            let bottomInset: CGFloat = 149.0 + navigationMapView.mapView.safeAreaInsets.bottom
            let leftInset: CGFloat = 50.0
            let rightInset: CGFloat = 50.0

            let padding = UIEdgeInsets(
                top: topInset,
                left: leftInset,
                bottom: bottomInset,
                right: rightInset
            )

            navigationViewportDataSource.currentNavigationCameraOptions.followingCamera.padding = padding
            navigationViewportDataSource.currentNavigationCameraOptions.followingCamera.pitch = 40.0
            navigationViewportDataSource.currentNavigationCameraOptions.followingCamera.zoom = 14.0

            navigationCamera.update(cameraState: .following)
        }
    }
}
