import XCTest
import CoreLocation
@testable import MapboxCoreNavigation

let oneMile: CLLocationDistance = metersPerMile
let oneFeet: CLLocationDistance = 0.3048

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
        
        assertDistance(0,               spoken: "0 feet",               displayed: "0 ft")
        assertDistance(oneFeet*50,      spoken: "50 feet",              displayed: "50 ft")
        assertDistance(oneFeet*100,     spoken: "100 feet",             displayed: "100 ft")
        assertDistance(oneFeet*249,     spoken: "250 feet",             displayed: "250 ft")
        assertDistance(oneFeet*305,     spoken: "300 feet",             displayed: "300 ft")
        assertDistance(oneFeet*997,     spoken: "1,000 feet",           displayed: "1,000 ft")
        assertDistance(oneMile*0.25,    spoken: "a quarter mile",       displayed: "0.2 mi")
        assertDistance(oneMile/2,       spoken: "a half mile",          displayed: "0.5 mi")
        assertDistance(oneMile*0.75,    spoken: "3 quarters of a mile", displayed: "0.8 mi")
        assertDistance(oneMile,         spoken: "1 mile",               displayed: "1 mi")
        assertDistance(oneMile*2.5,     spoken: "2 & a half miles",     displayed: "2.5 mi")
        assertDistance(oneMile*2.9,     spoken: "2.9 miles",            displayed: "2.9 mi")
        assertDistance(oneMile*3,       spoken: "3 miles",              displayed: "3 mi")
        assertDistance(oneMile*3.5,     spoken: "4 miles",              displayed: "4 mi")
        assertDistance(oneMile*5.4,     spoken: "5 miles",              displayed: "5 mi")
    }
    
    func testDistanceFormatters_DE() {
        spokenDistanceFormatter.numberFormatter.locale = Locale(identifier: "de-DE")
        distanceFormatter.numberFormatter.locale = Locale(identifier: "de-DE")
        
        assertDistance(0,       spoken: "0 Meter",          displayed: "0 m")
        assertDistance(4,       spoken: "5 Meter",          displayed: "5 m")
        assertDistance(11,      spoken: "10 Meter",         displayed: "10 m")
        assertDistance(15,      spoken: "15 Meter",         displayed: "15 m")
        assertDistance(24,      spoken: "25 Meter",         displayed: "25 m")
        assertDistance(89,      spoken: "100 Meter",        displayed: "100 m")
        assertDistance(226,     spoken: "250 Meter",        displayed: "250 m")
        assertDistance(275,     spoken: "300 Meter",        displayed: "300 m")
        assertDistance(500,     spoken: "500 Meter",        displayed: "500 m")
        assertDistance(949,     spoken: "950 Meter",        displayed: "950 m")
        assertDistance(951,     spoken: "950 Meter",        displayed: "950 m")
        assertDistance(1000,    spoken: "1 Kilometer",      displayed: "1 km")
        assertDistance(1001,    spoken: "1 Kilometer",      displayed: "1 km")
        assertDistance(2_500,   spoken: "2.5 Kilometer",    displayed: "2.5 km")
        assertDistance(2_900,   spoken: "2.9 Kilometer",    displayed: "2.9 km")
        assertDistance(3_000,   spoken: "3 Kilometer",      displayed: "3 km")
        assertDistance(3_500,   spoken: "4 Kilometer",      displayed: "4 km")
    }
    
    func testDistanceFormatters_GB() {
        spokenDistanceFormatter.numberFormatter.locale = Locale(identifier: "en-GB")
        distanceFormatter.numberFormatter.locale = Locale(identifier: "en-GB")
        
        assertDistance(0,           spoken: "0 feet",               displayed: "0 ft")
        assertDistance(oneMile/2,   spoken: "a half mile",          displayed: "0.5 mi")
        assertDistance(oneMile,     spoken: "1 mile",               displayed: "1 mi")
        assertDistance(oneMile*2.5, spoken: "2 & a half miles",     displayed: "2.5 mi")
        assertDistance(oneMile*3,   spoken: "3 miles",              displayed: "3 mi")
        assertDistance(oneMile*3.5, spoken: "4 miles",              displayed: "4 mi")
    }
}
