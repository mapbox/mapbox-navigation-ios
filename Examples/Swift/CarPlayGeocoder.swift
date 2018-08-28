import Foundation
#if canImport(CarPlay)
import CarPlay
#endif
import MapboxGeocoder


class CarPlayGeocoder: Geocoder {
    
    static let CarPlayGeocoderPlacemarkKey: String = "CPGecoderPlacemark"
    static var recentItems = RecentItem.loadDefaults()
    
    @available(iOS 12.0, *)
    static func searchTemplate(_ searchTemplate: CPSearchTemplate, updatedSearchText searchText: String, completionHandler: @escaping ([CPListItem]) -> Void) {
        
        // Append recent searches
        var items = recentSearches(searchText)
        
        // Search for placemarks using MapboxGeocoder.swift
        let shouldSearch = searchText.count > 2
        if shouldSearch {
            
            let options = ForwardGeocodeOptions(query: searchText)
            options.locale = .autoupdatingCurrent
            var allScopes: PlacemarkScope = .all
            allScopes.remove(.postalCode)
            options.allowedScopes = allScopes
            options.maximumResultCount = 10
            options.includesRoutableLocations = true
            Geocoder.shared.geocode(options, completionHandler: { (placemarks, attribution, error) in
                
                guard let placemarks = placemarks else {
                    completionHandler(CarPlayGeocoder.resultsOrNoResults(items))
                    return
                }
                
                let results = placemarks.map { $0.listItem() }
                items.append(contentsOf: results)
                completionHandler(CarPlayGeocoder.resultsOrNoResults(results))
            })
            
        } else {
            completionHandler(CarPlayGeocoder.resultsOrNoResults(items))
        }
    }
    
    @available(iOS 12.0, *)
    static func carPlayManager(_ searchTemplate: CPSearchTemplate, selectedResult item: CPListItem, completionHandler: @escaping () -> Void) {
        
        if let userInfo = item.userInfo as? [String: Any],
            let placemark = userInfo[CarPlayGeocoderPlacemarkKey] as? GeocodedPlacemark {
            
        } else {
            assertionFailure("Missing placemark")
        }
    }
    
    @available(iOS 12.0, *)
    static func recentSearches(_ searchText: String) -> [CPListItem] {
        if searchText.isEmpty {
            return recentItems.map { $0.listItem() }
        }
        
        return recentItems.filter { $0.matches(searchText) }.map { $0.listItem() }
    }
    
    @available(iOS 12.0, *)
    static func resultsOrNoResults(_ items: [CPListItem]) -> [CPListItem] {
        if items.count > 0 {
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
    
    #if canImport(CarPlay)
    @available(iOS 12.0, *)
    func listItem() -> CPListItem {
        let item = CPListItem(text: formattedName, detailText: address, image: nil, showsDisclosureIndicator: true)
        item.userInfo = [CarPlayGeocoder.CarPlayGeocoderPlacemarkKey: self]
        return item
    }
    #endif
}
