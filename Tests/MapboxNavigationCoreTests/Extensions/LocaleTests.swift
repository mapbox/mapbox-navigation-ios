@testable import MapboxNavigationCore
import XCTest

final class LocaleTests: XCTestCase {
    func testLanguageCountryCodeAddsRegionToLanguage() {
        XCTAssertEqual(Locale.languageCountryCode(localization: "en", regionCode: "US"), "en-US")
        XCTAssertEqual(Locale.languageCountryCode(localization: "en", regionCode: nil), "en")
    }

    func testLanguageCountryCodeKeepsHyphenatedLocalization() {
        XCTAssertEqual(Locale.languageCountryCode(localization: "pt-BR", regionCode: "US"), "pt-BR")
        XCTAssertEqual(Locale.languageCountryCode(localization: "zh-Hant", regionCode: "TW"), "zh-Hant")
        XCTAssertEqual(Locale.languageCountryCode(localization: "zh-Hant-TW", regionCode: "DE"), "zh-Hant-TW")
    }

    func testLanguageCountryCodeNormalizesUnderscores() {
        XCTAssertEqual(Locale.languageCountryCode(localization: "zh_Hant_TW", regionCode: "TW"), "zh-Hant-TW")
        XCTAssertEqual(Locale.languageCountryCode(localization: "zh_Hant_TW", regionCode: "DE"), "zh-Hant-TW")
        XCTAssertEqual(Locale.languageCountryCode(localization: "zh_Hant_HK", regionCode: "HK"), "zh-Hant-HK")
        XCTAssertEqual(Locale.languageCountryCode(localization: "cs_CZ", regionCode: "CZ"), "cs-CZ")
    }

    func testLanguageCountryCodeGivesStableLocaleIdentifier() {
        let code = Locale.languageCountryCode(localization: "zh_Hant_TW", regionCode: "DE")
        XCTAssertEqual(Locale(identifier: code).identifier, "zh-Hant-TW")
    }

    func testFallbackDistanceUnit() throws {
        XCTAssertEqual(Locale(identifier: "en-US").fallbackDistanceUnit, .mile)
        XCTAssertEqual(Locale(identifier: "en-US").fallbackDistanceUnit, .mile)
        XCTAssertEqual(Locale(identifier: "pl_PL").fallbackDistanceUnit, .kilometer)
    }

    @available(iOS 16.0, *)
    func testCalculatedDistanceUnitIOS16() throws {
        XCTAssertEqual(Locale(identifier: "en-US").calculatedDistanceUnit, .mile)
        XCTAssertEqual(Locale(identifier: "en-US").calculatedDistanceUnit, .mile)
        XCTAssertEqual(Locale(identifier: "pl_PL").calculatedDistanceUnit, .kilometer)
    }
}
