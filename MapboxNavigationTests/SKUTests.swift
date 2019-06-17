import XCTest
import Mapbox
import MapboxCoreNavigation
import MapboxDirections
import MapboxSpeech
import MapboxNavigation


class SKUTests: XCTestCase {

    // Billing per trip is the default which corresponds to `MBXAccountsSKUID.navigationUser`
    func testDefaultSKU() {
        let mapsSkuToken = MGLMapView.skuToken
        let directionsSkuToken = Directions.skuToken
        let speechSkuToken = SpeechSynthesizer.skuToken
        
        XCTAssertNotNil(mapsSkuToken)
        XCTAssertNotNil(speechSkuToken)
        XCTAssertNotNil(directionsSkuToken)
        
        XCTAssertEqual(mapsSkuToken?.skuId, SkuID.mapsUser.rawValue)
        XCTAssertEqual(speechSkuToken?.skuId, SkuID.navigationSession.rawValue)
        XCTAssertEqual(directionsSkuToken?.skuId, SkuID.navigationSession.rawValue)
    }
    
    // Billing per Monthly Active User (MAU) corresponds to `MBXAccountsSKUID.navigationUser`
    func testMAUSKU() {
        MBXAccounts.activateSKUID(.navigationUser)
        
        let mapsSkuToken = MGLMapView.skuToken
        let directionsSkuToken = Directions.skuToken
        let speechSkuToken = SpeechSynthesizer.skuToken
        
        XCTAssertNotNil(mapsSkuToken)
        XCTAssertNotNil(speechSkuToken)
        XCTAssertNotNil(directionsSkuToken)
        
        XCTAssertEqual(mapsSkuToken?.skuId, SkuID.navigationUser.rawValue)
        XCTAssertEqual(speechSkuToken?.skuId, SkuID.navigationUser.rawValue)
        XCTAssertEqual(directionsSkuToken?.skuId, SkuID.navigationUser.rawValue)
        
        // Re-activate default
        MBXAccounts.activateSKUID(.navigationSession)
    }
}
