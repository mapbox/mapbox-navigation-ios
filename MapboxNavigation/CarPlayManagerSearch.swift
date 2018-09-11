#if canImport(CarPlay) && canImport(MapboxGeocoder)
import Foundation
import CarPlay
import MapboxGeocoder
import MapboxDirections

@available(iOS 12.0, *)
extension CarPlayManager {
    
    public static let CarPlayGeocodedPlacemarkKey: String = "CPGecodedPlacemark"
    static var recentItems = RecentItem.loadDefaults()
    
    @available(iOS 12.0, *)
    public static func searchTemplate(_ searchTemplate: CPSearchTemplate, updatedSearchText searchText: String, completionHandler: @escaping ([CPListItem]) -> Void) {
        
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
                    completionHandler(CarPlayManager.resultsOrNoResults(items))
                    return
                }
                
                let results = placemarks.map { $0.listItem() }
                items.append(contentsOf: results)
                completionHandler(CarPlayManager.resultsOrNoResults(results))
            })
            
        } else {
            completionHandler(CarPlayManager.resultsOrNoResults(items))
        }
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
