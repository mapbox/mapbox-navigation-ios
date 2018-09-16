import XCTest
@testable import MapboxNavigation
#if canImport(CarPlay)
import CarPlay

@available(iOS 12.0, *)
class CPMapTemplateTests: XCTestCase {
    func testInitializationFromPanDirection() {
        XCTAssertEqual(CLLocationDirection(panDirection: .up), 0)
        XCTAssertEqual(CLLocationDirection(panDirection: .right), 90)
        XCTAssertEqual(CLLocationDirection(panDirection: .down), 180)
        XCTAssertEqual(CLLocationDirection(panDirection: .left), 270)
        
        XCTAssertEqual(CLLocationDirection(panDirection: [.up, .left]), 360 - 45)
        XCTAssertEqual(CLLocationDirection(panDirection: [.up, .right]), 45)
        
        XCTAssertEqual(CLLocationDirection(panDirection: [.down, .left]), 180 + 45)
        XCTAssertEqual(CLLocationDirection(panDirection: [.down, .right]), 180 - 45)
        
        XCTAssertNil(CLLocationDirection(panDirection: []))
    }
}
#endif
