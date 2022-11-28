import XCTest
import Solar
import CoreLocation
import TestHelper
@testable import MapboxNavigation

struct Location {
    static let sf = CLLocation(latitude: 37.78, longitude: -122.40)
    static let london = CLLocation(latitude: 51.50, longitude: -0.12)
    static let paris = CLLocation(latitude: 48.85, longitude: 2.35)
}

class StyleManagerTests: TestCase {
    var location = Location.london
    var styleManager: StyleManager!
    
    override func setUp() {
        super.setUp()
        styleManager = StyleManager()
        styleManager.delegate = self
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

    func testStyleManagerParisWithSeconds() {
        location = Location.paris
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "CET")

        NSTimeZone.default = NSTimeZone.init(abbreviation: "CET")! as TimeZone

        let justBeforeSunrise = dateFormatter.date(from: "08:44:05")!
        let justAfterSunrise = dateFormatter.date(from: "08:44:30")!
        let noonDate = dateFormatter.date(from: "12:00:00")!
        let juetBeforeSunset = dateFormatter.date(from: "17:04:05")!
        let justAfterSunset = dateFormatter.date(from: "17:04:30")!
        let midnight = dateFormatter.date(from: "00:00:00")!

        styleManager.date = justBeforeSunrise
        XCTAssert(styleManager.styleType(for: location) == .night)
        styleManager.date = justAfterSunrise
        XCTAssert(styleManager.styleType(for: location) == .day)
        styleManager.date = noonDate
        XCTAssert(styleManager.styleType(for: location) == .day)
        styleManager.date = juetBeforeSunset
        XCTAssert(styleManager.styleType(for: location) == .day)
        styleManager.date = justAfterSunset
        XCTAssert(styleManager.styleType(for: location) == .night)
        styleManager.date = midnight
        XCTAssert(styleManager.styleType(for: location) == .night)
    }
    
    func testStyleManagerSanFrancisco() {
        location = Location.sf
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        dateFormatter.timeZone = TimeZone(identifier: "PST")
        
        NSTimeZone.default = NSTimeZone.init(abbreviation: "PST")! as TimeZone
        
        let beforeSunrise = dateFormatter.date(from: "05:00 AM")!
        let afterSunrise = dateFormatter.date(from: "09:00 AM")!
        let noonDate = dateFormatter.date(from: "12:00 PM")!
        let beforeSunset = dateFormatter.date(from: "04:00 PM")!
        let afterSunset = dateFormatter.date(from: "09:00 PM")!
        let midnight = dateFormatter.date(from: "00:00 AM")!
        
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

    func testTimeIntervalsUntilTimeOfDayChanges() {
        location = Location.paris
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        dateFormatter.timeZone = TimeZone(identifier: "CET")

        NSTimeZone.default = NSTimeZone.init(abbreviation: "CET")! as TimeZone

        let sunrise = dateFormatter.date(from: "08:00")!
        let sunset = dateFormatter.date(from: "18:00")!

        let beforeSunriseAfterMidnight = dateFormatter.date(from: "02:00")!
        let afterSunriseBeforeSunset = dateFormatter.date(from: "11:00")!
        let afterSunsetBeforeMidnight = dateFormatter.date(from: "22:00")!

        XCTAssert(beforeSunriseAfterMidnight.intervalUntilTimeOfDayChanges(sunrise: sunrise, sunset: sunset) == (6 * 3600))
        XCTAssert(afterSunriseBeforeSunset.intervalUntilTimeOfDayChanges(sunrise: sunrise, sunset: sunset) == (7 * 3600))
        XCTAssert(afterSunsetBeforeMidnight.intervalUntilTimeOfDayChanges(sunrise: sunrise, sunset: sunset) == (10 * 3600))
    }
    
    func testDidChangeStyleNotification() {
        styleManager.styles = [DayStyle(), NightStyle()]
        location = Location.paris
        
        styleManager.applyStyle(type: .day)
        
        let dayExpectation = expectation(forNotification: .styleManagerDidApplyStyle, object: styleManager) { (notification) -> Bool in
            let userInfo = notification.userInfo
            let style = userInfo?[StyleManagerNotificationUserInfoKey.styleKey] as? Style
            let styleManager = userInfo?[StyleManagerNotificationUserInfoKey.styleManagerKey] as? StyleManager
            XCTAssertNotNil(style)
            XCTAssertNotNil(styleManager)
            return style?.styleType == StyleType.day
        }
        
        let nightExpectation = expectation(forNotification: .styleManagerDidApplyStyle, object: styleManager) { (notification) -> Bool in
            let userInfo = notification.userInfo
            let style = userInfo?[StyleManagerNotificationUserInfoKey.styleKey] as? Style
            let styleManager = userInfo?[StyleManagerNotificationUserInfoKey.styleManagerKey] as? StyleManager
            XCTAssertNotNil(style)
            XCTAssertNotNil(styleManager)
            return style?.styleType == StyleType.night
        }
        
        styleManager.applyStyle(type: .night)
        styleManager.applyStyle(type: .day)
        
        wait(for: [dayExpectation, nightExpectation], timeout: 5)
    }
}

extension StyleManagerTests: StyleManagerDelegate {
    public func styleManagerDidRefreshAppearance(_ styleManager: StyleManager) { }
    
    public func styleManager(_ styleManager: StyleManager, didApply style: Style) { }
    
    public func location(for styleManager: StyleManager) -> CLLocation? {
        return location
    }
}
