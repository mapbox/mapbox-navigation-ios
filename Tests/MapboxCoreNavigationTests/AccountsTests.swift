import XCTest
import TestHelper
@testable import MapboxCoreNavigation

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
}
