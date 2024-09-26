import CoreLocation
@testable import MapboxNavigationCore
import MapboxNavigationNative
import XCTest

final class FixLocationTests: XCTestCase {
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

        var location = CLLocation(
            coordinate: coordinate,
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            course: bearing,
            courseAccuracy: bearingAccuracy,
            speed: speed,
            speedAccuracy: speedAccuracy,
            timestamp: timestamp
        )

#if compiler(>=5.5)
        if #available(iOS 15.0, *) {
            let sourceInfo = CLLocationSourceInformation(
                softwareSimulationState: true,
                andExternalAccessoryState: false
            )
            location = CLLocation(
                coordinate: coordinate,
                altitude: altitude,
                horizontalAccuracy: horizontalAccuracy,
                verticalAccuracy: verticalAccuracy,
                course: bearing,
                courseAccuracy: bearingAccuracy,
                speed: speed,
                speedAccuracy: speedAccuracy,
                timestamp: timestamp,
                sourceInfo: sourceInfo
            )
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

        XCTAssertEqual(fixLocation.bearingAccuracy?.doubleValue, bearingAccuracy)
        XCTAssertEqual(fixLocation.speedAccuracy?.doubleValue, speedAccuracy)

#if compiler(>=5.5)
        if #available(iOS 15.0, *) {
            XCTAssertEqual(fixLocation.provider, "sim:1,acc:0")
        }
#endif
    }
}
