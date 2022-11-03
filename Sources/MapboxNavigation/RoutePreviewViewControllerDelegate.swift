/**
 The interface for an object that serves as the routes preview delegate.
 */
public protocol RoutePreviewViewControllerDelegate: AnyObject {
    
    /**
     Tells the delegate that the user tapped on start active navigation button.
     
     - parameter: `RoutePreviewViewController` instance where this action was initiated.
     */
    func didPressBeginActiveNavigationButton(_ routePreviewViewController: RoutePreviewViewController)
}
