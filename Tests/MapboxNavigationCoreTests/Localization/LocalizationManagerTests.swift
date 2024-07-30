import MapboxNavigationCore
import XCTest

final class LocalizationManagerTests: XCTestCase {
    override func tearDown() {
        LocalizationManager.customLocalizationBundle = nil

        super.tearDown()
    }

    func testlocalizedStringIfNoCustomBundle() {
        let nonExistentKey = "NON_EXISTENT_KEY"
        let localizedNonExistent = LocalizationManager.localizedString(
            nonExistentKey,
            defaultBundle: .mapboxNavigationUXCore,
            value: ""
        )
        XCTAssertEqual(localizedNonExistent, nonExistentKey)

        let localized = LocalizationManager.localizedString(
            "SAME_TIME",
            defaultBundle: .mapboxNavigationUXCore,
            value: "value"
        )
        XCTAssertEqual(localized, "Similar ETA")
    }

    func testlocalizedStringIfCustomBundle() {
        LocalizationManager.customLocalizationBundle = Bundle.module

        let nonExistentKey = "NON_EXISTENT_KEY"
        let localizedNonExistent = LocalizationManager.localizedString(
            nonExistentKey,
            defaultBundle: .mapboxNavigationUXCore,
            value: "default localization"
        )
        XCTAssertEqual(localizedNonExistent, "default localization")

        let localized = LocalizationManager.localizedString(
            "SAME_TIME",
            defaultBundle: .mapboxNavigationUXCore,
            value: "value"
        )
        XCTAssertEqual(localized, "Overwritten value in the custom bundle")
    }
}
