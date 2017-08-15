import XCTest
import CoreLocation
@testable import MapboxCoreNavigation

class LocationTests: XCTestCase {
    
    func testSerializeAndDeserializeLocation() {
        let coordinate = CLLocationCoordinate2D(latitude: 1.1, longitude: 2.2)
        let altitude: CLLocationAccuracy = 3.3
        let speed: CLLocationSpeed = 4.4
        let horizontalAccuracy: CLLocationAccuracy = 5.5
        let verticalAccuracy: CLLocationAccuracy = 6.6
        let course: CLLocationDirection = 7.7
        let timestamp = Date().ISO8601
        
        var locationDictionary:[String: Any] = [:]
        locationDictionary["lat"] = coordinate.latitude
        locationDictionary["lng"] = coordinate.longitude
        locationDictionary["altitude"] = altitude
        locationDictionary["timestamp"] = timestamp
        locationDictionary["horizontalAccuracy"] = horizontalAccuracy
        locationDictionary["verticalAccuracy"] = verticalAccuracy
        locationDictionary["course"] = course
        locationDictionary["speed"] = speed
        
        let location = CLLocation(dictionary: locationDictionary)
        
        let lhs = locationDictionary as NSDictionary
        let rhs = location.dictionaryRepresentation as NSDictionary
        
        XCTAssert(lhs == rhs)
    }
    
}
