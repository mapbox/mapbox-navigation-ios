#if canImport(CarPlay) && canImport(MapboxGeocoder)
import Foundation
import CarPlay
import MapboxGeocoder
import MapboxDirections

@available(iOS 12.0, *)
extension CarPlayManager: CPSearchTemplateDelegate {
    
    public static let CarPlayGeocodedPlacemarkKey: String = "CPGecodedPlacemark"
    static var recentItems = RecentItem.loadDefaults()
    
    static var MaximumInitialSearchResults: UInt = 5
    static var MaximumExtendedSearchResults: UInt = 10
    /// A very coarse location manager used for focal location when searching
    fileprivate static let coarseLocationManager: CLLocationManager = {
        let coarseLocationManager = CLLocationManager()
        coarseLocationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        return coarseLocationManager
    }()
    
    // MARK: CPSearchTemplateDelegate
    
    public func searchTemplate(_ searchTemplate: CPSearchTemplate, updatedSearchText searchText: String, completionHandler: @escaping ([CPListItem]) -> Void) {
        let notImplementedItem = CPListItem(text: "Search not implemented", detailText: nil)
        delegate?.carPlayManager?(self, searchTemplate: searchTemplate, updatedSearchText: searchText, completionHandler: completionHandler)
            ?? completionHandler([notImplementedItem])
    }
    
    public func searchTemplateSearchButtonPressed(_ searchTemplate: CPSearchTemplate) {
        guard let items = recentSearchItems else { return }
        let extendedItems = CarPlayManager.resultsOrNoResults(items, limit: CarPlayManager.MaximumExtendedSearchResults)
        
        let section = CPListSection(items: extendedItems)
        let template = CPListTemplate(title: CarPlayManager.shared.recentSearchText, sections: [section])
        
        interfaceController?.pushTemplate(template, animated: true)
    }
    
    public func searchTemplate(_ searchTemplate: CPSearchTemplate, selectedResult item: CPListItem, completionHandler: @escaping () -> Void) {
        delegate?.carPlayManager?(self, searchTemplate: searchTemplate, selectedResult: item, completionHandler: completionHandler)
    }
    
    func searchTemplateButton(searchTemplate: CPSearchTemplate, interfaceController: CPInterfaceController, traitCollection: UITraitCollection) -> CPBarButton {
        
        let searchTemplateButton = CPBarButton(type: .image) { [weak self] button in
            guard let strongSelf = self else {
                return
            }
            
            if let mapTemplate = interfaceController.topTemplate as? CPMapTemplate {
                strongSelf.resetPanButtons(mapTemplate)
            }
            
            interfaceController.pushTemplate(searchTemplate, animated: true)
        }
        
        let bundle = Bundle.mapboxNavigation
        searchTemplateButton.image = UIImage(named: "search-monocle", in: bundle, compatibleWith: traitCollection)
        
        return searchTemplateButton
    }
    
    @available(iOS 12.0, *)
    public static func searchTemplate(_ searchTemplate: CPSearchTemplate, updatedSearchText searchText: String, completionHandler: @escaping ([CPListItem]) -> Void) {
        CarPlayManager.shared.recentSearchText = searchText
        
        // Append recent searches
        var items = recentSearches(searchText)
        
        // Search for placemarks using MapboxGeocoder.swift
        let shouldSearch = searchText.count > 2
        if shouldSearch {
            
            let options = CarPlayManager.forwardGeocodeOptions(searchText)
            Geocoder.shared.geocode(options, completionHandler: { (placemarks, attribution, error) in
                guard let placemarks = placemarks else {
                    completionHandler(CarPlayManager.resultsOrNoResults(items, limit: MaximumInitialSearchResults))
                    return
                }
                
                let results = placemarks.map { $0.listItem() }
                items.append(contentsOf: results)
                completionHandler(CarPlayManager.resultsOrNoResults(results, limit: MaximumInitialSearchResults))
            })
            
        } else {
            completionHandler(CarPlayManager.resultsOrNoResults(items, limit: MaximumInitialSearchResults))
        }
    }
    
