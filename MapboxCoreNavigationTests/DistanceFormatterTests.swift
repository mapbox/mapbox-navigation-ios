import XCTest
import CoreLocation
@testable import MapboxCoreNavigation

let oneMile: CLLocationDistance = metersPerMile

class DistanceFormatterTests: XCTestCase {
    
    var spokenDistanceFormatter = SpokenDistanceFormatter(approximate: true)
    var distanceFormatter = DistanceFormatter(approximate: true)
    
    override func setUp() {
        super.setUp()
        spokenDistanceFormatter.unitStyle = .long
    }
    
    func assertDistance(_ distance: CLLocationDistance, spoken: String, displayed: String) {
        let spokenString = spokenDistanceFormatter.string(from: distance)
        let displayedString = distanceFormatter.string(from: distance)
        XCTAssert(spokenString.contains(spoken), "Spoken '\(spokenString)' should be equal to '\(spoken)'")
        XCTAssert(displayedString.contains(displayed), "Displayed: '\(displayedString)' should be equal to \(displayed)")
    }
    
    func testDistanceFormatters_US() {
        spokenDistanceFormatter.numberFormatter.locale = Locale(identifier: "en-US")
        distanceFormatter.numberFormatter.locale = Locale(identifier: "en-US")
        
        assertDistance(oneMile/2,   spoken: "a half mile",        displayed: "0.5 mi")
        assertDistance(oneMile,     spoken: "1 mile",             displayed: "1 mi")
        assertDistance(oneMile*2.5, spoken: "2 & a half miles",   displayed: "2.5 mi")
        assertDistance(oneMile*3,   spoken: "3 miles",            displayed: "3 mi")
        assertDistance(oneMile*3.5, spoken: "4 miles",            displayed: "4 mi")
    }
    
    func testDistanceFormatters_DE() {
        spokenDistanceFormatter.numberFormatter.locale = Locale(identifier: "de-DE")
        distanceFormatter.numberFormatter.locale = Locale(identifier: "de-DE")
        
        assertDistance(500,     spoken: "500 Meter",      displayed: "500 m")
        assertDistance(1000,    spoken: "1.000 Meter",    displayed: "1.000 m")
        assertDistance(2_500,   spoken: "2.5 Kilometer",  displayed: "2.5 km")
        assertDistance(3_500,   spoken: "4 Kilometer",    displayed: "4 km")
    }
    
    func testDistanceFormatters_GB() {
        spokenDistanceFormatter.numberFormatter.locale = Locale(identifier: "en-GB")
        distanceFormatter.numberFormatter.locale = Locale(identifier: "en-GB")
        
        assertDistance(oneMile/2,   spoken: "a half mile",        displayed: "0.5 mi")
        assertDistance(oneMile,     spoken: "1 mile",             displayed: "1 mi")
        assertDistance(oneMile*2.5, spoken: "2 & a half miles",   displayed: "2.5 mi")
        assertDistance(oneMile*3,   spoken: "3 miles",            displayed: "3 mi")
        assertDistance(oneMile*3.5, spoken: "4 miles",            displayed: "4 mi")
    }
}
