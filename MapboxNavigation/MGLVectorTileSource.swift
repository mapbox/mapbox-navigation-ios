import Foundation
import Mapbox

// https://www.mapbox.com/vector-tiles/mapbox-streets-v7/#overview
let mapboxStreetsLanguages = Set(["ar", "de", "en", "es", "fr", "pt", "ru", "zh", "zh-Hans"])

extension MGLVectorTileSource {
    var isMapboxStreets: Bool {
        guard let configurationURL = configurationURL else {
            return false
        }
        return configurationURL.scheme == "mapbox" && configurationURL.host!.components(separatedBy: ",").contains("mapbox.mapbox-streets-v7")
    }
    
    static var preferredMapboxStreetsLanguage: String? {
        let preferredLanguages = Bundle.preferredLocalizations(from: Array(mapboxStreetsLanguages), forPreferences: Locale.preferredLanguages)
        var mostSpecificLanguage: String?
        for language in preferredLanguages {
            if language.count > mostSpecificLanguage?.count ?? 0 {
                mostSpecificLanguage = language
            }
        }
        return mostSpecificLanguage
    }
}
