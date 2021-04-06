import CarPlay
import CoreLocation

public enum FavoritesList {
    enum POI: RawRepresentable {
        typealias RawValue = String
        case mapboxSF, timesSquare
        static let all: [POI] = [.mapboxSF, .timesSquare]
        
        var subTitle: String {
            switch self {
            case .mapboxSF:
                return "Office Location"
            case .timesSquare:
                return "Downtown Attractions"
            }
        }
        
        var location: CLLocation {
            switch self {
            case .mapboxSF:
                return CLLocation(latitude: 37.788443, longitude: -122.4020258)
            case .timesSquare:
                return CLLocation(latitude: 40.758899, longitude: -73.9873197)
            }
        }
        
        var rawValue: String {
            switch self {
            case .mapboxSF:
                return "Mapbox SF"
            case .timesSquare:
                return "Times Square"
            }
        }
        
        init?(rawValue: String) {
            let value = rawValue.lowercased()
            switch value {
            case "mapbox sf":
                self = .mapboxSF
            case "times square":
                self = .timesSquare
            default:
                return nil
            }
        }
        
        @available(iOS 12.0, *)
        func listItem() -> CPListItem {
            return CPListItem(text: rawValue, detailText: subTitle, image: nil, showsDisclosureIndicator: true)
        }
    }
}
