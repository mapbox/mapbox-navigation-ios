import XCTest
import CoreLocation
@testable import MapboxCoreNavigation

let oneMile: CLLocationDistance = metersPerMile
let oneFeet: CLLocationDistance = 0.3048

class DistanceFormatterTests: XCTestCase {
    
    var distanceFormatter = DistanceFormatter(approximate: true)
    
    override func setUp() {
        super.setUp()
    }
    
    func assertDistance(_ distance: CLLocationDistance, displayed: String) {
        let displayedString = distanceFormatter.string(from: distance)
        XCTAssert(displayedString.contains(displayed), "Displayed: '\(displayedString)' should be equal to \(displayed)")
    }
    
    func testDistanceFormatters_US() {
        distanceFormatter.numberFormatter.locale = Locale(identifier: "en-US")
        
        assertDistance(0,               displayed: "0 ft")
        assertDistance(oneFeet*50,      displayed: "50 ft")
        assertDistance(oneFeet*100,     displayed: "100 ft")
        assertDistance(oneFeet*249,     displayed: "250 ft")
        assertDistance(oneFeet*305,     displayed: "300 ft")
        assertDistance(oneMile*0.1,     displayed: "0.1 mi")
        assertDistance(oneMile*0.25,    displayed: "0.2 mi")
        assertDistance(oneMile/2,       displayed: "0.5 mi")
        assertDistance(oneMile*0.75,    displayed: "0.8 mi")
        assertDistance(oneMile,         displayed: "1 mi")
        assertDistance(oneMile*2.5,     displayed: "2.5 mi")
        assertDistance(oneMile*2.9,     displayed: "2.9 mi")
        assertDistance(oneMile*3,       displayed: "3 mi")
        assertDistance(oneMile*3.5,     displayed: "4 mi")
        assertDistance(oneMile*5.4,     displayed: "5 mi")
    }
    
    func testDistanceFormatters_DE() {
        distanceFormatter.numberFormatter.locale = Locale(identifier: "de-DE")
        
        assertDistance(0,       displayed: "0 m")
        assertDistance(4,       displayed: "5 m")
        assertDistance(11,      displayed: "10 m")
        assertDistance(15,      displayed: "15 m")
        assertDistance(24,      displayed: "25 m")
        assertDistance(89,      displayed: "100 m")
        assertDistance(226,     displayed: "250 m")
        assertDistance(275,     displayed: "300 m")
        assertDistance(500,     displayed: "500 m")
        assertDistance(949,     displayed: "950 m")
        assertDistance(951,     displayed: "950 m")
        assertDistance(1000,    displayed: "1 km")
        assertDistance(1001,    displayed: "1 km")
        assertDistance(2_500,   displayed: "2.5 km")
        assertDistance(2_900,   displayed: "2.9 km")
        assertDistance(3_000,   displayed: "3 km")
        assertDistance(3_500,   displayed: "4 km")
    }
    
    func testDistanceFormatters_GB() {
        distanceFormatter.numberFormatter.locale = Locale(identifier: "en-GB")
        
        assertDistance(0,               displayed: "0 ft")
        assertDistance(oneMile/2,       displayed: "0.5 mi")
        assertDistance(oneMile,         displayed: "1 mi")
        assertDistance(oneMile*2.5,     displayed: "2.5 mi")
        assertDistance(oneMile*3,       displayed: "3 mi")
        assertDistance(oneMile*3.5,     displayed: "4 mi")
    }
}
