@_spi(Experimental) import MapboxNavigation
import UIKit

extension SceneDelegate: NavigationViewControllerDelegate {
    
    public func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController,
                                                   byCanceling canceled: Bool) {
        // Hide top and bottom banner containers.
        navigationViewController.navigationView.topBannerContainerView.hide()
        navigationViewController.navigationView.bottomBannerContainerView.hide(completion: { _ in
            navigationViewController.dismiss(animated: true)
        })
    }
}
