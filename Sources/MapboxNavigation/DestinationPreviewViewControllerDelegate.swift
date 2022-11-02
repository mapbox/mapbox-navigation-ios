/**
 The interface for an object that serves as the destination preview delegate.
 */
public protocol DestinationPreviewViewControllerDelegate: AnyObject {
    
    /**
     Tells the delegate that the user tapped on preview routes button.
     
     - parameter: `DestinationPreviewViewController` instance where this action was initiated.
     */
    func didTapPreviewRoutesButton(_ destinationPreviewViewController: DestinationPreviewViewController)
    
    /**
     Tells the delegate that the user tapped on begin active navigation button.
     
     - parameter: `DestinationPreviewViewController` instance where this action was initiated.
     */
    func didTapBeginActiveNavigationButton(_ destinationPreviewViewController: DestinationPreviewViewController)
}
