import Foundation
import MapboxMaps


extension VectorSource {
    /// A dictionary associating known tile set identifiers with identifiers of source layers that contain road names.
    static let roadLabelLayerIdentifiersByTileSetIdentifier = [
        "mapbox.mapbox-streets-v8": "road",
        "mapbox.mapbox-streets-v7": "road_label",
    ]
    
    /**
     Method, which returns a boolean value indicating whether the tile source is a supported version of the Mapbox Streets source.
     */
    static func isMapboxStreets(_ identifiers: [String]) -> Bool {
        return identifiers.contains("mapbox.mapbox-streets-v8") || identifiers.contains("mapbox.mapbox-streets-v7")
    }
    
    /**
     An array of locales for which Mapbox Streets source v8 has a [dedicated name field](https://docs.mapbox.com/vector-tiles/reference/mapbox-streets-v8/#name-text--name_lang-code-text).
     */
    static let mapboxStreetsLocales = ["ar", "de", "en", "es", "fr", "it", "ja", "ko", "pt", "ru", "vi", "zh-Hans", "zh-Hant"].map(Locale.init(identifier:))
    
    /**
     Returns the BCP 47 language tag supported by Mapbox Streets source v8 that is most preferred according to the given preferences.
     */
    static func preferredMapboxStreetsLocalization(among preferences: [String]) -> String? {
        let preferredLocales = preferences.map(Locale.init(identifier:))
        let acceptsEnglish = preferredLocales.contains { $0.languageCode == "en" }
        var availableLocales = mapboxStreetsLocales
        if !acceptsEnglish {
            availableLocales.removeAll { $0.languageCode == "en" }
        }
        
        let mostSpecificLanguage = Bundle.preferredLocalizations(from: availableLocales.map { $0.identifier },
                                                                 forPreferences: preferences)
            .max { $0.count > $1.count }
        
        // `Bundle.preferredLocalizations(from:forPreferences:)` is just returning the first localization it could find.
        if let mostSpecificLanguage = mostSpecificLanguage, !preferredLocales.contains(where: { $0.languageCode == Locale(identifier: mostSpecificLanguage).languageCode }) {
            return nil
        }
        
        return mostSpecificLanguage
    }
    
    /**
     Returns the locale supported by Mapbox Streets source v8 that is most preferred for the given locale.
     
     - parameter locale: The locale to match. To use the system’s preferred language, if supported, specify `nil`. To use the local language, specify a locale with the identifier `mul`.
     */
    static func preferredMapboxStreetsLocale(for locale: Locale?) -> Locale? {
        guard locale?.languageCode != "mul" else {
            // FIXME: Unlocalization not yet implemented: https://github.com/mapbox/mapbox-maps-ios/issues/653
            return nil
        }
        
        let preferences: [String]
        if let locale = locale {
            preferences = [locale.identifier]
        } else {
            preferences = Locale.preferredLanguages
        }
        
        guard let preferredLocalization = VectorSource.preferredMapboxStreetsLocalization(among: preferences) else {
            return nil
        }
        return Locale(identifier: preferredLocalization)
    }
}
