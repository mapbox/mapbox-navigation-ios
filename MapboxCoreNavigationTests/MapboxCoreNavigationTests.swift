import XCTest
import MapboxDirections
import Turf
import TestHelper
@testable import MapboxCoreNavigation

let jsonFileName = "routeWithInstructions"
var routeOptions: NavigationRouteOptions {
    let from = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165))
    let to = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))
    return NavigationRouteOptions(waypoints: [from, to])
}
let response = Fixture.routeResponse(from: jsonFileName, options: routeOptions)
let directions = DirectionsSpy()
let route: Route = {
    return Fixture.route(from: jsonFileName, options: routeOptions)
}()

let waitForInterval: TimeInterval = 5

class MapboxCoreNavigationTests: XCTestCase {
    var navigation: MapboxNavigationService!
    
    func testNavigationNotificationsInfoDict() {
        navigation = MapboxNavigationService(route: route, routeIndex: 0, routeOptions: routeOptions, directions: directions, simulating: .never)
        let now = Date()
        let steps = route.legs.first!.steps
        let coordinates = steps[2].shape!.coordinates + steps[3].shape!.coordinates
        
        let locations = coordinates.enumerated().map { CLLocation(coordinate: $0.element,
                                                                  altitude: -1, horizontalAccuracy: 10,
                                                                  verticalAccuracy: -1, course: -1, speed: 10,
                                                                  timestamp: now + $0.offset) }
        
        let spokenTest = expectation(forNotification: .routeControllerDidPassSpokenInstructionPoint, object: navigation.router) { (note) -> Bool in
            return note.userInfo!.count == 2
        }
        spokenTest.expectationDescription = "Spoken Instruction notification expected to have user info dictionary with two values"
        
        navigation.start()
        
        for loc in locations {
            navigation.locationManager(navigation.locationManager, didUpdateLocations: [loc])
        }
        
        let location = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.78895, longitude: -122.42543), altitude: 1, horizontalAccuracy: 1, verticalAccuracy: 1, course: 171, speed: 10, timestamp: Date() + 4)
        
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [location])
        
        wait(for: [spokenTest], timeout: waitForInterval)
    }
    
    func testDepart() {
        navigation = MapboxNavigationService(route: route, routeIndex: 0, routeOptions: routeOptions, directions: directions, simulating: .never)
        
        // Coordinates from first step
        let coordinates = route.legs[0].steps[0].shape!.coordinates
        let now = Date()
        let locations = coordinates.enumerated().map { CLLocation(coordinate: $0.element,
                                                                  altitude: -1, horizontalAccuracy: 10,
                                                                  verticalAccuracy: -1, course: -1, speed: 10,
                                                                  timestamp: now + $0.offset) }
        
        expectation(forNotification: .routeControllerDidPassSpokenInstructionPoint, object: navigation.router) { (notification) -> Bool in
            let routeProgress = notification.userInfo![RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress
            
            return routeProgress != nil && routeProgress?.currentLegProgress.userHasArrivedAtWaypoint == false
        }
        
        navigation.start()
        
        for location in locations {
            navigation.locationManager(navigation.locationManager, didUpdateLocations: [location])
        }
        
        waitForExpectations(timeout: waitForInterval) { (error) in
            XCTAssertNil(error)
        }
    }
    
    func testNewStep() {
        // Coordinates from beginning of step[1] to end of step[2]
        let coordinates = route.legs[0].steps[1].shape!.coordinates + route.legs[0].steps[2].shape!.coordinates
        let locations: [CLLocation]
        let now = Date()
        locations = coordinates.enumerated().map { CLLocation(coordinate: $0.element,
                                                              altitude: -1, horizontalAccuracy: -1, verticalAccuracy: -1, course: -1, speed: 10,
                                                              timestamp: now + $0.offset) }
        
        navigation = MapboxNavigationService(route: route, routeIndex: 0, routeOptions: routeOptions, directions: directions, simulating: .never)
        expectation(forNotification: .routeControllerDidPassSpokenInstructionPoint, object: navigation.router) { (notification) -> Bool in
            let routeProgress = notification.userInfo![RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress
            
            return routeProgress?.currentLegProgress.stepIndex == 2
        }
        
        navigation.start()
        
        locations.forEach { navigation.router!.locationManager!(navigation.locationManager, didUpdateLocations: [$0])}
        
        waitForExpectations(timeout: waitForInterval) { (error) in
            XCTAssertNil(error)
        }
    }
    
    func testJumpAheadToLastStep() {
        let coordinates = route.legs[0].steps.map { $0.shape!.coordinates }.flatMap { $0 }
        
        let now = Date()
        let locations = coordinates.enumerated().map { CLLocation(coordinate: $0.element, altitude: -1, horizontalAccuracy: -1, verticalAccuracy: -1, timestamp: now + $0.offset) }
        
        let locationManager = ReplayLocationManager(locations: locations)
        navigation = MapboxNavigationService(route: route, routeIndex: 0, routeOptions: routeOptions, directions: directions, locationSource: locationManager, simulating: .never)
        
        expectation(forNotification: .routeControllerDidPassSpokenInstructionPoint, object: navigation.router) { (notification) -> Bool in
            let routeProgress = notification.userInfo![RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress
            return routeProgress?.currentLegProgress.stepIndex == 4
        }
        
        navigation.start()
        
        locations.forEach { navigation.router!.locationManager!(navigation.locationManager, didUpdateLocations: [$0]) }
        
        waitForExpectations(timeout: waitForInterval) { (error) in
            XCTAssertNil(error)
        }
    }
    
    func testShouldReroute() {
        let coordinates = route.legs[0].steps[1].shape!.coordinates
        let now = Date()
        let locations = coordinates.enumerated().map { CLLocation(coordinate: $0.element,
                                                                  altitude: -1, horizontalAccuracy: 10, verticalAccuracy: -1, course: -1, speed: 10, timestamp: now + $0.offset) }
        
        let offRouteCoordinates = [[-122.41765, 37.79095],[-122.41830,37.79087],[-122.41907,37.79079],[-122.41960,37.79073]]
            .map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) }
        
        let offRouteLocations = offRouteCoordinates.enumerated().map {
            CLLocation(coordinate: $0.element, altitude: -1, horizontalAccuracy: 10,
                       verticalAccuracy: -1, course: -1, speed: 10,
                       timestamp: now + locations.count + $0.offset)
        }
        
        let locationManager = ReplayLocationManager(locations: locations + offRouteLocations)
        navigation = MapboxNavigationService(route: route, routeIndex: 0, routeOptions: routeOptions, directions: directions, locationSource: locationManager, simulating: .never)
        expectation(forNotification: .routeControllerWillReroute, object: navigation.router) { (notification) -> Bool in
            XCTAssertEqual(notification.userInfo?.count, 1)
            
            let location = notification.userInfo![RouteController.NotificationUserInfoKey.locationKey] as? CLLocation
            return location?.coordinate == offRouteLocations[1].coordinate
        }
        
        navigation.start()
        
        (locations + offRouteLocations).forEach {
            navigation.router!.locationManager!(navigation.locationManager, didUpdateLocations: [$0])
        }
        
        waitForExpectations(timeout: waitForInterval) { (error) in
            XCTAssertNil(error)
        }
    }
    
    func testArrive() {
        let now = Date()
        let locations = Fixture.generateTrace(for: route).enumerated().map {
            $0.element.shifted(to: now + $0.offset)
        }

        let locationManager = DummyLocationManager()
        navigation = MapboxNavigationService(route: route, routeIndex: 0, routeOptions: routeOptions, directions: directions, locationSource: locationManager, simulating: .never)

        expectation(forNotification: .routeControllerProgressDidChange, object: navigation.router) { (notification) -> Bool in
            let routeProgress = notification.userInfo![RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress
            return routeProgress != nil
        }

        class Responder: NSObject, NavigationServiceDelegate {
            var willArriveExpectation: XCTestExpectation!
            var didArriveExpectation: XCTestExpectation!

            init(_ willArriveExpectation: XCTestExpectation, _ didArriveExpectation: XCTestExpectation) {
                self.willArriveExpectation = willArriveExpectation
                // TODO: remove next line (fulfill) when willArrive works properly
                self.willArriveExpectation.fulfill()
                self.didArriveExpectation = didArriveExpectation
            }

            func navigationService(_ service: NavigationService, willArriveAt waypoint: Waypoint, after remainingTimeInterval: TimeInterval, distance: CLLocationDistance) {
                willArriveExpectation.fulfill()
            }

            func navigationService(_ service: NavigationService, didArriveAt waypoint: Waypoint) -> Bool {
                didArriveExpectation.fulfill()
                return true
            }
        }

        let willArriveExpectation = expectation(description: "navigationService(_:willArriveAt:after:distance:) must trigger")
        let didArriveExpectation = expectation(description: "navigationService(_:didArriveAt:) must trigger once")
        willArriveExpectation.assertForOverFulfill = false

        let responder = Responder(willArriveExpectation, didArriveExpectation)
        navigation.delegate = responder
        navigation.start()

        for location in locations {
            navigation.locationManager(locationManager, didUpdateLocations: [location])
        }

        self.waitForExpectations(timeout: 5) { (error) in
            XCTAssertNil(error)
        }
    }
    
    func testOrderOfExecution() {
        let trace = Fixture.generateTrace(for: route).shiftedToPresent().qualified()
        let directions = DirectionsSpy()
        navigation = MapboxNavigationService(route: route, routeIndex: 0, routeOptions: routeOptions, directions: directions)
        
        struct InstructionPoint {
            enum InstructionType {
                case visual, spoken
            }
            
            let type: InstructionType
            let legIndex: Int
            let stepIndex: Int
            let spokenInstructionIndex: Int
            let visualInstructionIndex: Int
        }
        
        var points = [InstructionPoint]()
        
        expectation(forNotification: .routeControllerDidPassSpokenInstructionPoint, object: nil) { (notification) -> Bool in
            let routeProgress = notification.userInfo![RouteController.NotificationUserInfoKey.routeProgressKey] as! RouteProgress
            let legIndex = routeProgress.legIndex
            let stepIndex = routeProgress.currentLegProgress.stepIndex
            let spokenInstructionIndex = routeProgress.currentLegProgress.currentStepProgress.spokenInstructionIndex
            let visualInstructionIndex = routeProgress.currentLegProgress.currentStepProgress.visualInstructionIndex
            
            let point = InstructionPoint(type: .spoken, legIndex: legIndex, stepIndex: stepIndex, spokenInstructionIndex: spokenInstructionIndex, visualInstructionIndex: visualInstructionIndex)
            points.append(point)
            
            return true
        }
        
        expectation(forNotification: .routeControllerDidPassVisualInstructionPoint, object: nil) { (notification) -> Bool in
            let routeProgress = notification.userInfo![RouteController.NotificationUserInfoKey.routeProgressKey] as! RouteProgress
            let legIndex = routeProgress.legIndex
            let stepIndex = routeProgress.currentLegProgress.stepIndex
            let spokenInstructionIndex = routeProgress.currentLegProgress.currentStepProgress.spokenInstructionIndex
            let visualInstructionIndex = routeProgress.currentLegProgress.currentStepProgress.visualInstructionIndex
            
            let point = InstructionPoint(type: .visual, legIndex: legIndex, stepIndex: stepIndex, spokenInstructionIndex: spokenInstructionIndex, visualInstructionIndex: visualInstructionIndex)
            points.append(point)
            
            return true
        }
        
        for location in trace {
            navigation.router!.locationManager!(navigation.locationManager, didUpdateLocations: [location])
        }
        
        waitForExpectations(timeout: 2) { (error) in
            XCTAssertNil(error)
        }
        
        if points.isEmpty {
            XCTFail()
            return
        }
        
        XCTAssertEqual(points[0].legIndex, 0)
        XCTAssertEqual(points[0].stepIndex, 0)
        XCTAssertEqual(points[0].visualInstructionIndex, 0)
        XCTAssertEqual(points[0].spokenInstructionIndex, 0)
        XCTAssertEqual(points[0].type, .spoken)
        
        XCTAssertEqual(points[1].legIndex, 0)
        XCTAssertEqual(points[1].stepIndex, 0)
        XCTAssertEqual(points[1].visualInstructionIndex, 0)
        XCTAssertEqual(points[1].spokenInstructionIndex, 0)
        XCTAssertEqual(points[1].type, .visual)
        
        XCTAssertEqual(points[2].legIndex, 0)
        XCTAssertEqual(points[2].stepIndex, 0)
        XCTAssertEqual(points[2].visualInstructionIndex, 0)
        XCTAssertEqual(points[2].spokenInstructionIndex, 1)
        XCTAssertEqual(points[2].type, .spoken)
        
        XCTAssertEqual(points[3].legIndex, 0)
        XCTAssertEqual(points[3].stepIndex, 1)
        XCTAssertEqual(points[3].visualInstructionIndex, 0)
        XCTAssertEqual(points[3].spokenInstructionIndex, 0)
        XCTAssertEqual(points[3].type, .spoken)
        
        // Make sure we never have unsynced indexes or move backward in time by comparing previous to current instruction point
        let zippedPoints = zip(points, points.suffix(from: 1))
        
        for seq in zippedPoints {
            let previous = seq.0
            let current = seq.1
            
            let sameStepAndLeg = previous.legIndex == current.legIndex && previous.stepIndex == current.stepIndex
            
            if sameStepAndLeg {
                XCTAssert(current.visualInstructionIndex >= previous.visualInstructionIndex)
                XCTAssert(current.spokenInstructionIndex >= previous.spokenInstructionIndex)
            } else {
                XCTAssert(current.visualInstructionIndex == 0)
                XCTAssert(current.spokenInstructionIndex == 0)
            }
        }
    }
    
    func testFailToReroute() {
        let directionsClientSpy = DirectionsSpy()
        navigation = MapboxNavigationService(route: route, routeIndex: 0, routeOptions: routeOptions, directions: directionsClientSpy,  simulating: .never)
        
        expectation(forNotification: .routeControllerWillReroute, object: navigation.router) { (notification) -> Bool in
            return true
        }
        
        expectation(forNotification: .routeControllerDidFailToReroute, object: navigation.router) { (notification) -> Bool in
            return true
        }
        
        navigation.router.reroute(from: CLLocation(latitude: 0, longitude: 0), along: navigation.router.routeProgress)
        directionsClientSpy.fireLastCalculateCompletion(with: nil, routes: nil, error: .profileNotFound)
        
        waitForExpectations(timeout: 2) { (error) in
            XCTAssertNil(error)
        }
    }
}
