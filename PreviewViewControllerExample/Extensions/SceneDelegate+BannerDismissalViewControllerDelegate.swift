import MapboxNavigation

// MARK: - BannerDismissalViewControllerDelegate methods

extension SceneDelegate: BannerDismissalViewControllerDelegate {
    
    func didTapDismissBannerButton(_ bannerDismissalViewController: BannerDismissalViewController) {
        previewViewController.dismissBanner(at: .bottomLeading,
                                            animated: shouldAnimate,
                                            duration: animationDuration)
        
        // In case if there are no more bottom banners - dismiss top banner as well.
        if previewViewController.topBanner(at: .bottomLeading) == nil {
            previewViewController.dismissBanner(at: .topLeading,
                                                animated: shouldAnimate,
                                                duration: animationDuration,
                                                animations: {
                self.previewViewController.navigationView.topBannerContainerView.alpha = 0.0
            }, completion: {
                self.previewViewController.navigationView.topBannerContainerView.alpha = 1.0
            })
        }
    }
}
