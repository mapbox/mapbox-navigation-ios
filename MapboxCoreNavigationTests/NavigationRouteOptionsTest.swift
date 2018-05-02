import XCTest
import MapboxDirections
@testable import MapboxCoreNavigation

class NavigationRouteOptionsTests: XCTestCase {
    
    func testLocale() {
        
        let coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let options = NavigationRouteOptions(coordinates: [coordinate, coordinate])
        
        options.locale = Locale(identifier: "en-US")
        XCTAssertEqual(options.distanceMeasurementSystem, MeasurementSystem.metric)
    }
}
