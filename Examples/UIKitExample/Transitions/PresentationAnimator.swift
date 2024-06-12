import MapboxNavigationCore
import MapboxNavigationUIKit
import UIKit

class PresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.0
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromViewController = transitionContext.viewController(forKey: .from) as? PreviewViewController,
              let toViewController = transitionContext.viewController(forKey: .to) as? NavigationViewController
        else {
            transitionContext.completeTransition(false)
            return
        }

        if let dataSource = fromViewController.navigationMapView.navigationCamera
            .viewportDataSource as? MobileViewportDataSource
        {
            dataSource.options.followingCameraOptions = FollowingCameraOptions()
        }
        // Replace default `NavigationMapView` in `NavigationViewController` with `NavigationMapView`
        // that was used in `PreviewViewController`.
        toViewController.navigationMapView = fromViewController.navigationMapView

        transitionContext.containerView.addSubview(toViewController.view)
        transitionContext.completeTransition(true)
    }
}
