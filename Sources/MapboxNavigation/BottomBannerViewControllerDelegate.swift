/**
 `BottomBannerViewControllerDelegate` provides a method for reacting to the user tapping on the "cancel" button in the `BottomBannerViewController`.
 */
public protocol BottomBannerViewControllerDelegate: AnyObject {
    /**
     A method that is invoked when the user taps on the cancel button.
     - parameter sender: The button that originated the tap event.
     */
    func didTapCancel(_ sender: Any)
}
