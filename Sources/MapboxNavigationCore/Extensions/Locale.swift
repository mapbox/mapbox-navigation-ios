import Foundation

extension Locale {
    /// Given the app's localized language setting, returns a string representing the user's localization.
    public static var preferredLocalLanguageCountryCode: String {
        languageCountryCode(
            localization: Bundle.main.preferredLocalizations.first!,
            regionCode: (Locale.current as NSLocale).object(forKey: .countryCode) as? String
        )
    }

    /// Returns a BCP 47 language tag for `localization`. Adds `regionCode` if `localization` contains only a language.
    static func languageCountryCode(localization: String, regionCode: String?) -> String {
        // Localizations can use underscores (`zh_Hant_TW`), but Mapbox APIs accept only hyphens.
        let languageTag = localization.replacingOccurrences(of: "_", with: "-")

        if languageTag.contains("-") {
            return languageTag
        }

        if let regionCode {
            return "\(languageTag)-\(regionCode)"
        }

        return languageTag
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

    var calculatedDistanceUnit: LengthFormatter.Unit {
        if #available(iOS 16.0, *) {
            return switch measurementSystem {
            case .metric:
                .kilometer
            case .us:
                .mile
            case .uk:
                .yard
            default:
                .mile
            }
        }
        return fallbackDistanceUnit
    }

    var fallbackDistanceUnit: LengthFormatter.Unit {
        return if usesMetricSystem {
            .kilometer
        } else {
            switch regionCode {
            case "GB":
                .yard
            default:
                .mile
            }
        }
    }
}
