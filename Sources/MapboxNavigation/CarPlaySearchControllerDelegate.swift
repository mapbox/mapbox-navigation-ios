import CarPlay
import MapboxDirections

/**
 Delegate, which is used to control behavior based on certain actions from the user when performing search on CarPlay.
 */
@available(iOS 12.0, *)
public protocol CarPlaySearchControllerDelegate: AnyObject {
    
    /**
     Method, which is called whenever user selects search result.
     
     - parameter waypoint: `Waypoint` instance, which contains information regarding destination.
     - parameter completionHandler: A block object to be executed when route preview finishes.
     */
    func previewRoutes(to waypoint: Waypoint, completionHandler: @escaping () -> Void)
    
    /**
     Method, which is called whenever `CPSearchTemplate` is presented to give user the
     opportunity to change `CPMapTemplate.mapButtons`.
     
     - parameter mapTemplate: `CPMapTemplate` object, on the trailing bottom corner of which
     an array of bar buttons will be displayed.
     */
    func resetPanButtons(_ mapTemplate: CPMapTemplate)
    
    /**
     Method, which is called whenever `CPSearchTemplate` is presented.
     
     - parameter template: `CPSearchTemplate` instance.
     - parameter animated: Boolean flag which determines whether `CPSearchTemplate` presentation push
     will be animated or not.
     */
    func pushTemplate(_ template: CPTemplate, animated: Bool)
    
    /**
     Method, which is called whenever user selects `CPListItem` with destination and
     `CPSearchTemplate` is being dismissed.
     
     - parameter animated: Boolean flag which determines whether `CPSearchTemplate` dismissal is
     animated or not.
     */
    func popTemplate(animated: Bool)
}
