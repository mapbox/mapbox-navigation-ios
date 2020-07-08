@testable import MapboxCoreNavigation
import XCTest

class SkuTokenProviderTests: XCTestCase {
    func testGetTokenMethodReturnsNonEmptySkuToken() {
        // Given
        let tokenProvider = SkuTokenProvider()
        
        // When
        let skuToken = tokenProvider.getToken()
        
        // Then
        XCTAssertFalse(skuToken.isEmpty)
    }
}
