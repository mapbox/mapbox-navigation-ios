import XCTest
import CoreLocation
@testable import MapboxCoreNavigation

let oneMile: CLLocationDistance = .metersPerMile
let oneYard: CLLocationDistance = 0.9144
let oneFeet: CLLocationDistance = 0.3048

class DistanceFormatterTests: XCTestCase {
    
    var distanceFormatter = DistanceFormatter(approximate: true)
    
    override func setUp() {
        super.setUp()
    }
    
    func assertDistance(_ distance: CLLocationDistance, displayed: String, quantity: String) {
        let displayedString = distanceFormatter.string(from: distance)
        XCTAssertEqual(displayedString, displayed, "Displayed: '\(displayedString)' should be equal to \(displayed)")
        
        let attributedString = distanceFormatter.attributedString(for: distance as NSNumber)
        XCTAssertEqual(attributedString?.string, displayed, "Displayed: '\(attributedString?.string ?? "")' should be equal to \(displayed)")
        guard let checkedAttributedString = attributedString else {
            return
        }
        
        let quantityRange = checkedAttributedString.string.range(of: quantity)
        XCTAssertNotNil(quantityRange, "Displayed: '\(checkedAttributedString.string)' should contain \(quantity)")
        guard let checkedQuantityRange = quantityRange else {
            return
        }
        
        var effectiveQuantityRange = NSRange(location: NSNotFound, length: 0)
        let quantityAttrs = checkedAttributedString.attributes(at: checkedQuantityRange.lowerBound.encodedOffset, effectiveRange: &effectiveQuantityRange)
        XCTAssertEqual(quantityAttrs[NSAttributedStringKey.quantity] as? NSNumber, distance as NSNumber, "'\(quantity)' should have quantity \(distance)")
        XCTAssertEqual(effectiveQuantityRange.length, quantity.count)
        
        guard checkedQuantityRange.upperBound.encodedOffset < checkedAttributedString.length else {
            return
        }
        let unitAttrs = checkedAttributedString.attributes(at: checkedQuantityRange.upperBound.encodedOffset, effectiveRange: nil)
        XCTAssertNil(unitAttrs[NSAttributedStringKey.quantity], "Unit should not be emphasized like a quantity")
    }
    
    func testDistanceFormatters_US() {
        NavigationSettings.shared.distanceUnit = .mile
        distanceFormatter.numberFormatter.locale = Locale(identifier: "en-US")
        
        assertDistance(0,               displayed: "0 ft",      quantity: "0")
        assertDistance(oneFeet*50,      displayed: "50 ft",     quantity: "50")
        assertDistance(oneFeet*100,     displayed: "100 ft",    quantity: "100")
        assertDistance(oneFeet*249,     displayed: "250 ft",    quantity: "250")
        assertDistance(oneFeet*305,     displayed: "300 ft",    quantity: "300")
        assertDistance(oneMile*0.1,     displayed: "0.1 mi",    quantity: "0.1")
        assertDistance(oneMile*0.24,    displayed: "0.2 mi",    quantity: "0.2")
        assertDistance(oneMile*0.251,   displayed: "0.3 mi",    quantity: "0.3")
        assertDistance(oneMile*0.75,    displayed: "0.8 mi",    quantity: "0.8")
        assertDistance(oneMile,         displayed: "1 mi",      quantity: "1")
        assertDistance(oneMile*2.5,     displayed: "2.5 mi",    quantity: "2.5")
        assertDistance(oneMile*2.9,     displayed: "2.9 mi",    quantity: "2.9")
        assertDistance(oneMile*3,       displayed: "3 mi",      quantity: "3")
        assertDistance(oneMile*3.5,     displayed: "4 mi",      quantity: "4")
        assertDistance(oneMile*5.4,     displayed: "5 mi",      quantity: "5")
    }
    
    func testDistanceFormatters_DE() {
        NavigationSettings.shared.distanceUnit = .kilometer
        distanceFormatter.numberFormatter.locale = Locale(identifier: "de-DE")
        
        assertDistance(0,       displayed: "0 m",       quantity: "0")
        assertDistance(4,       displayed: "5 m",       quantity: "5")
        assertDistance(11,      displayed: "10 m",      quantity: "10")
        assertDistance(15,      displayed: "15 m",      quantity: "15")
        assertDistance(24,      displayed: "25 m",      quantity: "25")
        assertDistance(89,      displayed: "100 m",     quantity: "100")
        assertDistance(226,     displayed: "250 m",     quantity: "250")
        assertDistance(275,     displayed: "300 m",     quantity: "300")
        assertDistance(500,     displayed: "500 m",     quantity: "500")
        assertDistance(949,     displayed: "950 m",     quantity: "950")
        assertDistance(951,     displayed: "950 m",     quantity: "950")
        assertDistance(999,     displayed: "1 km",      quantity: "1")
        assertDistance(1000,    displayed: "1 km",      quantity: "1")
        assertDistance(1001,    displayed: "1 km",      quantity: "1")
        assertDistance(2_500,   displayed: "2.5 km",    quantity: "2.5")
        assertDistance(2_900,   displayed: "2.9 km",    quantity: "2.9")
        assertDistance(3_000,   displayed: "3 km",      quantity: "3")
        assertDistance(3_500,   displayed: "4 km",      quantity: "4")
    }
    
