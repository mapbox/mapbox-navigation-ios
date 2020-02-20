import XCTest
import Mapbox
import MapboxCoreNavigation
import MapboxDirections
import MapboxSpeech
import MapboxNavigation

class SKUTests: XCTestCase {

    // Billing per monthly active user (MAU), the default, corresponds to `MBXAccountsSKUID.navigationUser`.
    func testDefaultSKU() {
        let mapsSkuToken = MGLMapView.skuToken
        let directionsSkuToken = Directions.skuToken
        let speechSkuToken = SpeechSynthesizer.skuToken
        
        XCTAssertNotNil(mapsSkuToken)
        XCTAssertNotNil(speechSkuToken)
        XCTAssertNotNil(directionsSkuToken)
        
        XCTAssertEqual(mapsSkuToken?.skuId, SkuID.navigationUser.rawValue)
        XCTAssertEqual(speechSkuToken?.skuId, SkuID.navigationUser.rawValue)
        XCTAssertEqual(directionsSkuToken?.skuId, SkuID.navigationUser.rawValue)
    }
}
