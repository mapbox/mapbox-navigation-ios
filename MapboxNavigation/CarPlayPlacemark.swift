import Foundation
import MapboxGeocoder
#if canImport(CarPlay)
import CarPlay
#endif

extension GeocodedPlacemark {
    
    #if canImport(CarPlay)
    @available(iOS 12.0, *)
    func listItem() -> CPListItem {
        return CPListItem(text: formattedName, detailText: address, image: nil, showsDisclosureIndicator: true)
    }
    #endif
}
