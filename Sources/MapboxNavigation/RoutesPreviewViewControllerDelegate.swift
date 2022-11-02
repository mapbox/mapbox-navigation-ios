/**
 The interface for an object that serves as the routes preview delegate.
 */
public protocol RoutesPreviewViewControllerDelegate: AnyObject {
    
    /**
     Tells the delegate that the user tapped on start active navigation button.
     
     - parameter: `RoutesPreviewViewController` instance where this action was initiated.
     */
    func didPressBeginActiveNavigationButton(_ routesPreviewViewController: RoutesPreviewViewController)
}
