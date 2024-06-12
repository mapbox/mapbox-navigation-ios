import CarPlay
import MapboxDirections

/// Delegate, which is used to control behavior based on certain actions from the user when performing search on
/// CarPlay.
public protocol CarPlaySearchControllerDelegate: CPSearchTemplateDelegate {
    // MARK: Previewing the Route

    /// Method, which is called whenever user selects search result.
    /// - Parameters:
    ///   - waypoint: `Waypoint` instance, which contains information regarding destination.
    ///   - completionHandler: A block object to be executed when route preview finishes.
    func previewRoutes(to waypoint: Waypoint, completionHandler: @escaping () -> Void)

    // MARK: Templates Events

    /// Method, which is called whenever `CPSearchTemplate` is presented to give user the opportunity to change
    /// `CPMapTemplate.mapButtons`.
    /// - Parameters:
    /// - mapTemplate: `CPMapTemplate` object, on the trailing bottom corner of which an array of bar buttons will be
    /// displayed.
    func resetPanButtons(_ mapTemplate: CPMapTemplate)

    /// Method, which is called whenever `CPSearchTemplate` is presented.
    /// - Parameters:
    /// - template: `CPSearchTemplate` instance.
    /// - animated: Boolean flag which determines whether `CPSearchTemplate` presentation push will be animated or not.
    func pushTemplate(_ template: CPTemplate, animated: Bool)

    /// Method, which is called whenever user selects `CPListItem` with destination and `CPSearchTemplate` is being
    /// dismissed.
    /// - Parameters:
    /// -  animated: Boolean flag which determines whether `CPSearchTemplate` dismissal is animated or not.
    func popTemplate(animated: Bool)

    // MARK: Interacting with Search Results

    /// The most recent search results.
    var recentSearchItems: [CPListItem]? { get set }

    /// The most recent search text, which is going to be used as `CPListTemplate` title after performing search.
    var recentSearchText: String? { get set }

    /// Method, which offers the delegate an opportunity to react to updates in the search text.
    /// - Parameters:
    /// - searchTemplate: The search template currently accepting user input.
    /// - searchText: The updated search text in `searchTemplate`.
    /// - completionHandler: Called when the search is complete. Accepts a list of search results.
    /// - Postcondition: You must call `completionHandler` within this method.
    func searchTemplate(
        _ searchTemplate: CPSearchTemplate,
        updatedSearchText searchText: String,
        completionHandler: @escaping ([CPListItem]) -> Void
    )

    /// Method, which offers the delegate an opportunity to react to selection of a search result.
    /// - Parameters:
    /// -  searchTemplate: The search template currently accepting user input.
    /// - tem: The search result the user has selected.
    /// - completionHandler: Called when the delegate is done responding to the selection.
    /// - Postcondition: You must call `completionHandler` within this method.
    func searchTemplate(
        _ searchTemplate: CPSearchTemplate,
        selectedResult item: CPListItem,
        completionHandler: @escaping () -> Void
    )

    /// Method, which allows to provide list of `CPListItem`s and show them in `CPListTemplate` after performing search.
    /// - Parameters:
    /// -   items: List of `CPListItem`, which will be shown in `CPListTemplate`.
    /// - limit: Optional integer, which serves as a limiter for a list of search results.
    /// - Returns: List of `CPListItem` objects with certain limit (if applicable).
    func searchResults(with items: [CPListItem], limit: UInt?) -> [CPListItem]
}
