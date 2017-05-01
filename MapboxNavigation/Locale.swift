import Foundation

extension Locale {
    static var preferredLocalLanguageCountryCode: String {
        let bundleLanguage = Bundle.main.preferredLocalizations.first!
        let bundleLanguages = bundleLanguage.components(separatedBy: "-")
        
        if bundleLanguages.count == 2 {
            return bundleLanguage
        }
        
        let countryCode = NSLocale.Key.countryCode
        let locale = NSLocale.current as NSLocale
        let countryString = locale.object(forKey: countryCode) as! String
        return "\(bundleLanguages.first!)-\(countryString)"
    }
}
