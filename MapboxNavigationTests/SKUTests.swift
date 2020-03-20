import XCTest
import Mapbox
import MapboxCoreNavigation
import MapboxDirections
import MapboxSpeech
import MapboxNavigation

class SKUTests: XCTestCase {

    // Billing per monthly active user (MAU), the default, corresponds to `MBXAccountsSKUID.navigationUser`.
    
    func testDirectionsSKU() {
        let directionsSkuToken = Directions.skuToken
        
        XCTAssertNotNil(directionsSkuToken)
        
        XCTAssertEqual(directionsSkuToken?.skuId, SkuID.navigationUser.rawValue)
    }
    
    func testSpeechSynthesizerSKU() {
        let speechSkuToken = SpeechSynthesizer.skuToken
        
        XCTAssertNotNil(speechSkuToken)
        
        XCTAssertEqual(speechSkuToken?.skuId, SkuID.navigationUser.rawValue)
    }
}
