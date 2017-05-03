import Foundation

extension Locale {
    static var preferredLocalLanguageCountryCode: String {
        let firstBundleLocale = Bundle.main.preferredLocalizations.first!
        let bundleLocale = firstBundleLocale.components(separatedBy: "-")
        
        if bundleLocale.count > 1 {
            return firstBundleLocale
        }
        
        let countryString = (NSLocale.current as NSLocale).object(forKey: .countryCode) as! String
        return "\(bundleLocale.first!)-\(countryString)"
    }
    
    static var nationalizedCurrent = Locale(identifier: preferredLocalLanguageCountryCode)
}
