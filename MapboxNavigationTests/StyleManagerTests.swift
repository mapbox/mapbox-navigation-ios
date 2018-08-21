import XCTest
import Solar
@testable import MapboxNavigation

struct Location {
    static let sf = CLLocation(latitude: 37.78, longitude: -122.40)
    static let london = CLLocation(latitude: 51.50, longitude: -0.12)
}

class StyleManagerTests: XCTestCase {
    
    var location = Location.london
    var styleManager: StyleManager!
    
    override func setUp() {
        super.setUp()
        styleManager = StyleManager(self)
        styleManager.automaticallyAdjustsStyleForTimeOfDay = true
    }
    
    func testStyleManagerLondon() {
        location = Location.london
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        let beforeSunrise = dateFormatter.date(from: "05:00")!
        let afterSunrise = dateFormatter.date(from: "09:00")!
        let noonDate = dateFormatter.date(from: "12:00")!
        let beforeSunset = dateFormatter.date(from: "16:00")!
        let afterSunset = dateFormatter.date(from: "21:00")!
        let midnight = dateFormatter.date(from: "00:00")!
        
        styleManager.date = beforeSunrise
        XCTAssert(styleManager.styleType(for: location) == .night)
        styleManager.date = afterSunrise
        XCTAssert(styleManager.styleType(for: location) == .day)
        styleManager.date = noonDate
        XCTAssert(styleManager.styleType(for: location) == .day)
        styleManager.date = beforeSunset
        XCTAssert(styleManager.styleType(for: location) == .day)
        styleManager.date = afterSunset
        XCTAssert(styleManager.styleType(for: location) == .night)
        styleManager.date = midnight
        XCTAssert(styleManager.styleType(for: location) == .night)
    }
    
    func testStyleManagerSanFrancisco() {
        location = Location.sf
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        dateFormatter.timeZone = TimeZone(identifier: "PST")
        
//        NSTimeZone.default = NSTimeZone.init(abbreviation: "PST")! as TimeZone
//        
//        let beforeSunrise = dateFormatter.date(from: "05:00 AM")!
//        let afterSunrise = dateFormatter.date(from: "09:00 AM")!
//        let noonDate = dateFormatter.date(from: "12:00 PM")!
//        let beforeSunset = dateFormatter.date(from: "04:00 PM")!
//        let afterSunset = dateFormatter.date(from: "09:00 PM")!
//        let midnight = dateFormatter.date(from: "00:00 AM")!
//        
//        styleManager.date = beforeSunrise
//        XCTAssert(styleManager.styleType(for: location) == .night)
//        styleManager.date = afterSunrise
//        XCTAssert(styleManager.styleType(for: location) == .day)
//        styleManager.date = noonDate
//        XCTAssert(styleManager.styleType(for: location) == .day)
//        styleManager.date = beforeSunset
//        XCTAssert(styleManager.styleType(for: location) == .day)
//        styleManager.date = afterSunset
//        XCTAssert(styleManager.styleType(for: location) == .night)
//        styleManager.date = midnight
//        XCTAssert(styleManager.styleType(for: location) == .night)
    }
}

extension StyleManagerTests: StyleManagerDelegate {
    func styleManagerDidRefreshAppearance(_ styleManager: StyleManager) { }
    func styleManager(_ styleManager: StyleManager, didApply style: Style) { }
    
    func locationFor(styleManager: StyleManager) -> CLLocation? {
        return location
    }
}
