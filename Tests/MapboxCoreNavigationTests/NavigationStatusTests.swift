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


    override func setUp() {
        super.setUp()

        let shield = Shield(baseUrl: "shield_url", displayRef: "ref", name: "shield", textColor: "")
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
                                   imageBaseUrl: nil,
                                   shield: nil)
        roadLocalizedRu2 = RoadName(text: "ru name 2",
                                    language: "ru",
                                    imageBaseUrl: nil,
                                    shield: nil)
        roadLocalizedEn = RoadName(text: "en name",
                                   language: "en",
                                   imageBaseUrl: nil,
                                   shield: nil)
    }

    func testReturnRoadName() {
        let status1 = status(with: [roadNonLocalizedAndShield])
        XCTAssertEqual(status1.roadName, "name")

        let status2 = status(with: [roadNonLocalizedAndShield, roadLocalizedRu])
        XCTAssertEqual(status2.roadName, "name ru name")

        let status3 = status(with: [roadNonLocalizedAndShield, roadDelimeter, roadLocalizedRu])
        XCTAssertEqual(status3.roadName, "name")

        let status4 = status(with: [roadNonLocalizedAndShield, roadLocalizedRu, roadDelimeter, roadLocalizedEn])
        XCTAssertEqual(status4.roadName, "name ru name")

        let status5 = status(with: [roadNonLocalized])
        XCTAssertEqual(status5.roadName, "name")
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
    }

    func status(with roads: [MapboxNavigationNative.RoadName]) -> NavigationStatus {
        TestNavigationStatusProvider.createNavigationStatus(roads: roads)
    }
}
