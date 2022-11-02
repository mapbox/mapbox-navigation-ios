/**
 The interface for an object that serves as the banner dismissal delegate.
 */
public protocol BannerDismissalViewControllerDelegate: AnyObject {
    
    /**
     Tells the delegate that the user tapped on dismiss button.
     
     - parameter: `BannerDismissalViewController` instance where this action was initiated.
     */
    func didTapDismissBannerButton(_ bannerDismissalViewController: BannerDismissalViewController)
}
