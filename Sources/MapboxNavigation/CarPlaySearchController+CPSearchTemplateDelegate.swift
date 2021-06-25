import Foundation
import CarPlay
import MapboxDirections

@available(iOS 12.0, *)
extension CarPlaySearchController: CPSearchTemplateDelegate {
    
    public func searchTemplate(_ searchTemplate: CPSearchTemplate, updatedSearchText searchText: String, completionHandler: @escaping ([CPListItem]) -> Void) {
        delegate?.searchTemplate(searchTemplate, updatedSearchText: searchText, completionHandler: completionHandler)
    }
    
    public func searchTemplate(_ searchTemplate: CPSearchTemplate, selectedResult item: CPListItem, completionHandler: @escaping () -> Void) {
        delegate?.searchTemplate(searchTemplate, selectedResult: item, completionHandler: completionHandler)
    }
    
    public static let CarPlayGeocodedPlacemarkKey: String = "MBGecodedPlacemark"
    
    static var MaximumInitialSearchResults: UInt = 5
    static var MaximumExtendedSearchResults: UInt = 10
    
    public func searchTemplateSearchButtonPressed(_ searchTemplate: CPSearchTemplate) {
        guard let items = delegate?.recentSearchItems else { return }
        guard let extendedItems = delegate?.resultsOrNoResults(with: items, limit: CarPlaySearchController.MaximumExtendedSearchResults) else { return }
        
        let section = CPListSection(items: extendedItems)
        let template = CPListTemplate(title: delegate?.recentSearchText, sections: [section])
        template.delegate = self
        delegate?.pushTemplate(template, animated: true)
    }

    public func searchTemplateButton(searchTemplate: CPSearchTemplate,
                                     interfaceController: CPInterfaceController,
                                     traitCollection: UITraitCollection) -> CPBarButton {
        let searchTemplateButton = CPBarButton(type: .image) { [weak self] button in
            guard let strongSelf = self else {
                return
            }
            
            if let mapTemplate = interfaceController.topTemplate as? CPMapTemplate {
                strongSelf.delegate?.resetPanButtons(mapTemplate)
            }
            
            self?.delegate?.pushTemplate(searchTemplate, animated: false)
        }
        
        let bundle = Bundle.mapboxNavigation
        searchTemplateButton.image = UIImage(named: "carplay_search",
                                             in: bundle,
                                             compatibleWith: traitCollection)
        
        return searchTemplateButton
    }
}

@available(iOS 12.0, *)
extension CarPlaySearchController: CPListTemplateDelegate {
    
    public func listTemplate(_ listTemplate: CPListTemplate,
                             didSelect item: CPListItem,
                             completionHandler: @escaping () -> Void) {
        // Selected a search item from the extended list?
        if let userInfo = item.userInfo as? [String: Any],
           let placemark = userInfo[CarPlaySearchController.CarPlayGeocodedPlacemarkKey] as? NavigationGeocodedPlacemark,
           let location = placemark.location {
            let destinationWaypoint = Waypoint(location: location)
            delegate?.popTemplate(animated: false)
            delegate?.previewRoutes(to: destinationWaypoint, completionHandler: completionHandler)
            return
        }
    }
}