    @available(iOS 12.0, *)
    static func forwardGeocodeOptions(_ searchText: String) -> ForwardGeocodeOptions {
        let options = ForwardGeocodeOptions(query: searchText)
        options.locale = .autoupdatingCurrent
        var allScopes: PlacemarkScope = .all
        allScopes.remove(.postalCode)
        options.allowedScopes = allScopes
        options.maximumResultCount = CarPlayManager.MaximumExtendedSearchResults
        options.includesRoutableLocations = true
        return options
    }
    
    @available(iOS 12.0, *)
    public static func carPlayManager(_ searchTemplate: CPSearchTemplate, selectedResult item: CPListItem, completionHandler: @escaping () -> Void) {
        
        guard let userInfo = item.userInfo as? [String: Any],
            let placemark = userInfo[CarPlayGeocodedPlacemarkKey] as? GeocodedPlacemark,
            let location = placemark.location else {
                completionHandler()
                return
        }
        
        recentItems.add(RecentItem(placemark))
        recentItems.save()
        
        let destinationWaypoint = Waypoint(location: location, heading: nil, name: placemark.formattedName)
        CarPlayManager.shared.calculateRouteAndStart(to: destinationWaypoint, completionHandler: completionHandler)
    }
    
    @available(iOS 12.0, *)
    static func recentSearches(_ searchText: String) -> [CPListItem] {
        if searchText.isEmpty {
            return recentItems.map { $0.geocodedPlacemark.listItem() }
        }
        return recentItems.filter { $0.matches(searchText) }.map { $0.geocodedPlacemark.listItem() }
    }
    
    @available(iOS 12.0, *)
    static func resultsOrNoResults(_ items: [CPListItem], limit: UInt? = nil) -> [CPListItem] {
        CarPlayManager.shared.recentSearchItems = items
        
        if items.count > 0 {
            if let limit = limit {
                return Array<CPListItem>(items.prefix(Int(limit)))
            }
            
            return items
        } else {
            let noResult = CPListItem(text: "No results", detailText: nil, image: nil, showsDisclosureIndicator: false)
            return [noResult]
        }
    }
    
    @available(iOS 12.0, *)
    static func sortedByRelevance(_ items: [CPListItem]) -> [CPListItem] {
        // TODO: Sort by relevance https://github.com/mapbox/MapboxGeocoder.swift/issues/156
        return []
    }
}

extension GeocodedPlacemark {
    
    @available(iOS 12.0, *)
    func listItem() -> CPListItem {
        let item = CPListItem(text: formattedName, detailText: subtitle, image: nil, showsDisclosureIndicator: true)
        item.userInfo = [CarPlayManager.CarPlayGeocodedPlacemarkKey: self]
        return item
    }
    
    var subtitle: String? {
        if let addressDictionary = addressDictionary, var lines = addressDictionary["formattedAddressLines"] as? [String] {
            // Chinese addresses have no commas and are reversed.
            if scope == .address {
                if qualifiedName?.contains(", ") ?? false {
                    lines.removeFirst()
                } else {
                    lines.removeLast()
                }
            }
            
            if let regionCode = administrativeRegion?.code,
                let abbreviatedRegion = regionCode.components(separatedBy: "-").last, (abbreviatedRegion as NSString).intValue == 0 {
                // Cut off country and postal code and add abbreviated state/region code at the end.
                
                let stitle = lines.prefix(2).joined(separator: NSLocalizedString("ADDRESS_LINE_SEPARATOR", value: ", ", comment: "Delimiter between lines in an address when displayed inline"))
                
                if scope == .region || scope == .district || scope == .place || scope == .postalCode {
                    return stitle
                }
                return stitle.appending("\(NSLocalizedString("ADDRESS_LINE_SEPARATOR", value: ", ", comment: "Delimiter between lines in an address when displayed inline"))\(abbreviatedRegion)")
            }
            
            if scope == .country {
                return ""
            }
            if qualifiedName?.contains(", ") ?? false {
                return lines.joined(separator: NSLocalizedString("ADDRESS_LINE_SEPARATOR", value: ", ", comment: "Delimiter between lines in an address when displayed inline"))
            }
            return lines.joined()
        }
        
        return description
    }
}
#endif
