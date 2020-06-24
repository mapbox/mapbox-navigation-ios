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
        let verticalAccuracy: CLLocationAccuracy = 50
        let speedAccuracy: CLLocationAccuracy = 25
        let bearingAccuracy: CLLocationAccuracy = 35
        
        let fixLocation = FixLocation(coordinate: coordinate,
                                      time: timestamp,
                                      speed: speed as NSNumber,
                                      bearing: bearing as NSNumber,
                                      altitude: altitude as NSNumber,
                                      accuracyHorizontal: horizontalAccuracy as NSNumber,
                                      provider: nil,
                                      bearingAccuracy: bearingAccuracy as NSNumber,
                                      speedAccuracy: speedAccuracy as NSNumber,
                                      verticalAccuracy: verticalAccuracy as NSNumber)
        
        let location = CLLocation(fixLocation)
        
        XCTAssertEqual(location.coordinate.latitude, coordinate.latitude)
        XCTAssertEqual(location.coordinate.longitude, coordinate.longitude)
        XCTAssertEqual(location.coordinate, fixLocation.coordinate)
        XCTAssertEqual(location.timestamp, fixLocation.time)
        XCTAssertEqual(location.speed, fixLocation.speed?.doubleValue)
        XCTAssertEqual(location.altitude, fixLocation.altitude?.doubleValue)
        XCTAssertEqual(location.horizontalAccuracy, fixLocation.accuracyHorizontal?.doubleValue)
        XCTAssertEqual(location.speedAccuracy, fixLocation.speedAccuracy?.doubleValue)
        XCTAssertEqual(location.verticalAccuracy, fixLocation.verticalAccuracy?.doubleValue)
        XCTAssertEqual(location.course, fixLocation.bearing?.doubleValue)
        if #available(iOS 13.4, *) {
            XCTAssertEqual(location.courseAccuracy, fixLocation.bearingAccuracy?.doubleValue)
        }
    }

    func testShiftLocation() {
        let coordinate = CLLocationCoordinate2D(latitude: 1, longitude: 2)
        let location = CLLocation(coordinate: coordinate,
                                  altitude: 10,
                                  horizontalAccuracy: 40,
                                  verticalAccuracy: 50,
                                  course: 180,
                                  speed: 18,
                                  timestamp: Date())
        
        XCTAssertEqual(location.timestamp, location.shifted(to: location.timestamp).timestamp)
    }
    
    func testCLLocationToFixLocation() {
        let coordinate = CLLocationCoordinate2D(latitude: 1, longitude: 2)
        let now = Date()
        
        var location = CLLocation(coordinate: coordinate,
                                  altitude: -1,
                                  horizontalAccuracy: -1,
                                  verticalAccuracy: 1,
                                  course: -1,
                                  speed: -1,
                                  timestamp: now)
        
        if #available(iOS 13.4, *) {
            location = CLLocation(coordinate: coordinate,
                                  altitude: -1,
                                  horizontalAccuracy: -1,
                                  verticalAccuracy: 1,
                                  course: -1,
                                  courseAccuracy: 2,
                                  speed: -1,
                                  speedAccuracy: 3,
                                  timestamp: now)
        }
        
        let fixLocation = FixLocation(location)
        
        XCTAssertEqual(fixLocation.coordinate.latitude, coordinate.latitude)
        XCTAssertEqual(fixLocation.coordinate.longitude, coordinate.longitude)
        XCTAssertEqual(fixLocation.altitude, -1)
        XCTAssertEqual(fixLocation.bearing, nil)
        XCTAssertEqual(fixLocation.accuracyHorizontal, nil)
        XCTAssertEqual(fixLocation.speed, nil)
        XCTAssertEqual(fixLocation.time, now)
        XCTAssertEqual(fixLocation.verticalAccuracy, 1)
        
        if #available(iOS 13.4, *) {
            XCTAssertEqual(fixLocation.bearingAccuracy, 2)
            XCTAssertEqual(fixLocation.speedAccuracy, 3)
        }
    }
}

