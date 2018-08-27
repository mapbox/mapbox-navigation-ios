import Foundation
#if canImport(CarPlay)
import CarPlay
#endif
import MapboxGeocoder


class CarPlayGeocoder: Geocoder {
    
    @available(iOS 12.0, *)
    static func searchTemplate(_ searchTemplate: CPSearchTemplate, updatedSearchText searchText: String, completionHandler: @escaping ([CPListItem]) -> Void) {
        
        var items = favorites(searchText)
        let shouldSearch = searchText.count > 2
        
        if shouldSearch {
            
            let options = ForwardGeocodeOptions(query: searchText)
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
    static func favorites(_ searchText: String) -> [CPListItem] {
        let allFavorites = CPFavoritesList.POI.all
        let filteredFavorites = searchText.isEmpty
            ? allFavorites.map { $0.listItem() }
            : allFavorites.filter { $0.rawValue.contains(searchText) || $0.subTitle.contains(searchText) }.map { $0.listItem() }
        
        return filteredFavorites
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
