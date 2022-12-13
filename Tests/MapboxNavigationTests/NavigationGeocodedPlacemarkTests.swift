import XCTest
import CarPlay
import MapboxNavigation
import TestHelper

class NavigationGeocodedPlacemarkTests: TestCase {
    
    func testNavigationGeocodedPlacemarkListItem() {
        
        let title = "title"
        let subtitle = "subtitle"
        let navigationGeocodedPlacemark = NavigationGeocodedPlacemark(title: title,
                                                                      subtitle: subtitle,
                                                                      location: nil,
                                                                      routableLocations: nil)
        
        let listItem = navigationGeocodedPlacemark.listItem()
        XCTAssertEqual(listItem.text, title, "Titles should be equal.")
        XCTAssertEqual(listItem.detailText, subtitle, "Subtitles should be equal.")
        XCTAssertEqual(listItem.image, nil, "Image should not be set.")
    }
    
    func testNavigationGeocodedPlacemarkEncodingAndDecoding() {
        let coordinate = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        let altitude: CLLocationDistance = 1.0
        let horizontalAccuracy: CLLocationAccuracy = 2.0
        let verticalAccuracy: CLLocationAccuracy = 3.0
        let course: CLLocationDirection = 4.0
        let speed: CLLocationSpeed = 6.0
        let timestamp = Date()
        
        let location = CLLocation(coordinate: coordinate,
                                  altitude: altitude,
                                  horizontalAccuracy: horizontalAccuracy,
                                  verticalAccuracy: verticalAccuracy,
                                  course: course,
                                  speed: speed,
                                  timestamp: timestamp)
        
        let navigationGeocodedPlacemark = NavigationGeocodedPlacemark(title: "title",
                                                                      subtitle: "subtitle",
                                                                      location: location,
                                                                      routableLocations: [location])
        
        let navigationGeocodedPlacemarkData: Data!
        
        do {
            navigationGeocodedPlacemarkData = try JSONEncoder().encode(navigationGeocodedPlacemark)
        } catch {
            XCTFail("Failed to encode NavigationGeocodedPlacemark with error: \(error.localizedDescription)")
            return
        }
        
        XCTAssertNotNil(navigationGeocodedPlacemarkData, "Encoded data should be valid.")
        
        let decodedNavigationGeocodedPlacemark: NavigationGeocodedPlacemark!
        
        do {
            decodedNavigationGeocodedPlacemark = try JSONDecoder().decode(NavigationGeocodedPlacemark.self,
                                                                          from: navigationGeocodedPlacemarkData)
        } catch {
            XCTFail("Failed to decode NavigationGeocodedPlacemark with error: \(error.localizedDescription)")
            return
        }
        
        let decodedLocation = decodedNavigationGeocodedPlacemark.location
        
        XCTAssertEqual(navigationGeocodedPlacemark, decodedNavigationGeocodedPlacemark, "NavigationGeocodedPlacemark should be equal.")
        XCTAssertEqual(decodedLocation?.coordinate, coordinate, "Coordinates should be equal.")
        XCTAssertEqual(decodedLocation?.altitude, altitude, "Altitudes should be equal.")
        XCTAssertEqual(decodedLocation?.horizontalAccuracy, horizontalAccuracy, "Horizontal accuracies should be equal.")
        XCTAssertEqual(decodedLocation?.verticalAccuracy, verticalAccuracy, "Vertical accuracies should be equal.")
        XCTAssertEqual(decodedLocation?.course, course, "Courses should be equal.")
        XCTAssertEqual(decodedLocation?.speed, speed, "Speeds should be equal.")
        XCTAssertEqual(decodedLocation?.timestamp, timestamp, "Timestamps should be equal.")
        
        let decodedRoutableLocations = decodedNavigationGeocodedPlacemark.routableLocations
        
        XCTAssertEqual(decodedRoutableLocations?.count, 1, "There should be only one routable location.")
        XCTAssertEqual(decodedRoutableLocations?.first?.coordinate,
                       navigationGeocodedPlacemark.routableLocations?.first?.coordinate,
                       "Coordinates should be equal.")
    }
}
