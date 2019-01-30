#if canImport(CarPlay) && canImport(MapboxGeocoder)
import Foundation
import CarPlay
import MapboxGeocoder
import MapboxDirections

@available(iOS 12.0, *)
extension CarPlaySearchController: CPSearchTemplateDelegate {
    
    static var recentItems = RecentItem.loadDefaults()
    public static let CarPlayGeocodedPlacemarkKey: String = "MBGecodedPlacemark"
    
    static var MaximumInitialSearchResults: UInt = 5
    static var MaximumExtendedSearchResults: UInt = 10
    /// A very coarse location manager used for focal location when searching
    fileprivate static let coarseLocationManager: CLLocationManager = {
        let coarseLocationManager = CLLocationManager()
        coarseLocationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        return coarseLocationManager
    }()
    
    public func searchTemplate(_ searchTemplate: CPSearchTemplate, updatedSearchText searchText: String, completionHandler: @escaping ([CPListItem]) -> Void) {
        
        recentSearchText = searchText
        
        // Append recent searches
        var items = recentSearches(searchText)
        
        // Search for placemarks using MapboxGeocoder.swift
        let shouldSearch = searchText.count > 2
        if shouldSearch {
            
            let options = CarPlaySearchController.forwardGeocodeOptions(searchText)
            Geocoder.shared.geocode(options, completionHandler: { [weak self] (placemarks, attribution, error) in
                guard let strongSelf = self else { return }
                guard let placemarks = placemarks else {
                    completionHandler(strongSelf.resultsOrNoResults(items, limit: CarPlaySearchController.MaximumInitialSearchResults))
                    return
                }
                
                let results = placemarks.map { $0.listItem() }
                items.append(contentsOf: results)
                completionHandler(strongSelf.resultsOrNoResults(results, limit: CarPlaySearchController.MaximumInitialSearchResults))
            })
            
        } else {
            completionHandler(resultsOrNoResults(items, limit: CarPlaySearchController.MaximumInitialSearchResults))
        }
    }
    
    public func searchTemplateSearchButtonPressed(_ searchTemplate: CPSearchTemplate) {
        guard let items = recentSearchItems else { return }
        let extendedItems = resultsOrNoResults(items, limit: CarPlaySearchController.MaximumExtendedSearchResults)
        
        let section = CPListSection(items: extendedItems)
        let template = CPListTemplate(title: recentSearchText, sections: [section])
        template.delegate = self
        delegate?.pushTemplate(template, animated: true)
    }
    
    public func searchTemplate(_ searchTemplate: CPSearchTemplate, selectedResult item: CPListItem, completionHandler: @escaping () -> Void) {
        guard let userInfo = item.userInfo as? [String: Any],
            let placemark = userInfo[CarPlaySearchController.CarPlayGeocodedPlacemarkKey] as? GeocodedPlacemark,
            let location = placemark.location else {
                completionHandler()
                return
        }
        
        CarPlaySearchController.recentItems.add(RecentItem(placemark))
        CarPlaySearchController.recentItems.save()
        
        let destinationWaypoint = Waypoint(location: location, heading: nil, name: placemark.formattedName)
        delegate?.previewRoutes(to: destinationWaypoint, completionHandler: completionHandler)
    }
    
    public func searchTemplateButton(searchTemplate: CPSearchTemplate, interfaceController: CPInterfaceController, traitCollection: UITraitCollection) -> CPBarButton {
        
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
        searchTemplateButton.image = UIImage(named: "carplay_search", in: bundle, compatibleWith: traitCollection)
        
        return searchTemplateButton
    }
    
    @available(iOS 12.0, *)
    static func forwardGeocodeOptions(_ searchText: String) -> ForwardGeocodeOptions {
        let options = ForwardGeocodeOptions(query: searchText)
        options.focalLocation = CarPlaySearchController.coarseLocationManager.location
        options.locale = Locale.autoupdatingCurrent.languageCode == "en" ? nil : .autoupdatingCurrent
        var allScopes: PlacemarkScope = .all
        allScopes.remove(.postalCode)
        options.allowedScopes = allScopes
        options.maximumResultCount = CarPlaySearchController.MaximumExtendedSearchResults
        options.includesRoutableLocations = true
        return options
    }
    
    @available(iOS 12.0, *)
    public func selectResult(item: CPListItem, completionHandler: @escaping () -> Void) {
        
        guard let userInfo = item.userInfo as? [String: Any],
            let placemark = userInfo[CarPlaySearchController.CarPlayGeocodedPlacemarkKey] as? GeocodedPlacemark,
            let location = placemark.routableLocations?.first ?? placemark.location else {
                completionHandler()
                return
        }
        
        CarPlaySearchController.recentItems.add(RecentItem(placemark))
        CarPlaySearchController.recentItems.save()
        
        let destinationWaypoint = Waypoint(location: location, heading: nil, name: placemark.formattedName)
        delegate?.previewRoutes(to: destinationWaypoint, completionHandler: completionHandler)
    }
    
    @available(iOS 12.0, *)
    func recentSearches(_ searchText: String) -> [CPListItem] {
        if searchText.isEmpty {
            return CarPlaySearchController.recentItems.map { $0.geocodedPlacemark.listItem() }
        }
        return CarPlaySearchController.recentItems.filter { $0.matches(searchText) }.map { $0.geocodedPlacemark.listItem() }
    }
    
    @available(iOS 12.0, *)
    func resultsOrNoResults(_ items: [CPListItem], limit: UInt? = nil) -> [CPListItem] {
        recentSearchItems = items
        
        if items.count > 0 {
            if let limit = limit {
                return Array<CPListItem>(items.prefix(Int(limit)))
            }
            
            return items
        } else {
            let title = NSLocalizedString("CARPLAY_SEARCH_NO_RESULTS", bundle: .mapboxNavigation, value: "No results", comment: "Message when search returned zero results in CarPlay")
            let noResult = CPListItem(text: title, detailText: nil, image: nil, showsDisclosureIndicator: false)
            return [noResult]
        }
    }
}

@available(iOS 12.0, *)
extension CarPlaySearchController: CPListTemplateDelegate {
    public func listTemplate(_ listTemplate: CPListTemplate, didSelect item: CPListItem, completionHandler: @escaping () -> Void) {
        // Selected a search item from the extended list?
        if let userInfo = item.userInfo as? [String: Any],
            let placemark = userInfo[CarPlaySearchController.CarPlayGeocodedPlacemarkKey] as? GeocodedPlacemark,
            let location = placemark.location {
            let destinationWaypoint = Waypoint(location: location)
            delegate?.popTemplate(animated: false)
            delegate?.previewRoutes(to: destinationWaypoint, completionHandler: completionHandler)
            return
        }
    }
}

extension GeocodedPlacemark {
    
    @available(iOS 12.0, *)
    func listItem() -> CPListItem {
        let item = CPListItem(text: formattedName, detailText: subtitle, image: nil, showsDisclosureIndicator: true)
        item.userInfo = [CarPlaySearchController.CarPlayGeocodedPlacemarkKey: self]
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
