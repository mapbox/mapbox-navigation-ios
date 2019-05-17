import XCTest
@testable import MapboxNavigation


class CompassViewTests: XCTestCase {

    func testDirections() {
        let compassView = CarPlayCompassView()
        let min: CLLocationDirection = -720
        let max: CLLocationDirection = 720
        
        let allowedDirections = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        
        for direction in stride(from: min, to: max, by: 1) {
            compassView.course = direction
            XCTAssertTrue(allowedDirections.contains(compassView.label.text!))
        }
    }
}
