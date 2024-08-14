import Foundation

extension Locale {
    /// Given the app's localized language setting, returns a string representing the user's localization.
    public static var preferredLocalLanguageCountryCode: String {
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

    /// Returns a `Locale` from ``Foundation/Locale/preferredLocalLanguageCountryCode``.
    public static var nationalizedCurrent: Locale {
        Locale(identifier: preferredLocalLanguageCountryCode)
    }

    var BCP47Code: String {
        if #available(iOS 16, *) {
            language.maximalIdentifier
        } else {
            languageCode ?? identifier
        }
    }

    var preferredBCP47Codes: [String] {
        let currentCode = BCP47Code
        var codes = [currentCode]
        for code in Self.preferredLanguages {
            let newCode: String = if #available(iOS 16, *) {
                Locale(languageCode: Locale.LanguageCode(stringLiteral: code)).BCP47Code
            } else {
                Locale(identifier: code).BCP47Code
            }
            guard newCode != currentCode else { continue }
            codes.append(newCode)
        }
        return codes
    }
}
