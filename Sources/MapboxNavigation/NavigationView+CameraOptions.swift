import MapboxMaps

extension NavigationView {
    
    func defaultRoutesPreviewCameraOptions() -> CameraOptions {
        let topInset: CGFloat
        let bottomInset: CGFloat
        let leftInset: CGFloat
        let rightInset: CGFloat
        let spacing: CGFloat = 50.0
        
        if traitCollection.verticalSizeClass == .regular {
            topInset = topBannerContainerView.frame.height + spacing
            bottomInset = bottomBannerContainerView.frame.height + spacing
            leftInset = navigationMapView.mapView.safeAreaInsets.left + spacing
            rightInset = navigationMapView.mapView.safeAreaInsets.right + spacing
        } else {
            topInset = 50.0
            bottomInset = 50.0
            leftInset = bottomBannerContainerView.frame.width + spacing
            rightInset = navigationMapView.mapView.safeAreaInsets.right + spacing
        }
        
        let padding = UIEdgeInsets(top: topInset,
                                   left: leftInset,
                                   bottom: bottomInset,
                                   right: rightInset)
        
        let pitch: CGFloat = 0.0
        let bearing: CGFloat = 0.0
        
        return CameraOptions(padding: padding, bearing: bearing, pitch: pitch)
    }
}
