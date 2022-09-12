import XCTest
import CoreLocation
import TestHelper
@testable import MapboxCoreNavigation

class DistanceFormatterTests: TestCase {
    var distanceFormatter = DistanceFormatter()
    
    override func setUp() {
        super.setUp()
    }
    
    func assertDistance(_ measurement: Measurement<UnitLength>, displayed: String, quantity: String) {
        let displayedString = distanceFormatter.string(from: measurement)
        XCTAssertEqual(displayedString, displayed, "Displayed: '\(displayedString)' should be equal to \(displayed)")
        
        let value = measurement.localized(into: distanceFormatter.locale).value
        XCTAssertEqual(distanceFormatter.measurementFormatter.numberFormatter.string(from: value as NSNumber), quantity)
        
        let attributedString = distanceFormatter.attributedString(for: measurement.distance as NSNumber)
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
        let quantityAttrs = checkedAttributedString.attributes(at: checkedQuantityRange.lowerBound.utf16Offset(in: checkedAttributedString.string), effectiveRange: &effectiveQuantityRange)
        XCTAssertEqual(quantityAttrs[.quantity] as? NSNumber, value as NSNumber, "'\(quantity)' should have quantity \(measurement.distance)")
        XCTAssertEqual(effectiveQuantityRange.length, quantity.count)
        
        guard checkedQuantityRange.upperBound.utf16Offset(in: checkedAttributedString.string) < checkedAttributedString.length else {
            return
        }
        let unitAttrs = checkedAttributedString.attributes(at: checkedQuantityRange.upperBound.utf16Offset(in: checkedAttributedString.string), effectiveRange: nil)
        XCTAssertNil(unitAttrs[.quantity], "Unit should not be emphasized like a quantity")
    }
    
    func testDistanceFormatters_US() {
        NavigationSettings.shared.distanceUnit = .mile
        distanceFormatter.locale = Locale(identifier: "en-US")

        assertDistance(Measurement(value:   0,      unit: .feet),  displayed: "0 ft",      quantity: "0")
        assertDistance(Measurement(value:  50,      unit: .feet),  displayed: "50 ft",     quantity: "50")
        assertDistance(Measurement(value: 100,      unit: .feet),  displayed: "100 ft",    quantity: "100")
        assertDistance(Measurement(value: 249,      unit: .feet),  displayed: "250 ft",    quantity: "250")
        assertDistance(Measurement(value: 305,      unit: .feet),  displayed: "300 ft",    quantity: "300")
        assertDistance(Measurement(value:   0.1,    unit: .miles), displayed: "0.1 mi",    quantity: "0.1")
        assertDistance(Measurement(value:   0.24,   unit: .miles), displayed: "0.2 mi",    quantity: "0.2")
        assertDistance(Measurement(value:   0.251,  unit: .miles), displayed: "0.3 mi",    quantity: "0.3")
        assertDistance(Measurement(value:   0.75,   unit: .miles), displayed: "0.8 mi",    quantity: "0.8")
        assertDistance(Measurement(value:   1,      unit: .miles), displayed: "1 mi",      quantity: "1")
        assertDistance(Measurement(value:   2.5,    unit: .miles), displayed: "2.5 mi",    quantity: "2.5")
        assertDistance(Measurement(value:   2.9,    unit: .miles), displayed: "2.9 mi",    quantity: "2.9")
        assertDistance(Measurement(value:   3,      unit: .miles), displayed: "3 mi",      quantity: "3")
        assertDistance(Measurement(value:   3.5,    unit: .miles), displayed: "4 mi",      quantity: "4")
        assertDistance(Measurement(value:   5.4,    unit: .miles), displayed: "5 mi",      quantity: "5")
    }
    
