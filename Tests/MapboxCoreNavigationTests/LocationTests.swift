import XCTest
import CoreLocation
@testable import MapboxCoreNavigation
@testable import TestHelper

class LocationTests: TestCase {
    var setup: (progress: RouteProgress, firstLocation: CLLocation) {
        let progress = RouteProgress(route: makeRoute(), options: routeOptions)
        let firstCoord = progress.nearbyShape.coordinates.first!
        let firstLocation = CLLocation(latitude: firstCoord.latitude, longitude: firstCoord.longitude)
        
        return (progress, firstLocation)
    }
    
    func testSerializeAndDeserializeLocation() {
        let coordinate = CLLocationCoordinate2D(latitude: 1.1, longitude: 2.2)
        let altitude: CLLocationAccuracy = 3.3
        let speed: CLLocationSpeed = 4.4
        let horizontalAccuracy: CLLocationAccuracy = 5.5
        let verticalAccuracy: CLLocationAccuracy = 6.6
        let course: CLLocationDirection = 7.7
        let timestamp = Date()
        
        let location = CLLocation(coordinate: coordinate, altitude: altitude, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy, course: course, speed: speed, timestamp: timestamp)
        
        let encoded = try! JSONEncoder().encode(Location(location))
        let decoded = CLLocation(try! JSONDecoder().decode(Location.self, from: encoded))
        
        XCTAssertEqual(decoded.coordinate.latitude, coordinate.latitude)
        XCTAssertEqual(decoded.coordinate.longitude, coordinate.longitude)
        XCTAssertEqual(decoded.altitude, altitude)
        XCTAssertEqual(decoded.speed, speed)
        XCTAssertEqual(decoded.horizontalAccuracy, horizontalAccuracy)
        XCTAssertEqual(decoded.verticalAccuracy, verticalAccuracy)
        XCTAssertEqual(decoded.course, course)
        XCTAssertEqual(decoded.timestamp.timeIntervalSince1970, timestamp.timeIntervalSince1970, accuracy: 0.01)
    }
    
    func testSnappedLocation100MetersAlongRoute() {
        let progress = setup.progress
        let firstLocation = setup.firstLocation
        
        let initialHeadingOnFirstStep = progress.currentLegProgress.currentStep.finalHeading!
        let coordinateAlongFirstStep = firstLocation.coordinate.coordinate(at: 100, facing: initialHeadingOnFirstStep)
        let locationAlongFirstStep = CLLocation(latitude: coordinateAlongFirstStep.latitude, longitude: coordinateAlongFirstStep.longitude)
        guard let snapped = locationAlongFirstStep.snapped(to: progress) else {
            return XCTFail("Location should have snapped to route")
        }
        
        XCTAssertTrue(locationAlongFirstStep.distance(from: snapped) < 1, "The location is less than 1 meter away from the calculated snapped location")
    }
    
    func testInterpolatedCourse() {
        let progress = setup.progress
        let firstLocation = setup.firstLocation
        
        let calculatedCourse = firstLocation.interpolatedCourse(along: progress.currentLegProgress.currentStepProgress.step.shape!)!
        let initialHeadingOnFirstStep = progress.currentLegProgress.currentStepProgress.step.finalHeading!
        XCTAssertTrue(calculatedCourse - initialHeadingOnFirstStep < 1, "At the beginning of the route, the final heading of the departure step should be very similar to the caclulated course of the first location update.")
    }
    
    func testShouldSnap() {
        let progress = setup.progress
        let firstLocation = setup.firstLocation
        
        let initialHeadingOnFirstStep = progress.currentLegProgress.currentStepProgress.step.finalHeading!
        
        XCTAssertTrue(firstLocation.shouldSnap(toRouteWith: initialHeadingOnFirstStep), "Should snap")
        
        let differentCourseAndAccurateLocation = CLLocation(coordinate: firstLocation.coordinate, altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: 0, speed: 10, timestamp: Date())
        
        XCTAssertFalse(differentCourseAndAccurateLocation.shouldSnap(toRouteWith: initialHeadingOnFirstStep), "Should not snap when user course is different, the location is accurate and moving")
    }
}
