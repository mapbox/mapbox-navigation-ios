import Foundation


extension Locale {
    
    // Returns Locale.autoupdatingCurrent unless its languageCode is equal to `en`, then nil will be returned.
    static var autoupdatingNonEnglish: Locale? {
        if let languageCode = Locale.autoupdatingCurrent.languageCode,
            languageCode == "en" {
            return nil
        }
        
        return .autoupdatingCurrent
    }
}