    func testDistanceFormatters_DE() {
        NavigationSettings.shared.distanceUnit = .kilometer
        distanceFormatter.locale = Locale(identifier: "de-DE")

        assertDistance(Measurement(value:   0,      unit: .meters),     displayed: "0 m",       quantity: "0")
        assertDistance(Measurement(value:   4,      unit: .meters),     displayed: "5 m",       quantity: "5")
        assertDistance(Measurement(value:  11,      unit: .meters),     displayed: "10 m",      quantity: "10")
        assertDistance(Measurement(value:  15,      unit: .meters),     displayed: "15 m",      quantity: "15")
        assertDistance(Measurement(value:  24,      unit: .meters),     displayed: "25 m",      quantity: "25")
        assertDistance(Measurement(value:  89,      unit: .meters),     displayed: "100 m",     quantity: "100")
        assertDistance(Measurement(value: 226,      unit: .meters),     displayed: "250 m",     quantity: "250")
        assertDistance(Measurement(value: 275,      unit: .meters),     displayed: "300 m",     quantity: "300")
        assertDistance(Measurement(value: 500,      unit: .meters),     displayed: "500 m",     quantity: "500")
        assertDistance(Measurement(value: 949,      unit: .meters),     displayed: "950 m",     quantity: "950")
        assertDistance(Measurement(value: 951,      unit: .meters),     displayed: "950 m",     quantity: "950")
        assertDistance(Measurement(value: 999,      unit: .meters),     displayed: "1 km",      quantity: "1")
        assertDistance(Measurement(value:   1,      unit: .kilometers), displayed: "1 km",      quantity: "1")
        assertDistance(Measurement(value:   1.001,  unit: .kilometers), displayed: "1 km",      quantity: "1")
        assertDistance(Measurement(value:   2.5,    unit: .kilometers), displayed: "2,5 km",    quantity: "2,5")
        assertDistance(Measurement(value:   2.9,    unit: .kilometers), displayed: "2,9 km",    quantity: "2,9")
        assertDistance(Measurement(value:   3,      unit: .kilometers), displayed: "3 km",      quantity: "3")
        assertDistance(Measurement(value:   3.5,    unit: .kilometers), displayed: "4 km",      quantity: "4")
    }
    
    func testDistanceFormatters_GB() {
        NavigationSettings.shared.distanceUnit = .mile
        distanceFormatter.locale = Locale(identifier: "en-GB")

        assertDistance(Measurement(value:   0,      unit: .yards),  displayed: "0 yd",      quantity: "0")
        assertDistance(Measurement(value:   4,      unit: .yards),  displayed: "0 yd",      quantity: "0")
        assertDistance(Measurement(value:   5,      unit: .yards),  displayed: "10 yd",     quantity: "10")
        assertDistance(Measurement(value:  12,      unit: .yards),  displayed: "10 yd",     quantity: "10")
        assertDistance(Measurement(value:  24,      unit: .yards),  displayed: "25 yd",     quantity: "25")
        assertDistance(Measurement(value:  25,      unit: .yards),  displayed: "25 yd",     quantity: "25")
        assertDistance(Measurement(value:  38,      unit: .yards),  displayed: "50 yd",     quantity: "50")
        assertDistance(Measurement(value: 126,      unit: .yards),  displayed: "150 yd",    quantity: "150")
        assertDistance(Measurement(value: 150,      unit: .yards),  displayed: "150 yd",    quantity: "150")
        assertDistance(Measurement(value: 174,      unit: .yards),  displayed: "150 yd",    quantity: "150")
        assertDistance(Measurement(value: 175,      unit: .yards),  displayed: "200 yd",    quantity: "200")
        assertDistance(Measurement(value:   0.5,    unit: .miles),  displayed: "0.5 mi",    quantity: "0.5")
        assertDistance(Measurement(value:   1,      unit: .miles),  displayed: "1 mi",      quantity: "1")
        assertDistance(Measurement(value:   2.5,    unit: .miles),  displayed: "2.5 mi",    quantity: "2.5")
        assertDistance(Measurement(value:   3,      unit: .miles),  displayed: "3 mi",      quantity: "3")
        assertDistance(Measurement(value:   3.5,    unit: .miles),  displayed: "4 mi",      quantity: "4")
    }

    func testDistanceFormatters_he_IL() {
        NavigationSettings.shared.distanceUnit = .kilometer
        distanceFormatter.locale = Locale(identifier: "he-IL")

        assertDistance(Measurement(value:   0,      unit: .meters),     displayed: "0 מ׳",       quantity: "0")
        assertDistance(Measurement(value:   4,      unit: .meters),     displayed: "5 מ׳",       quantity: "5")
        assertDistance(Measurement(value:  11,      unit: .meters),     displayed: "10 מ׳",      quantity: "10")
        assertDistance(Measurement(value:  15,      unit: .meters),     displayed: "15 מ׳",      quantity: "15")
        assertDistance(Measurement(value:  24,      unit: .meters),     displayed: "25 מ׳",      quantity: "25")
        assertDistance(Measurement(value:  89,      unit: .meters),     displayed: "100 מ׳",     quantity: "100")
        assertDistance(Measurement(value: 226,      unit: .meters),     displayed: "250 מ׳",     quantity: "250")
        assertDistance(Measurement(value: 275,      unit: .meters),     displayed: "300 מ׳",     quantity: "300")
        assertDistance(Measurement(value: 500,      unit: .meters),     displayed: "500 מ׳",     quantity: "500")
        assertDistance(Measurement(value: 949,      unit: .meters),     displayed: "950 מ׳",     quantity: "950")
        assertDistance(Measurement(value: 951,      unit: .meters),     displayed: "950 מ׳",     quantity: "950")

        func iOS16Fix(_ input: String) -> String {
            // Formatter in iOS 16 now returns U+202F NARROW NO-BREAK SPACE instead of simple space
            if #available(iOS 16, *) {
                return input.replacingOccurrences(
                    of: "\u{0020}",
                    with: "\u{202F}")
            } else {
                return input
            }
        }

