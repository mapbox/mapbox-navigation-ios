import CarPlay
import MapboxDirections

/**
 Delegate, which is used to control behavior based on certain actions from the user when performing search on CarPlay.
 */
@available(iOS 12.0, *)
public protocol CarPlaySearchControllerDelegate: CPSearchTemplateDelegate {
    
    // MARK: Previewing the Route
    
    /**
     Method, which is called whenever user selects search result.
     
     - parameter waypoint: `Waypoint` instance, which contains information regarding destination.
     - parameter completionHandler: A block object to be executed when route preview finishes.
     */
    func previewRoutes(to waypoint: Waypoint, completionHandler: @escaping () -> Void)
    
    // MARK: Templates Events
    
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
    
    // MARK: Interacting with Search Results
    
    /**
     The most recent search results.
     */
    var recentSearchItems: [CPListItem]? { get set }
    
    /**
     The most recent search text, which is going to be used as `CPListTemplate` title after
     performing search.
     */
    var recentSearchText: String? { get set }
    
    /**
     Method, which offers the delegate an opportunity to react to updates in the search text.
     
     - parameter searchTemplate: The search template currently accepting user input.
     - parameter searchText: The updated search text in `searchTemplate`.
     - parameter completionHandler: Called when the search is complete. Accepts a list of search results.
     
     - postcondition: You must call `completionHandler` within this method.
     */
    func searchTemplate(_ searchTemplate: CPSearchTemplate,
                        updatedSearchText searchText: String,
                        completionHandler: @escaping ([CPListItem]) -> Void)
    
    /**
     Method, which offers the delegate an opportunity to react to selection of a search result.
     
     - parameter searchTemplate: The search template currently accepting user input.
     - parameter item: The search result the user has selected.
     - parameter completionHandler: Called when the delegate is done responding to the selection.
     
     - postcondition: You must call `completionHandler` within this method.
     */
    func searchTemplate(_ searchTemplate: CPSearchTemplate,
                        selectedResult item: CPListItem,
                        completionHandler: @escaping () -> Void)
    
    /**
     Method, which allows to provide list of `CPListItem`s and show them in `CPListTemplate` after
     performing search.
     
     - parameter items: List of `CPListItem`, which will be shown in `CPListTemplate`.
     - parameter limit: Optional integer, which serves as a limiter for a list of search results.
     - returns: List of `CPListItem` objects with certain limit (if applicable).
     */
    func searchResults(with items: [CPListItem], limit: UInt?) -> [CPListItem]
}
