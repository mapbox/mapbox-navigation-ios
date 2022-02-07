import Foundation
import CarPlay
import MapboxDirections

@available(iOS 12.0, *)
extension CarPlaySearchController: CPSearchTemplateDelegate {
    
    public static let CarPlayGeocodedPlacemarkKey: String = "NavigationGeocodedPlacemark"
    
    static var MaximumInitialSearchResults: UInt = 5
    static var MaximumExtendedSearchResults: UInt = 10
    
    // MARK: CPSearchTemplateDelegate Implementation
    
    public func searchTemplateSearchButtonPressed(_ searchTemplate: CPSearchTemplate) {
        guard let recentSearchItems = delegate?.recentSearchItems,
              let extendedItems = delegate?.searchResults(with: recentSearchItems,
                                                          limit: CarPlaySearchController.MaximumExtendedSearchResults) else { return }
        
        let section = CPListSection(items: extendedItems)
        let template = CPListTemplate(title: delegate?.recentSearchText, sections: [section])
        template.delegate = self
        delegate?.pushTemplate(template, animated: true)
    }

    public func searchTemplateButton(searchTemplate: CPSearchTemplate,
                                     interfaceController: CPInterfaceController,
                                     traitCollection: UITraitCollection) -> CPBarButton {
        let searchTemplateButton = CPBarButton(type: .image) { [weak self] button in
            guard let self = self else { return }
            
            if let mapTemplate = interfaceController.topTemplate as? CPMapTemplate {
                self.delegate?.resetPanButtons(mapTemplate)
            }
            
            self.delegate?.pushTemplate(searchTemplate, animated: false)
        }
        
        let bundle = Bundle.mapboxNavigation
        searchTemplateButton.image = UIImage(named: "carplay_search",
                                             in: bundle,
                                             compatibleWith: traitCollection)
        
        return searchTemplateButton
    }
    
    public func searchTemplate(_ searchTemplate: CPSearchTemplate,
                               updatedSearchText searchText: String,
                               completionHandler: @escaping ([CPListItem]) -> Void) {
        delegate?.searchTemplate(searchTemplate,
                                 updatedSearchText: searchText,
                                 completionHandler: completionHandler)
    }
    
    public func searchTemplate(_ searchTemplate: CPSearchTemplate,
                               selectedResult item: CPListItem,
                               completionHandler: @escaping () -> Void) {
        delegate?.searchTemplate(searchTemplate,
                                 selectedResult: item,
                                 completionHandler: completionHandler)
    }
}

@available(iOS 12.0, *)
extension CarPlaySearchController: CPListTemplateDelegate {
    
    // MARK: CPListTemplateDelegate Implementation
    
    public func listTemplate(_ listTemplate: CPListTemplate,
                             didSelect item: CPListItem,
                             completionHandler: @escaping () -> Void) {
        // Selected a search item from the extended list?
        guard let userInfo = item.userInfo as? CarPlayUserInfo,
              let placemark = userInfo[CarPlaySearchController.CarPlayGeocodedPlacemarkKey] as? NavigationGeocodedPlacemark,
              let location = placemark.location else {
                  return
              }
        
        let destinationWaypoint = Waypoint(location: location)
        delegate?.popTemplate(animated: false)
        delegate?.previewRoutes(to: destinationWaypoint, completionHandler: completionHandler)
    }
}
