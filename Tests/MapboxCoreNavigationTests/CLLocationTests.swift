import XCTest
import CoreLocation
import TestHelper
@testable import MapboxCoreNavigation
@testable import MapboxNavigationNative

class CLLocationTests: TestCase {
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
                                      monotonicTimestampNanoseconds: Int64(timestamp.nanosecondsSince1970),
                                      time: timestamp,
                                      speed: speed as NSNumber,
                                      bearing: bearing as NSNumber,
                                      altitude: altitude as NSNumber,
                                      accuracyHorizontal: horizontalAccuracy as NSNumber,
                                      provider: nil,
                                      bearingAccuracy: bearingAccuracy as NSNumber,
                                      speedAccuracy: speedAccuracy as NSNumber,
                                      verticalAccuracy: verticalAccuracy as NSNumber,
                                      extras: [:],
                                      isMock: true)
        
        let location = CLLocation(fixLocation)
        
        XCTAssertEqual(location.coordinate.latitude, coordinate.latitude)
        XCTAssertEqual(location.coordinate.longitude, coordinate.longitude)
        XCTAssertEqual(location.coordinate, fixLocation.coordinate)
        XCTAssertEqual(location.timestamp.timeIntervalSince1970, fixLocation.time.timeIntervalSince1970,
                       accuracy: 1e-6)
        XCTAssertEqual(Int64(location.timestamp.nanosecondsSince1970), fixLocation.monotonicTimestampNanoseconds)
        XCTAssertEqual(location.speed, fixLocation.speed?.doubleValue)
        XCTAssertEqual(location.altitude, fixLocation.altitude?.doubleValue)
        XCTAssertEqual(location.horizontalAccuracy, fixLocation.accuracyHorizontal?.doubleValue)
        XCTAssertEqual(location.verticalAccuracy, fixLocation.verticalAccuracy?.doubleValue)
        XCTAssertEqual(location.course, fixLocation.bearing?.doubleValue)
        if #available(iOS 13.4, *) {
            XCTAssertEqual(location.speedAccuracy, fixLocation.speedAccuracy?.doubleValue)
            XCTAssertEqual(location.courseAccuracy, fixLocation.bearingAccuracy?.doubleValue)
        }
    }

    func testTimestampShiftForLocation() {
        let coordinate = CLLocationCoordinate2D(latitude: 1, longitude: 2)
        let timestamp = Date()
        let location = CLLocation(coordinate: coordinate,
                                  altitude: 10,
                                  horizontalAccuracy: 40,
                                  verticalAccuracy: 50,
                                  course: 180,
                                  speed: 18,
                                  timestamp: timestamp)
        
        let shiftedTimestamp = location.timestamp + 10
        XCTAssertEqual(shiftedTimestamp, location.shifted(to: shiftedTimestamp).timestamp)
    }
    
    func testCLLocationToFixLocation() {
        let coordinate = CLLocationCoordinate2D(latitude: 1, longitude: 2)
        let timestamp = Date()
        let speed: CLLocationSpeed = -1
        let bearing: CLLocationDegrees = -1
        let altitude: CLLocationDistance = -1
        let horizontalAccuracy: CLLocationAccuracy = -1
        let verticalAccuracy: CLLocationAccuracy = 1
        let bearingAccuracy: CLLocationAccuracy = 2
        let speedAccuracy: CLLocationAccuracy = 3

        var location = CLLocation(coordinate: coordinate,
                                  altitude: altitude,
                                  horizontalAccuracy: horizontalAccuracy,
                                  verticalAccuracy: verticalAccuracy,
                                  course: bearing,
                                  speed: speed,
                                  timestamp: timestamp)
        
        if #available(iOS 13.4, *) {
            location = CLLocation(coordinate: coordinate,
                                  altitude: altitude,
                                  horizontalAccuracy: horizontalAccuracy,
                                  verticalAccuracy: verticalAccuracy,
                                  course: bearing,
                                  courseAccuracy: bearingAccuracy,
                                  speed: speed,
                                  speedAccuracy: speedAccuracy,
                                  timestamp: timestamp)
        }
        #if compiler(>=5.5)
        if #available(iOS 15.0, *) {
            let sourceInfo = CLLocationSourceInformation(
                softwareSimulationState: true,
                andExternalAccessoryState: false
            )
            location = CLLocation(coordinate: coordinate,
                                  altitude: altitude,
                                  horizontalAccuracy: horizontalAccuracy,
                                  verticalAccuracy: verticalAccuracy,
                                  course: bearing,
                                  courseAccuracy: bearingAccuracy,
                                  speed: speed,
                                  speedAccuracy: speedAccuracy,
                                  timestamp: timestamp,
                                  sourceInfo: sourceInfo)
        }
        #endif

        let fixLocation = FixLocation(location)
        
        XCTAssertEqual(fixLocation.coordinate.latitude, coordinate.latitude)
        XCTAssertEqual(fixLocation.coordinate.longitude, coordinate.longitude)
        XCTAssertEqual(fixLocation.altitude, altitude as NSNumber)
        XCTAssertEqual(fixLocation.bearing, nil)
        XCTAssertEqual(fixLocation.accuracyHorizontal, nil)
        XCTAssertEqual(fixLocation.speed, nil)
        XCTAssertEqual(fixLocation.time, timestamp)
        XCTAssertEqual(fixLocation.verticalAccuracy?.doubleValue, verticalAccuracy)
        
        if #available(iOS 13.4, *) {
            XCTAssertEqual(fixLocation.bearingAccuracy?.doubleValue, bearingAccuracy)
            XCTAssertEqual(fixLocation.speedAccuracy?.doubleValue, speedAccuracy)
        }
        #if compiler(>=5.5)
        if #available(iOS 15.0, *) {
            XCTAssertEqual(fixLocation.provider, "sim:1,acc:0")
        }
        #endif
    }
}

