import XCTest
import CoreLocation
import Turf
@testable import MapboxCoreNavigation

class LocationTests: XCTestCase {
    
    var setup: (progress: RouteProgress, firstLocation: CLLocation) {
        let progress = RouteProgress(route: route)
        let firstCoord = progress.currentLegProgress.nearbyCoordinates.first!
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
    
    func testSnappedLocationShouldBeInFrontOfUser() {
        let progress = setup.progress
        
        let initialHeadingOnFirstStep = progress.currentLegProgress.currentStep.finalHeading!
        let coordinateAlongFirstStep = Polyline(progress.currentLegProgress.nearbyCoordinates).coordinateFromStart(distance: 100)!
        let locationAlongFirstStep = CLLocation(coordinate: coordinateAlongFirstStep, altitude: 0, horizontalAccuracy: 1, verticalAccuracy: 0, course: initialHeadingOnFirstStep, speed: 10, timestamp: Date())
        guard let snapped = locationAlongFirstStep.snapped(to: progress.currentLegProgress) else {
            return XCTFail("Location should have snapped to route")
        }
        
        let distanceBetweenRealAndSnappedLocation = locationAlongFirstStep.distance(from: snapped)
    

        XCTAssertEqual(round(distanceBetweenRealAndSnappedLocation), 10, "The snapped location is 10 meters ahead of the user because they are moving.")
 
    }
    
    func testInterpolatedCourse() {
        let progress = setup.progress
        let firstLocation = setup.firstLocation
        
        let calculatedCourse = firstLocation.interpolatedCourse(along: progress.currentLegProgress.currentStepProgress.step.coordinates!)!
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
