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
    
    func testDistanceFormatters_US() {
        spokenDistanceFormatter.forcedLocale = Locale(identifier: "en-US")
        distanceFormatter.forcedLocale = Locale(identifier: "en-US")
        
        XCTAssert(spokenDistanceFormatter.string(from: oneMile/2).contains("a half mile"), "Spoken half mile")
        XCTAssert(distanceFormatter.string(from: oneMile/2).contains("0.5 mi"), "Displayed half mile")
        
        XCTAssert(spokenDistanceFormatter.string(from: oneMile).contains("1 mile"), "Spoken one mile")
        XCTAssert(distanceFormatter.string(from: oneMile).contains("1 mi"), "Displayed one mile")
        
        XCTAssert(spokenDistanceFormatter.string(from: oneMile*2.5).contains("2 & a half miles"), "Spoken 2.5 miles")
        XCTAssert(distanceFormatter.string(from: oneMile*2.5).contains("2.5 mi"), "Displayed 2.5 miles")
        
        XCTAssert(spokenDistanceFormatter.string(from: oneMile*3).contains("3 miles"), "Spoken 3 miles")
        XCTAssert(distanceFormatter.string(from: oneMile*3).contains("3 mi"), "Displayed 3 miles")
        
        XCTAssert(spokenDistanceFormatter.string(from: oneMile*3.5).contains("4 miles"), "Spoken 3.5 miles")
        XCTAssert(distanceFormatter.string(from: oneMile*3.5).contains("4 mi"), "Displayed 3.5 miles")
    }
    
    func testDistanceFormatters_DE() {
        spokenDistanceFormatter.forcedLocale = Locale(identifier: "de-DE")
        distanceFormatter.forcedLocale = Locale(identifier: "de-DE")
        
        XCTAssert(spokenDistanceFormatter.string(from: 500).contains("500 Meter"), "Spoken 500 meter")
        XCTAssert(distanceFormatter.string(from: 500).contains("500 m"), "Displayed 500 meter")
        
        XCTAssert(spokenDistanceFormatter.string(from: 1_000).contains("1.000 Meter"), "Spoken 1000 meters")
        XCTAssert(distanceFormatter.string(from: 1_000).contains("1.000 m"), "Displayed 1000 meters")
        
        XCTAssert(spokenDistanceFormatter.string(from: 2_500).contains("2.5 Kilometer"), "Spoken 2.5 kilometers")
        XCTAssert(distanceFormatter.string(from: 2_500).contains("2.5 km"), "Displayed 2.5 kilometers")
        
        XCTAssert(spokenDistanceFormatter.string(from: 3_500).contains("4 Kilometer"), "Spoken 3.5 kilometers")
        XCTAssert(distanceFormatter.string(from: 3_500).contains("4 km"), "Displayed 3.5 kilometers")
    }
    
    func testDistanceFormatters_GB() {
        spokenDistanceFormatter.forcedLocale = Locale(identifier: "en-GB")
        distanceFormatter.forcedLocale = Locale(identifier: "en-GB")
        
        XCTAssert(spokenDistanceFormatter.string(from: oneMile/2).contains("a half mile"), "Spoken half mile")
        XCTAssert(distanceFormatter.string(from: oneMile/2).contains("0.5 mi"), "Displayed half mile")
        
        XCTAssert(spokenDistanceFormatter.string(from: oneMile).contains("1 mile"), "Spoken one mile")
        XCTAssert(distanceFormatter.string(from: oneMile).contains("1 mi"), "Displayed one mile")
        
        XCTAssert(spokenDistanceFormatter.string(from: oneMile*2.5).contains("2 & a half miles"), "Spoken 2.5 miles")
        XCTAssert(distanceFormatter.string(from: oneMile*2.5).contains("2.5 mi"), "Displayed 2.5 miles")
        
        XCTAssert(spokenDistanceFormatter.string(from: oneMile*3).contains("3 miles"), "Spoken 3 miles")
        XCTAssert(distanceFormatter.string(from: oneMile*3).contains("3 mi"), "Displayed 3 miles")
        
        XCTAssert(spokenDistanceFormatter.string(from: oneMile*3.5).contains("4 miles"), "Spoken 3.5 miles")
        XCTAssert(distanceFormatter.string(from: oneMile*3.5).contains("4 mi"), "Displayed 3.5 miles")
    }
    
}
