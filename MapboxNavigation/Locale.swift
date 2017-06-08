import Foundation

extension Locale {
    static var preferredLocalLanguageCountryCode: String {
        let firstBundleLocale = Bundle.main.preferredLocalizations.first!
        let bundleLocale = firstBundleLocale.components(separatedBy: "-")
        
        if bundleLocale.count > 1 {
            return firstBundleLocale
        }
        
        if let countryCode = (Locale.current as NSLocale).object(forKey: .countryCode) as? String {
            return "\(bundleLocale.first!)-\(countryCode)"
        }
        
        return firstBundleLocale
    }
    
    static var nationalizedCurrent = Locale(identifier: preferredLocalLanguageCountryCode)
}
