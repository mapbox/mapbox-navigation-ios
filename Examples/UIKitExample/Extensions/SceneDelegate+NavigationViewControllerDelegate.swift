import MapboxNavigationUIKit
import UIKit

extension SceneDelegate: NavigationViewControllerDelegate {
    public func navigationViewControllerDidDismiss(
        _ navigationViewController: NavigationViewController,
        byCanceling canceled: Bool
    ) {
        // Hide top and bottom banner containers and after that dismiss `NavigationViewController`.
        navigationViewController.navigationView.topBannerContainerView.hide(
            animated: shouldAnimate,
            duration: animationDuration,
            animations: {
                navigationViewController.navigationView.topBannerContainerView.alpha = 0.0
            }
        )

        navigationViewController.navigationView.bottomBannerContainerView.hide(
            animated: shouldAnimate,
            duration: animationDuration,
            animations: {
                navigationViewController.navigationView.bottomBannerContainerView.alpha = 0.0
                navigationViewController.navigationView.speedLimitView.alpha = 0.0
                navigationViewController.navigationView.wayNameView.alpha = 0.0
                navigationViewController.navigationView.floatingStackView.alpha = 0.0
            },
            completion: { _ in
                navigationViewController.dismiss(animated: true) { [weak self] in
                    guard let self else { return }

                    let navigationView = previewViewController.navigationView
                    let navigationMapView = navigationView.navigationMapView

                    navigationMapView.delegate = self

                    navigationMapView.removeRoutes()

                    guard let initialRoutes else { return }

                    showcase(
                        navigationRoutes: initialRoutes,
                        animated: shouldAnimate,
                        duration: animationDuration
                    )

                    navigationView.topBannerContainerView.show(
                        animated: shouldAnimate,
                        duration: animationDuration,
                        animations: {
                            navigationView.topBannerContainerView.alpha = 1.0
                        }
                    )

                    navigationView.bottomBannerContainerView.show(
                        animated: shouldAnimate,
                        duration: animationDuration,
                        animations: {
                            navigationView.floatingStackView.alpha = 1.0
                            navigationView.bottomBannerContainerView.alpha = 1.0
                        }
                    )
                }
            }
        )
    }
}
