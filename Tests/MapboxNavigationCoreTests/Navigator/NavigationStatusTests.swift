import _MapboxNavigationTestHelpers
@testable import MapboxNavigationCore
import MapboxNavigationNative
import XCTest

final class NavigationStatusTests: XCTestCase {
    var roadNonLocalizedAndShield: MapboxNavigationNative.RoadName!
    var roadNonLocalized: MapboxNavigationNative.RoadName!
    var roadLocalizedRu: MapboxNavigationNative.RoadName!
    var roadLocalizedEn: MapboxNavigationNative.RoadName!
    var roadLocalizedRuAndShield: MapboxNavigationNative.RoadName!
    var roadLocalizedEnAndShield: MapboxNavigationNative.RoadName!
    var shield: Shield!
    var shieldRu: Shield!
    var shieldEn: Shield!

    override func setUp() {
        super.setUp()

        shield = Shield(baseUrl: "shield_url", displayRef: "ref", name: "shield", textColor: "")
        shieldRu = Shield(baseUrl: "shield_url_ru", displayRef: "ref", name: "shield_ru", textColor: "")
        shieldEn = Shield(baseUrl: "shield_url_en", displayRef: "ref", name: "shield_en", textColor: "")
        roadNonLocalizedAndShield = RoadName(
            text: "name",
            language: "",
            imageBaseUrl: "base_image_url",
            shield: shield
        )
        roadNonLocalized = RoadName(
            text: "name",
            language: "",
            imageBaseUrl: "base_image_url",
            shield: nil
        )
        roadLocalizedRu = RoadName(
            text: "ru name",
            language: "ru",
            imageBaseUrl: "ru_image_url",
            shield: nil
        )
        roadLocalizedEn = RoadName(
            text: "en name",
            language: "en",
            imageBaseUrl: "en_image_url",
            shield: nil
        )
        roadLocalizedRuAndShield = RoadName(
            text: "ru name",
            language: "ru",
            imageBaseUrl: "ru_image_url_3",
            shield: shieldRu
        )
        roadLocalizedEnAndShield = RoadName(
            text: "en name",
            language: "en",
            imageBaseUrl: "en_image_url_3",
            shield: shieldEn
        )
    }

    func testReturnLocalizedRoadName() {
        let locale = Locale(identifier: "ru-RU")
        let status1 = NavigationStatus.mock(roads: [roadNonLocalized])
        XCTAssertEqual(status1.localizedRoadName(locale: locale), .init(text: "name", language: ""))

        let status2 = NavigationStatus.mock(roads: [roadNonLocalized, roadLocalizedRu, roadLocalizedEn])
        XCTAssertEqual(status2.localizedRoadName(locale: locale), .init(text: "ru name", language: "ru"))

        let status3 = NavigationStatus.mock(roads: [roadLocalizedRu, roadLocalizedEn])
        XCTAssertEqual(
            status3.localizedRoadName(locale: Locale(identifier: "en-US")),
            .init(text: "en name", language: "en")
        )

        let status4 = NavigationStatus.mock(roads: [roadLocalizedRu, roadLocalizedEn])
        let localizedRoadName4 = status4.localizedRoadName(locale: Locale(identifier: "it-CH"))
        XCTAssertEqual(localizedRoadName4, .init(text: "ru name / en name", language: ""))

        let status5 = NavigationStatus.mock(roads: [roadNonLocalizedAndShield])
        let localizedRoadName5 = status5.localizedRoadName(locale: locale)
        let expectedRoadName5 = RoadName(text: "", language: "", shield: RoadShield(shield))
        XCTAssertEqual(localizedRoadName5, expectedRoadName5)

        let status6 = NavigationStatus.mock(roads: [
            roadLocalizedEnAndShield,
            roadLocalizedRuAndShield,
            roadLocalizedRu,
        ])
        let localizedRoadName6 = status6.localizedRoadName(locale: locale)
        let expectedRoadName6 = RoadName(text: "ru name", language: "ru", shield: RoadShield(shieldRu))
        XCTAssertEqual(localizedRoadName6, expectedRoadName6)

        let status7 = NavigationStatus.mock(roads: [roadLocalizedEn, roadLocalizedRuAndShield, roadLocalizedRu])
        let localizedRoadName7 = status7.localizedRoadName(locale: locale)
        let expectedRoadName7 = RoadName(text: "ru name", language: "ru", shield: RoadShield(shieldRu))
        XCTAssertEqual(localizedRoadName7, expectedRoadName7)
    }
}
