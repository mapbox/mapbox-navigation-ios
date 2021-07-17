import XCTest
import CoreLocation
import TestHelper
@testable import MapboxNavigation

class CarPlayCompassViewTests: TestCase {
    func testCarPlayCompassViewDirections() {
        let compassView = CarPlayCompassView()
        let min: CLLocationDirection = -720
        let max: CLLocationDirection = 720
        
        let allowedDirections = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        
        for direction in stride(from: min, to: max, by: 1) {
            compassView.course = direction
            
            guard let text = compassView.label.text else {
                XCTFail("CompassView label text is not valid.")
                return
            }
            
            XCTAssertTrue(allowedDirections.contains(text))
        }
    }
}
