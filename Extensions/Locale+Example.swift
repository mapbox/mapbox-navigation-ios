import Foundation

extension Locale {
    var currencySymbol: String? {
        guard let currencyCode = currencyCode else { return nil }
        let locale = NSLocale(localeIdentifier: currencyCode)
        if locale.displayName(forKey: .currencySymbol, value: currencyCode) == currencyCode {
            let newlocale = NSLocale(localeIdentifier: currencyCode.dropLast() + "_en")
            return newlocale.displayName(forKey: .currencySymbol, value: currencyCode)
        }
        return locale.displayName(forKey: .currencySymbol, value: currencyCode)
    }
}
