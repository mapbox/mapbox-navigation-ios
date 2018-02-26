import XCTest
import MapboxDirections
import Turf
@testable import MapboxCoreNavigation

class RouteControllerTests: XCTestCase {
    
    var setup: (routeController: RouteController, firstLocation: CLLocation) {
        route.accessToken = "foo"
        let navigation = RouteController(along: route, directions: directions)
        let firstCoord = navigation.routeProgress.currentLegProgress.nearbyCoordinates.first!
        return (routeController: navigation, firstLocation: CLLocation(latitude: firstCoord.latitude, longitude: firstCoord.longitude))
    }
    
    func testUserIsOnRoute() {
        let navigation = setup.routeController
        let firstLocation = setup.firstLocation
        
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [firstLocation])
        XCTAssertTrue(navigation.userIsOnRoute(firstLocation), "User should be on route")
    }
    
    func testUserIsOffRoute() {
        let navigation = setup.routeController
        let firstLocation = setup.firstLocation
        
        let coordinateOffRoute = firstLocation.coordinate.coordinate(at: 100, facing: 90)
        let locationOffRoute = CLLocation(latitude: coordinateOffRoute.latitude, longitude: coordinateOffRoute.longitude)
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [locationOffRoute])
        XCTAssertFalse(navigation.userIsOnRoute(locationOffRoute), "User should be off route")
    }
    
    func testAdvancingToFutureStepAndNotRerouting() {
        let navigation = setup.routeController
        let firstLocation = setup.firstLocation
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [firstLocation])
        XCTAssertTrue(navigation.userIsOnRoute(firstLocation), "User should be on route")
        XCTAssertEqual(navigation.routeProgress.currentLegProgress.stepIndex, 0, "User is on first step")
        
        let futureCoordinate = navigation.routeProgress.currentLegProgress.leg.steps[2].coordinates![10]
        let futureLocation = CLLocation(latitude: futureCoordinate.latitude, longitude: futureCoordinate.longitude)
        
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [futureLocation])
        XCTAssertTrue(navigation.userIsOnRoute(futureLocation), "User should be on route")
        
        XCTAssertEqual(navigation.routeProgress.currentLegProgress.stepIndex, 2, "User should be on route and we should increment all the way to the 4th step")
    }
    
    func testSnappedLocation() {
        let navigation = setup.routeController
        let firstLocation = setup.firstLocation
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [firstLocation])
        XCTAssertEqual(navigation.location!.coordinate, firstLocation.coordinate, "Check snapped location is working")
    }
    
    func testSnappedLocation100MetersAlongRoute() {
        let navigation = setup.routeController
        let firstLocation = setup.firstLocation
        
        let initialHeadingOnFirstStep = navigation.routeProgress.currentLegProgress.currentStep.finalHeading!
        let coordinateAlongFirstStep = firstLocation.coordinate.coordinate(at: 100, facing: initialHeadingOnFirstStep)
        let locationAlongFirstStep = CLLocation(latitude: coordinateAlongFirstStep.latitude, longitude: coordinateAlongFirstStep.longitude)
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [locationAlongFirstStep])
        XCTAssertTrue(locationAlongFirstStep.distance(from: navigation.location!) < 1, "The location update is less than 1 meter away from the calculated snapped location")
    }
    
    func testInterpolatedCourse() {
        let navigation = setup.routeController
        let firstLocation = setup.firstLocation
        
        let calculatedCourse = navigation.interpolatedCourse(from: firstLocation, along: navigation.routeProgress.currentLegProgress.currentStepProgress.step.coordinates!)!
        let initialHeadingOnFirstStep = navigation.routeProgress.currentLegProgress.currentStepProgress.step.finalHeading!
        XCTAssertTrue(calculatedCourse - initialHeadingOnFirstStep < 1, "At the beginning of the route, the final heading of the departure step should be very similar to the caclulated course of the first location update.")
    }
    
    func testShouldSnap() {
        let navigation = setup.routeController
        let firstLocation = setup.firstLocation
        let initialHeadingOnFirstStep = navigation.routeProgress.currentLegProgress.currentStepProgress.step.finalHeading!
        
        XCTAssertTrue(navigation.shouldSnap(firstLocation, toRouteWith: initialHeadingOnFirstStep), "Should snap")
        
        let differentCourseAndAccurateLocation = CLLocation(coordinate: firstLocation.coordinate, altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: 0, speed: 10, timestamp: Date())
        
        XCTAssertFalse(navigation.shouldSnap(differentCourseAndAccurateLocation, toRouteWith: initialHeadingOnFirstStep), "Should not snap when user course is different, the location is accurate and moving")
    }
}