    func testDistanceFormatters_GB() {
        NavigationSettings.shared.distanceUnit = .mile
        distanceFormatter.numberFormatter.locale = Locale(identifier: "en-GB")
        
        assertDistance(0,               displayed: "0 yd",      quantity: "0")
        assertDistance(oneYard*4,       displayed: "0 yd",      quantity: "0")
        assertDistance(oneYard*5,       displayed: "10 yd",     quantity: "10")
        assertDistance(oneYard*12,      displayed: "10 yd",     quantity: "10")
        assertDistance(oneYard*24,      displayed: "25 yd",     quantity: "25")
        assertDistance(oneYard*25,      displayed: "25 yd",     quantity: "25")
        assertDistance(oneYard*38,      displayed: "50 yd",     quantity: "50")
        assertDistance(oneYard*126,     displayed: "150 yd",    quantity: "150")
        assertDistance(oneYard*150,     displayed: "150 yd",    quantity: "150")
        assertDistance(oneYard*174,     displayed: "150 yd",    quantity: "150")
        assertDistance(oneYard*175,     displayed: "200 yd",    quantity: "200")
        assertDistance(oneMile/2,       displayed: "0.5 mi",    quantity: "0.5")
        assertDistance(oneMile,         displayed: "1 mi",      quantity: "1")
        assertDistance(oneMile*2.5,     displayed: "2.5 mi",    quantity: "2.5")
        assertDistance(oneMile*3,       displayed: "3 mi",      quantity: "3")
        assertDistance(oneMile*3.5,     displayed: "4 mi",      quantity: "4")
    }
    
    func testDistanceFormatters_he_IL() {
        NavigationSettings.shared.distanceUnit = .kilometer
        distanceFormatter.numberFormatter.locale = Locale(identifier: "he-IL")
        
        assertDistance(0,       displayed: "0 מ׳",       quantity: "0")
        assertDistance(4,       displayed: "5 מ׳",       quantity: "5")
        assertDistance(11,      displayed: "10 מ׳",      quantity: "10")
        assertDistance(15,      displayed: "15 מ׳",      quantity: "15")
        assertDistance(24,      displayed: "25 מ׳",      quantity: "25")
        assertDistance(89,      displayed: "100 מ׳",     quantity: "100")
        assertDistance(226,     displayed: "250 מ׳",     quantity: "250")
        assertDistance(275,     displayed: "300 מ׳",     quantity: "300")
        assertDistance(500,     displayed: "500 מ׳",     quantity: "500")
        assertDistance(949,     displayed: "950 מ׳",     quantity: "950")
        assertDistance(951,     displayed: "950 מ׳",     quantity: "950")
        assertDistance(1000,    displayed: "1 ק״מ",      quantity: "1")
        assertDistance(1001,    displayed: "1 ק״מ",      quantity: "1")
        assertDistance(2_500,   displayed: "2.5 ק״מ",    quantity: "2.5")
        assertDistance(2_900,   displayed: "2.9 ק״מ",    quantity: "2.9")
        assertDistance(3_000,   displayed: "3 ק״מ",      quantity: "3")
        assertDistance(3_500,   displayed: "4 ק״מ",      quantity: "4")
    }
    
    func testDistanceFormatters_hi_IN() {
        NavigationSettings.shared.distanceUnit = .kilometer
        distanceFormatter.numberFormatter.locale = Locale(identifier: "hi-IN")
    
        assertDistance(0,       displayed: "० मी॰",       quantity: "०")
        assertDistance(4,       displayed: "५ मी॰",       quantity: "५")
        assertDistance(11,      displayed: "१० मी॰",      quantity: "१०")
        assertDistance(15,      displayed: "१५ मी॰",      quantity: "१५")
        assertDistance(24,      displayed: "२५ मी॰",      quantity: "२५")
        assertDistance(89,      displayed: "१०० मी॰",     quantity: "१००")
        assertDistance(226,     displayed: "२५० मी॰",     quantity: "२५०")
        assertDistance(275,     displayed: "३०० मी॰",     quantity: "३००")
        assertDistance(500,     displayed: "५०० मी॰",     quantity: "५००")
        assertDistance(949,     displayed: "९५० मी॰",     quantity: "९५०")
        assertDistance(951,     displayed: "९५० मी॰",     quantity: "९५०")
        assertDistance(1000,    displayed: "१ कि॰मी॰",      quantity: "१")
        assertDistance(1001,    displayed: "१ कि॰मी॰",      quantity: "१")
        assertDistance(2_500,   displayed: "२.५ कि॰मी॰",    quantity: "२.५")
        assertDistance(2_900,   displayed: "२.९ कि॰मी॰",    quantity: "२.९")
        assertDistance(3_000,   displayed: "३ कि॰मी॰",      quantity: "३")
        assertDistance(3_500,   displayed: "४ कि॰मी॰",      quantity: "४")
        assertDistance(384_400_000, displayed: "३,८४,४०० कि॰मी॰", quantity: "३,८४,४००")
    }
    
    func testInches() {
        let oneMeter: CLLocationDistance = 1
        let oneMeterInInches = oneMeter.converted(to: .inch)
        XCTAssertEqual(oneMeterInInches, 39.3700787, accuracy: 0.00001)
    }
}