        assertDistance(Measurement(value: 1,     unit: .kilometers), displayed: iOS16Fix("1 ק״מ"),   quantity: "1")
        assertDistance(Measurement(value: 1.001, unit: .kilometers), displayed: iOS16Fix("1 ק״מ"),   quantity: "1")
        assertDistance(Measurement(value: 2.5,   unit: .kilometers), displayed: iOS16Fix("2.5 ק״מ"), quantity: "2.5")
        assertDistance(Measurement(value: 2.9,   unit: .kilometers), displayed: iOS16Fix("2.9 ק״מ"), quantity: "2.9")
        assertDistance(Measurement(value: 3,     unit: .kilometers), displayed: iOS16Fix("3 ק״מ"),   quantity: "3")
        assertDistance(Measurement(value: 3.5,   unit: .kilometers), displayed: iOS16Fix("4 ק״מ"),   quantity: "4")
    }

    func testDistanceFormatters_hi_IN() {
        NavigationSettings.shared.distanceUnit = .kilometer
        // Hindi as written in India in Devanagari script with Devanagari numbers.
        distanceFormatter.locale = Locale(identifier: "hi-Deva-IN-u-nu-deva")

        assertDistance(Measurement(value:   0,      unit: .meters),     displayed: "० मी॰",       quantity: "०")
        assertDistance(Measurement(value:   4,      unit: .meters),     displayed: "५ मी॰",       quantity: "५")
        assertDistance(Measurement(value:  11,      unit: .meters),     displayed: "१० मी॰",      quantity: "१०")
        assertDistance(Measurement(value:  15,      unit: .meters),     displayed: "१५ मी॰",      quantity: "१५")
        assertDistance(Measurement(value:  24,      unit: .meters),     displayed: "२५ मी॰",      quantity: "२५")
        assertDistance(Measurement(value:  89,      unit: .meters),     displayed: "१०० मी॰",     quantity: "१००")
        assertDistance(Measurement(value: 226,      unit: .meters),     displayed: "२५० मी॰",     quantity: "२५०")
        assertDistance(Measurement(value: 275,      unit: .meters),     displayed: "३०० मी॰",     quantity: "३००")
        assertDistance(Measurement(value: 500,      unit: .meters),     displayed: "५०० मी॰",     quantity: "५००")
        assertDistance(Measurement(value: 949,      unit: .meters),     displayed: "९५० मी॰",     quantity: "९५०")
        assertDistance(Measurement(value: 951,      unit: .meters),     displayed: "९५० मी॰",     quantity: "९५०")
        assertDistance(Measurement(value:   1,      unit: .kilometers), displayed: "१ कि॰मी॰",      quantity: "१")
        assertDistance(Measurement(value:   1.001,  unit: .kilometers), displayed: "१ कि॰मी॰",      quantity: "१")
        assertDistance(Measurement(value:   2.5,    unit: .kilometers), displayed: "२.५ कि॰मी॰",    quantity: "२.५")
        assertDistance(Measurement(value:   2.9,    unit: .kilometers), displayed: "२.९ कि॰मी॰",    quantity: "२.९")
        assertDistance(Measurement(value:   3,      unit: .kilometers), displayed: "३ कि॰मी॰",      quantity: "३")
        assertDistance(Measurement(value:   3.5,    unit: .kilometers), displayed: "४ कि॰मी॰",      quantity: "४")
        assertDistance(Measurement(value: 384.4,    unit: .megameters), displayed: "३,८४,४०० कि॰मी॰", quantity: "३,८४,४००")
    }
}
