import XCTest
import TestHelper
@testable import MapboxNavigationNative
@testable import MapboxCoreNavigation

final class NavigationStatusTests: TestCase {
    var roadNonLocalizedAndShield: MapboxNavigationNative.RoadName!
    var roadNonLocalized: MapboxNavigationNative.RoadName!
    var roadDelimeter: MapboxNavigationNative.RoadName!
    var roadLocalizedRu: MapboxNavigationNative.RoadName!
    var roadLocalizedRu2: MapboxNavigationNative.RoadName!
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
        roadNonLocalizedAndShield = RoadName(text: "name",
                                             language: "",
                                             imageBaseUrl: "base_image_url",
                                             shield: shield)
        roadNonLocalized = RoadName(text: "name",
                                    language: "",
                                    imageBaseUrl: "base_image_url",
                                    shield: nil)
        roadDelimeter = RoadName(text: "/",
                                 language: "",
                                 imageBaseUrl: nil,
                                 shield: nil)
        roadLocalizedRu = RoadName(text: "ru name",
                                   language: "ru",
                                   imageBaseUrl: "ru_image_url",
                                   shield: nil)
        roadLocalizedRu2 = RoadName(text: "ru name 2",
                                    language: "ru",
                                    imageBaseUrl: "ru_image_url_2",
                                    shield: nil)
        roadLocalizedEn = RoadName(text: "en name",
                                   language: "en",
                                   imageBaseUrl: "en_image_url",
                                   shield: nil)
        roadLocalizedRuAndShield = RoadName(text: "ru name",
                                            language: "ru",
                                            imageBaseUrl: "ru_image_url_3",
                                            shield: shieldRu)
        roadLocalizedEnAndShield = RoadName(text: "en name",
                                            language: "en",
                                            imageBaseUrl: "en_image_url_3",
                                            shield: shieldEn)
    }

    func testReturnRoadName() {
        let status1 = status(with: [roadNonLocalized])
        XCTAssertEqual(status1.roadName, "name")

        let status2 = status(with: [roadNonLocalized, roadLocalizedRu])
        XCTAssertEqual(status2.roadName, "name ru name")

        let status3 = status(with: [roadNonLocalized, roadDelimeter, roadLocalizedRu])
        XCTAssertEqual(status3.roadName, "name")

        let status4 = status(with: [roadNonLocalized, roadLocalizedRu, roadDelimeter, roadLocalizedEn])
        XCTAssertEqual(status4.roadName, "name ru name")

        let status5 = status(with: [roadNonLocalizedAndShield])
        XCTAssertEqual(status5.roadName, "")

        let status6 = status(with: [roadNonLocalizedAndShield, roadDelimeter, roadLocalizedRu])
        XCTAssertEqual(status6.roadName, "ru name")

        let status7 = status(with: [roadNonLocalizedAndShield, roadDelimeter, roadLocalizedRuAndShield])
        XCTAssertEqual(status7.roadName, "", "Should be empty if all road names contain a shield")

        let status8 = status(with: [])
        XCTAssertEqual(status8.roadName, "")
    }

    func testReturnLocalizedRoadName() {
        let locale = Locale(identifier: "ru-RU")
        let status1 = status(with: [roadNonLocalized])
        XCTAssertEqual(status1.localizedRoadName(locale: locale), "name")

        let status2 = status(with: [roadNonLocalized, roadLocalizedRu, roadLocalizedEn])
        XCTAssertEqual(status2.localizedRoadName(locale: locale), "ru name")

        let status3 = status(with: [roadLocalizedRu, roadDelimeter, roadLocalizedEn])
        XCTAssertEqual(status3.localizedRoadName(locale: Locale(identifier: "en-US")), "en name")

        let status4 = status(with: [roadLocalizedRu, roadDelimeter, roadLocalizedEn])
        XCTAssertEqual(status4.localizedRoadName(locale: Locale(identifier: "it-CH")), status4.roadName)

        let status5 = status(with: [roadNonLocalizedAndShield])
        XCTAssertEqual(status5.localizedRoadName(locale: locale), "")

        let status6 = status(with: [roadLocalizedRuAndShield, roadDelimeter, roadLocalizedRu])
        XCTAssertEqual(status6.localizedRoadName(locale: locale), "ru name")
    }

    func testReturnLocalizedRouteShieldRepresentation() {
        let locale = Locale(identifier: "ru-RU")

        let status1 = status(with: [roadNonLocalized])
        let representation1 = status1.localizedRouteShieldRepresentation(locale: locale)
        XCTAssertNil(representation1.shield)
        XCTAssertEqual(representation1.imageBaseURL!.absoluteString, roadNonLocalized.imageBaseUrl)

        let status2 = status(with: [roadNonLocalizedAndShield])
        let representation2 = status2.localizedRouteShieldRepresentation(locale: locale)
        XCTAssertEqual(representation2.shield, shield.shieldRepresentation)
        XCTAssertEqual(representation2.imageBaseURL!.absoluteString, roadNonLocalizedAndShield.imageBaseUrl)

        let roads: [MapboxNavigationNative.RoadName] = [
            roadNonLocalizedAndShield,
            roadLocalizedRu,
            roadLocalizedRuAndShield,
            roadLocalizedEnAndShield
        ]
        let status3 = status(with: roads)
        let representation3 = status3.localizedRouteShieldRepresentation(locale: locale)
        XCTAssertEqual(representation3.shield, shieldRu.shieldRepresentation)
        XCTAssertEqual(representation3.imageBaseURL!.absoluteString, roadLocalizedRu.imageBaseUrl)
    }

    func testReturnRouteShieldRepresentation() {
        let status1 = status(with: [roadNonLocalized])
        let representation1 = status1.routeShieldRepresentation
        XCTAssertNil(representation1.shield)
        XCTAssertEqual(representation1.imageBaseURL!.absoluteString, roadNonLocalized.imageBaseUrl)

        let status2 = status(with: [roadNonLocalizedAndShield])
        let representation2 = status2.routeShieldRepresentation
        XCTAssertEqual(representation2.shield, shield.shieldRepresentation)
        XCTAssertEqual(representation2.imageBaseURL!.absoluteString, roadNonLocalizedAndShield.imageBaseUrl)

        let status3 = status(with: [roadNonLocalizedAndShield, roadLocalizedRuAndShield, roadLocalizedEnAndShield])
        let representation3 = status3.routeShieldRepresentation
        XCTAssertEqual(representation3.shield, shield.shieldRepresentation)
        XCTAssertEqual(representation3.imageBaseURL!.absoluteString, roadNonLocalizedAndShield.imageBaseUrl)
    }

    func testReturnRouteShieldIfIncorrectUrls() {
        let shield1 = Shield(baseUrl: "", displayRef: "ref", name: "shield", textColor: "")
        let roadNilImageBaseUrl = RoadName(text: "name",
                                            language: "",
                                            imageBaseUrl: nil,
                                            shield: shield1)
        let status1 = status(with: [roadNilImageBaseUrl])
        let representation1 = status1.routeShieldRepresentation
        XCTAssertNil(representation1.shield)
        XCTAssertNil(representation1.imageBaseURL)

        if #available(iOS 17.0, *) {
            // These URLs are considered valid on iOS 17+
            // https://developer.apple.com/documentation/foundation/url/3126806-init
        } else {
            let shield2 = Shield(baseUrl: "|||", displayRef: "ref", name: "shield", textColor: "")
            let roadNonValidImageBaseUrlString = RoadName(text: "name",
                                                          language: "",
                                                          imageBaseUrl: "|||",
                                                          shield: shield2)
            let status2 = status(with: [roadNonValidImageBaseUrlString])
            let representation2 = status2.routeShieldRepresentation
            XCTAssertNil(representation2.shield)
            XCTAssertNil(representation2.imageBaseURL)
        }

        let shield3 = Shield(baseUrl: "", displayRef: "ref", name: "shield", textColor: "")
        let roadEmptyImageBaseUrlString = RoadName(text: "name",
                                                      language: "",
                                                      imageBaseUrl: "",
                                                      shield: shield3)
        let status3 = status(with: [roadEmptyImageBaseUrlString])
        let representation3 = status3.routeShieldRepresentation
        XCTAssertNil(representation3.shield)
        XCTAssertNil(representation3.imageBaseURL)
    }

    func status(with roads: [MapboxNavigationNative.RoadName]) -> NavigationStatus {
        TestNavigationStatusProvider.createNavigationStatus(roads: roads)
    }
}
