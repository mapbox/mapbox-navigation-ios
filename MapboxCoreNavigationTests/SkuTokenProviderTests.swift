@testable import MapboxCoreNavigation
import MapboxDirections
import XCTest

class SkuTokenProviderTests: XCTestCase {
    func testGetTokenMethodReturnsNonEmptySkuToken() {
        // Given
        let tokenProvider = SkuTokenProvider(with: DirectionsCredentials())
        
        // When
        let skuToken = tokenProvider.getToken()
        
        // Then
        XCTAssertFalse(skuToken.isEmpty)
    }
}
