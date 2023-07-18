import XCTest
import TestHelper
@testable import MapboxCoreNavigation
@_implementationOnly import MapboxCommon_Private

final class AccountsTests: TestCase {
    func testServiceSkuToken() {
        XCTAssertNil(Accounts.serviceSkuToken)

        billingServiceMock.onGetSessionStatus = { _ in .running }

        let token = "token"
        billingServiceMock.onGetSKUTokenIfValid = { _ in token }
        XCTAssertEqual(Accounts.serviceSkuToken, token)

        billingServiceMock.onGetSKUTokenIfValid = { _ in "" }
        XCTAssertNil(Accounts.serviceSkuToken)
    }

    func testServiceAccessToken() {
        XCTAssertEqual(Accounts.serviceAccessToken, BillingHandler.shared.serviceAccessToken)
    }

    func testSdkRegistry() throws {
        let sdkInfos = SdkInfoRegistryFactory.getInstance()
            .getSdkInformation()
            .filter { $0.packageName == "com.mapbox.navigation"}
        guard !sdkInfos.isEmpty else {
            XCTFail("Navigation SDK not added to registry"); return
        }

        let coreSdkInfo = try XCTUnwrap(sdkInfos.first(where: { $0.name == "mapbox-navigation-ios"}))
        XCTAssertEqual(coreSdkInfo.name, "mapbox-navigation-ios")
        XCTAssertEqual(coreSdkInfo.version, Bundle.navigationSDKVersion)

        if let uiSdkInfo = sdkInfos.first(where: { $0.name == "mapbox-navigation-ui-ios" }) {
            XCTAssertEqual(uiSdkInfo.version, Bundle.navigationSDKVersion)
        }
    }
}
