import CarPlay
import Foundation
import MapboxDirections

extension CarPlaySearchController: CPSearchTemplateDelegate {
    public static let CarPlayGeocodedPlacemarkKey: String = "NavigationGeocodedPlacemark"

    static var MaximumInitialSearchResults: UInt = 5
    static var MaximumExtendedSearchResults: UInt = 10

    // MARK: CPSearchTemplateDelegate Implementation

    public func searchTemplateSearchButtonPressed(_ searchTemplate: CPSearchTemplate) {
        guard let recentSearchItems = delegate?.recentSearchItems,
              let extendedItems = delegate?.searchResults(
                  with: recentSearchItems,
                  limit: CarPlaySearchController.MaximumExtendedSearchResults
              )
        else { return }

        for listItem in extendedItems {
            listItem.handler = { [weak self] item, completion in
                guard let self,
                      let userInfo = item.userInfo as? CarPlayUserInfo,
                      let placemark =
                      userInfo[CarPlaySearchController.CarPlayGeocodedPlacemarkKey] as? NavigationGeocodedPlacemark
                else {
                    completion()
                    return
                }
                handleSelection(location: placemark.location, completionHandler: completion)
            }
        }

        let section = CPListSection(items: extendedItems)
        let template = CPListTemplate(title: delegate?.recentSearchText, sections: [section])
        delegate?.pushTemplate(template, animated: true)
    }

    public func searchTemplateButton(
        searchTemplate: CPSearchTemplate,
        interfaceController: CPInterfaceController,
        traitCollection: UITraitCollection
    ) -> CPBarButton {
        let configuration = UIImage.SymbolConfiguration(pointSize: 24)
        let image = UIImage(systemName: "magnifyingglass", withConfiguration: configuration) ?? UIImage()

        let searchTemplateButton = CPBarButton(image: image) { [weak self] _ in
            guard let self else { return }

            if let mapTemplate = interfaceController.topTemplate as? CPMapTemplate {
                delegate?.resetPanButtons(mapTemplate)
            }

            delegate?.pushTemplate(searchTemplate, animated: false)
        }

        return searchTemplateButton
    }

    public func searchTemplate(
        _ searchTemplate: CPSearchTemplate,
        updatedSearchText searchText: String,
        completionHandler: @escaping ([CPListItem]) -> Void
    ) {
        delegate?.searchTemplate(
            searchTemplate,
            updatedSearchText: searchText,
            completionHandler: completionHandler
        )
    }

    public func searchTemplate(
        _ searchTemplate: CPSearchTemplate,
        selectedResult item: CPListItem,
        completionHandler: @escaping () -> Void
    ) {
        delegate?.searchTemplate(
            searchTemplate,
            selectedResult: item,
            completionHandler: completionHandler
        )
    }
}

extension CarPlaySearchController {
    func handleSelection(
        location: CLLocation?,
        completionHandler: @escaping () -> Void
    ) {
        guard let location else {
            completionHandler()
            return
        }

        let destinationWaypoint = Waypoint(location: location)
        delegate?.popTemplate(animated: false)
        delegate?.previewRoutes(to: destinationWaypoint, completionHandler: completionHandler)
    }
}

// MARK: CPListTemplateDelegate Implementation

@available(*, deprecated, message: "CPListItem.handler is used instead")
extension CarPlaySearchController: CPListTemplateDelegate {
    @available(*, deprecated, message: "CPListItem.handler is used instead")
    public func listTemplate(
        _ listTemplate: CPListTemplate,
        didSelect item: CPListItem,
        completionHandler: @escaping () -> Void
    ) {
        let userInfo = item.userInfo as? CarPlayUserInfo
        let placemark = userInfo?[CarPlaySearchController.CarPlayGeocodedPlacemarkKey] as? NavigationGeocodedPlacemark

        handleSelection(location: placemark?.location, completionHandler: completionHandler)
    }
}
