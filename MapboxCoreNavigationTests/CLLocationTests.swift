import XCTest
import CoreLocation
@testable import MapboxCoreNavigation
import MapboxNavigationNative

class CLLocationTests: XCTestCase {
    
    func testFixLocationToCLLocation() {
        let coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 1)
        let timestamp = Date()
        let speed: CLLocationSpeed = 18
        let bearing: CLLocationDegrees = 180
        let altitude: CLLocationDistance = 10
        let horizontalAccuracy: CLLocationAccuracy = 50
        
        let fixLocation = MBFixLocation(coordinate: coordinate, time: timestamp,
                                        speed: speed as NSNumber, bearing: bearing as NSNumber,
                                        altitude: altitude as NSNumber, accuracyHorizontal: horizontalAccuracy as NSNumber, provider: nil)
        
        let location = CLLocation(fixLocation)
        
        XCTAssertEqual(location.coordinate, fixLocation.coordinate)
        XCTAssertEqual(location.timestamp, fixLocation.time)
        XCTAssertEqual(location.speed, fixLocation.speed?.doubleValue)
        XCTAssertEqual(location.altitude, fixLocation.altitude?.doubleValue)
        XCTAssertEqual(location.horizontalAccuracy, fixLocation.accuracyHorizontal?.doubleValue)
    }

    func testShiftLocation() {
        let coordinate = CLLocationCoordinate2D(latitude: 1, longitude: 2)
        let location = CLLocation(coordinate: coordinate, altitude: 10,
                                  horizontalAccuracy: 40,
                                  verticalAccuracy: 50,
                                  course: 180, speed: 18,
                                  timestamp: Date())
        
        XCTAssertEqual(location.timestamp, location.shifted(to: location.timestamp).timestamp)
    }
}

