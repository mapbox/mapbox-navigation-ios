import MapboxMaps
import MapboxNavigation

extension NavigationView {
    
    func previewCameraOptions() -> CameraOptions {
        let topInset: CGFloat
        let bottomInset: CGFloat
        let leftInset: CGFloat
        let rightInset: CGFloat
        let spacing = 50.0
        
        if traitCollection.verticalSizeClass == .regular {
            topInset = topBannerContainerView.frame.height
            bottomInset = bottomBannerContainerView.frame.height
            leftInset = navigationMapView.mapView.safeAreaInsets.left
            rightInset = navigationMapView.mapView.safeAreaInsets.right
        } else {
            topInset = 0.0
            bottomInset = 0.0
            leftInset = bottomBannerContainerView.frame.width
            rightInset = navigationMapView.mapView.safeAreaInsets.right
        }
        
        let padding = UIEdgeInsets(top: topInset + spacing,
                                   left: leftInset + spacing,
                                   bottom: bottomInset + spacing,
                                   right: rightInset + spacing)
        
        let pitch: CGFloat = 0.0
        let bearing: CGFloat = 0.0
        
        return CameraOptions(padding: padding, bearing: bearing, pitch: pitch)
    }
}
