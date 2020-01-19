import XCTest
import CoreLocation
@testable import MapboxCoreNavigation
@testable import MapboxNavigationNative

class CLLocationTests: XCTestCase {
    func testFixLocationToCLLocation() {
        let coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 1)
        let timestamp = Date()
        let speed: CLLocationSpeed = 18
        let bearing: CLLocationDegrees = 180
        let altitude: CLLocationDistance = 10
        let horizontalAccuracy: CLLocationAccuracy = 50
        
        let fixLocation = FixLocation(coordinate: coordinate, time: timestamp,
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
    
    func testCLLocationToMBFixLocation() {
        let coordinate = CLLocationCoordinate2D(latitude: 1, longitude: 2)
        let now = Date()
        
        let location = CLLocation(coordinate: coordinate,
                                  altitude: -1,
                                  horizontalAccuracy: -1,
                                  verticalAccuracy: 0,
                                  course: -1,
                                  speed: -1,
                                  timestamp: now)
        
        let fixLocation = FixLocation(location)
        
        XCTAssertEqual(fixLocation.coordinate.latitude, coordinate.latitude)
        XCTAssertEqual(fixLocation.coordinate.longitude, coordinate.longitude)
        XCTAssertEqual(fixLocation.altitude, -1)
        XCTAssertEqual(fixLocation.bearing, nil)
        XCTAssertEqual(fixLocation.accuracyHorizontal, nil)
        XCTAssertEqual(fixLocation.speed, nil)
        XCTAssertEqual(fixLocation.time, now)
    }
    
    func testMBFixLocationToCLLocation() {
        let coordinate = CLLocationCoordinate2D(latitude: 1, longitude: 2)
        let now = Date()
        let fixLocation = FixLocation(coordinate: coordinate,
                                        time: now,
                                        speed: nil,
                                        bearing: nil,
                                        altitude: -1,
                                        accuracyHorizontal: nil, provider: "default")
        
        let location = CLLocation(fixLocation)
        
        XCTAssertEqual(location.coordinate.latitude, 1)
        XCTAssertEqual(location.coordinate.longitude, 2)
        XCTAssertEqual(location.timestamp, now)
        XCTAssertEqual(location.speed, -1)
        XCTAssertEqual(location.course, -1)
        XCTAssertEqual(location.altitude, -1)
        XCTAssertEqual(location.horizontalAccuracy, -1)
    }
}

