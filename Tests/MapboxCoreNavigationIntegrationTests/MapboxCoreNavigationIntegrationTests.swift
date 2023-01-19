import XCTest
import CoreLocation
import MapboxDirections
import Turf
import TestHelper
@testable import MapboxCoreNavigation

let jsonFileName = "routeWithInstructions"
let jsonFileNameEmptyDistance = "routeWithNoDistance"
var routeOptions: NavigationRouteOptions {
    let from = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165))
    let to = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))
    return NavigationRouteOptions(waypoints: [from, to])
}

let waitForInterval: TimeInterval = 5

func makeRouteResponse() -> RouteResponse {
    return Fixture.routeResponse(from: jsonFileName, options: routeOptions)
}

func makeRoute() -> Route {
    return Fixture.route(from: jsonFileName, options: routeOptions)
}

func makeRouteWithNoDistance() -> Route {
    return Fixture.route(from: jsonFileNameEmptyDistance, options: routeOptions)
}

class MapboxCoreNavigationIntegrationTests: TestCase {
    var navigation: MapboxNavigationService!
    var indexedRouteResponse: IndexedRouteResponse!
    var route: Route!
    var routeResponse: RouteResponse!

    override func setUp() {
        super.setUp()

        UserDefaults.standard.set("Location Usage Description", forKey: "NSLocationWhenInUseUsageDescription")
        UserDefaults.standard.set("Location Usage Description", forKey: "NSLocationAlwaysAndWhenInUseUsageDescription")
        routeResponse = makeRouteResponse()
        route = routeResponse.routes!.first!
        indexedRouteResponse = IndexedRouteResponse(routeResponse: routeResponse, routeIndex: 0)
    }
    
    override func tearDown() {
        Navigator.shared.rerouteController.reroutesProactively = true
        navigation = nil
        UserDefaults.resetStandardUserDefaults()

        super.tearDown()
    }
    
    func testNavigationNotificationsInfoDict() {
        navigation = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                             customRoutingProvider: MapboxRoutingProvider(.offline),
                                             credentials: Fixture.credentials,
                                             simulating: .never)
        let now = Date()
        let steps = route.legs.first!.steps
        let coordinates = steps[2].shape!.coordinates + steps[3].shape!.coordinates
        
        let locations = coordinates.enumerated().map {
            CLLocation(coordinate: $0.element,
                       altitude: -1,
                       horizontalAccuracy: 10,
                       verticalAccuracy: -1,
                       course: -1,
                       speed: 10,
                       timestamp: now + $0.offset)
        }
        
        let spokenTest = expectation(forNotification: .routeControllerDidPassSpokenInstructionPoint, object: navigation.router) { (note) -> Bool in
            return note.userInfo!.count == 2
        }
        spokenTest.expectationDescription = "Spoken Instruction notification expected to have user info dictionary with two values"
        
        navigation.start()
        
        for loc in locations {
            navigation.locationManager(navigation.locationManager, didUpdateLocations: [loc])
        }
        
        let location = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.78895, longitude: -122.42543),
                                  altitude: 1,
                                  horizontalAccuracy: 1,
                                  verticalAccuracy: 1,
                                  course: 171,
                                  speed: 10,
                                  timestamp: Date() + 4)
        
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [location])
        
        wait(for: [spokenTest], timeout: waitForInterval)
    }
    
    func testDepart() {
        navigation = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                             customRoutingProvider: MapboxRoutingProvider(.offline),
                                             credentials: Fixture.credentials,
                                             simulating: .never)
        Navigator.shared.rerouteController.reroutesProactively = false
        
        // Coordinates from first step
        let coordinates = route.legs[0].steps[0].shape!.coordinates
        let now = Date()
        let locations = coordinates.enumerated().map {
            CLLocation(coordinate: $0.element,
                       altitude: -1,
                       horizontalAccuracy: 10,
                       verticalAccuracy: -1,
                       course: -1,
                       speed: 10,
                       timestamp: now + $0.offset)
        }
        
        expectation(forNotification: .routeControllerDidPassSpokenInstructionPoint, object: navigation.router) { (notification) -> Bool in
            let routeProgress = notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress
            
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
        let steps = route.legs[0].steps
        // Create list of coordinates, which includes all coordinates in the first step and
        // first coordinate in the second step.
        var coordinates: [CLLocationCoordinate2D] = []
        if let firstStep = steps[0].shape, let secondStep = steps[1].shape {
            coordinates = firstStep.coordinates + secondStep.coordinates.prefix(1)
        }
        
        XCTAssertEqual(coordinates.count, 10, "Incorrect coordinates count.")
        let locationManager = ReplayLocationManager(locations: coordinates
                                                        .map { CLLocation(coordinate: $0) }
                                                        .shiftedToPresent())
        let navigationService = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                                        customRoutingProvider: MapboxRoutingProvider(.offline),
                                                        credentials: Fixture.credentials,
                                                        locationSource: locationManager,
                                                        simulating: .never)
        Navigator.shared.rerouteController.reroutesProactively = false
        
        var receivedSpokenInstructions: [String] = []
        
        let spokenInstructionExpectation = self.expectation(forNotification: .routeControllerDidPassSpokenInstructionPoint,
                                           object: navigationService.router) { (notification) -> Bool in
            let routeProgress = notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress
            
            guard let spokenInstruction = routeProgress?.currentLegProgress.currentStepProgress.currentSpokenInstruction?.text else {
                XCTFail("Spoken instruction should be valid.")
                return false
            }
            
            receivedSpokenInstructions.append(spokenInstruction)
            
            // Navigator always returns first spoken instruction for the second step.
            return routeProgress?.currentLegProgress.stepIndex == 1
        }

        locationManager.speedMultiplier = 10
        let replayFinished = expectation(description: "Replay finished")
        locationManager.replayCompletionHandler = { _ in
            replayFinished.fulfill()
            return false
        }
        navigationService.start()
        wait(for: [replayFinished, spokenInstructionExpectation], timeout: locationManager.expectedReplayTime)

        let expectedSpokenInstructions = [
            "Head south on Taylor Street, then turn right onto California Street",
            "Turn right onto California Street",
            "In a quarter mile, turn left onto Hyde Street"
        ]

        XCTAssertEqual(expectedSpokenInstructions, receivedSpokenInstructions, "Spoken instructions are not equal.")
    }
    
    func testJumpAheadToLastStep() {
        let coordinates = route.legs[0].steps.map { $0.shape!.coordinates }.flatMap { $0 }
        
        let now = Date()
        let locations = coordinates.enumerated().map {
            CLLocation(coordinate: $0.element,
                       altitude: -1,
                       horizontalAccuracy: -1,
                       verticalAccuracy: -1,
                       timestamp: now + $0.offset)
        }
        
        let locationManager = ReplayLocationManager(locations: locations)
        locationManager.speedMultiplier = 100
        navigation = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                             customRoutingProvider: MapboxRoutingProvider(.offline),
                                             credentials: Fixture.credentials,
                                             locationSource: locationManager,
                                             simulating: .never)
        Navigator.shared.rerouteController.reroutesProactively = false
        
        expectation(forNotification: .routeControllerDidPassSpokenInstructionPoint,
                    object: navigation.router) { (notification) -> Bool in
            let routeProgress = notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress
            return routeProgress?.currentLegProgress.stepIndex == 4
        }
        
        navigation.start()        
        waitForExpectations(timeout: waitForInterval) { (error) in
            XCTAssertNil(error)
        }
        navigation.stop()
    }
    
    func testShouldReroute() {
        let coordinates = route.legs[0].steps[1].shape!.coordinates
        let now = Date()
        let locations = coordinates.enumerated().map {
            CLLocation(coordinate: $0.element,
                       altitude: -1,
                       horizontalAccuracy: 10,
                       verticalAccuracy: -1,
                       course: -1,
                       speed: 10,
                       timestamp: now + $0.offset)
        }
        
        let offRouteCoordinates = [
            [-122.41765, 37.79095],
            [-122.41830, 37.79087],
            [-122.41907, 37.79079],
            [-122.41960, 37.79073]
        ].map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) }
        
        let offRouteLocations = offRouteCoordinates.enumerated().map {
            CLLocation(coordinate: $0.element,
                       altitude: -1,
                       horizontalAccuracy: 10,
                       verticalAccuracy: -1,
                       course: -1,
                       speed: 10,
                       timestamp: now + locations.count + $0.offset)
        }
        
        let locationManager = DummyLocationManager()
        navigation = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                             customRoutingProvider: MapboxRoutingProvider(.offline),
                                             credentials: Fixture.credentials,
                                             locationSource: locationManager,
                                             simulating: .never)
        expectation(forNotification: .routeControllerWillReroute, object: navigation.router) { (notification) -> Bool in
            XCTAssertEqual(notification.userInfo?.count, 1)
            
            let location = notification.userInfo![RouteController.NotificationUserInfoKey.locationKey] as! CLLocation
            // location is a map-matched location, so we don't know it in advance
            return offRouteLocations.first(where: { $0.distance(from: location) < 10 }) != nil
        }
        
        navigation.start()
        
        (locations + offRouteLocations).forEach {
            navigation.router.locationManager!(navigation.locationManager, didUpdateLocations: [$0])
        }
        
        waitForExpectations(timeout: waitForInterval) { (error) in
            XCTAssertNil(error)
        }
    }

    func testArrive() {
        let route = Fixture.route(from: "multileg-route", options: routeOptions)
        let replayLocations = Array(Fixture.generateTrace(for: route).shiftedToPresent().qualified()[0..<100])
        let routeResponse = RouteResponse(httpResponse: nil,
                                          routes: [route],
                                          options: .route(.init(locations: replayLocations, profileIdentifier: nil)),
                                          credentials: .mocked)

        let locationManager = ReplayLocationManager(locations: replayLocations)
        let speedMultiplier: TimeInterval = 50
        locationManager.speedMultiplier = speedMultiplier
        locationManager.startDate = Date()
        locationManager.startUpdatingLocation()

        navigation = MapboxNavigationService(indexedRouteResponse: IndexedRouteResponse(routeResponse: routeResponse,
                                                                                        routeIndex: 0),
                                             customRoutingProvider: MapboxRoutingProvider(.offline),
                                             credentials: Fixture.credentials,
                                             locationSource: locationManager,
                                             simulating: .never)
        navigation.router.refreshesRoute = false

        expectation(forNotification: .routeControllerProgressDidChange, object: navigation.router) { (notification) -> Bool in
            let routeProgress = notification.userInfo![RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress
            return routeProgress != nil
        }

        class Responder: NSObject, NavigationServiceDelegate {
            var willArriveExpectation: XCTestExpectation!
            var didArriveExpectation: XCTestExpectation!

            init(_ willArriveExpectation: XCTestExpectation, _ didArriveExpectation: XCTestExpectation) {
                self.willArriveExpectation = willArriveExpectation
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

        waitForExpectations(timeout: locationManager.expectedReplayTime, handler: nil)
        navigation.stop()
    }
    
    func testOrderOfExecution() {
        let trace = Fixture.generateTrace(for: route).shiftedToPresent().qualified()
        let locationManager = ReplayLocationManager(locations: trace)
        locationManager.speedMultiplier = 100

        navigation = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                             customRoutingProvider: MapboxRoutingProvider(.offline),
                                             credentials: Fixture.credentials,
                                             locationSource: locationManager)
        Navigator.shared.rerouteController.reroutesProactively = false
        navigation.router.refreshesRoute = false
        
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

        let spokenInstructionsExpectation = expectation(forNotification: .routeControllerDidPassSpokenInstructionPoint, object: navigation.router) { (notification) -> Bool in
            let routeProgress = notification.userInfo![RouteController.NotificationUserInfoKey.routeProgressKey] as! RouteProgress
            let legIndex = routeProgress.legIndex
            let stepIndex = routeProgress.currentLegProgress.stepIndex
            let spokenInstructionIndex = routeProgress.currentLegProgress.currentStepProgress.spokenInstructionIndex
            let visualInstructionIndex = routeProgress.currentLegProgress.currentStepProgress.visualInstructionIndex
            
            let point = InstructionPoint(type: .spoken,
                                         legIndex: legIndex,
                                         stepIndex: stepIndex,
                                         spokenInstructionIndex: spokenInstructionIndex,
                                         visualInstructionIndex: visualInstructionIndex)
            points.append(point)
            
            return true
        }

        let visualInstructionsExpectation = expectation(forNotification: .routeControllerDidPassVisualInstructionPoint, object: navigation.router) { (notification) -> Bool in
            let routeProgress = notification.userInfo![RouteController.NotificationUserInfoKey.routeProgressKey] as! RouteProgress
            let legIndex = routeProgress.legIndex
            let stepIndex = routeProgress.currentLegProgress.stepIndex
            let spokenInstructionIndex = routeProgress.currentLegProgress.currentStepProgress.spokenInstructionIndex
            let visualInstructionIndex = routeProgress.currentLegProgress.currentStepProgress.visualInstructionIndex
            
            let point = InstructionPoint(type: .visual,
                                         legIndex: legIndex,
                                         stepIndex: stepIndex,
                                         spokenInstructionIndex: spokenInstructionIndex,
                                         visualInstructionIndex: visualInstructionIndex)
            points.append(point)
            
            return true
        }
        let replayFinished = expectation(description: "Replay Finished")
        locationManager.replayCompletionHandler = { _ in
            replayFinished.fulfill()
            return false
        }

        locationManager.startUpdatingLocation()

        wait(for: [replayFinished, spokenInstructionsExpectation, visualInstructionsExpectation],
             timeout: locationManager.expectedReplayTime)
        
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
        locationManager.stopUpdatingLocation()
    }
    
    func testFailToReroute() {
        navigation = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                             customRoutingProvider: MapboxRoutingProvider(.online),
                                             credentials: Fixture.credentials,
                                             simulating: .never)
        
        expectation(forNotification: .routeControllerWillReroute, object: navigation.router) { (notification) -> Bool in
            return true
        }
        
        expectation(forNotification: .routeControllerDidFailToReroute, object: navigation.router) { (notification) -> Bool in
            return true
        }
        
        navigation.router.reroute(from: CLLocation(latitude: 0, longitude: 0), along: navigation.router.routeProgress)
        
        waitForExpectations(timeout: 2) { (error) in
            XCTAssertNil(error)
        }
    }
    
    func testNoUpdatesAfterFinishingRouting() {
        navigation = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                             customRoutingProvider: MapboxRoutingProvider(.offline),
                                             credentials: Fixture.credentials,
                                             simulating: .never)
        
        // Coordinates from first step
        let coordinates = route.legs[0].steps[0].shape!.coordinates
        let now = Date()
        let locations = coordinates.enumerated().map {
            CLLocation(coordinate: $0.element,
                       altitude: -1,
                       horizontalAccuracy: 10,
                       verticalAccuracy: -1,
                       course: -1,
                       speed: 10,
                       timestamp: now + $0.offset)
        }
        
        var hasFinishedRouting = false
        expectation(forNotification: .routeControllerProgressDidChange, object: navigation.router) { _ in
            return hasFinishedRouting
        }.isInverted = true
        expectation(forNotification: .routeControllerWillReroute, object: navigation.router) { _ in
            return hasFinishedRouting
        }.isInverted = true
        expectation(forNotification: .routeControllerDidReroute, object: navigation.router) { _ in
            return hasFinishedRouting
        }.isInverted = true
        
        let routerDelegateSpy = RouterDelegateSpy()
        navigation.router.delegate = routerDelegateSpy
        
        routerDelegateSpy.onShouldDiscard = { _ in
            if hasFinishedRouting {
                XCTFail("Location updates should not be tracked.")
            }
            return false
        }
        
        navigation.start()
        
        for location in locations {
            navigation.locationManager(navigation.locationManager, didUpdateLocations: [location])
            
            if !hasFinishedRouting {
                navigation.router.finishRouting()
                hasFinishedRouting = true

                navigation.updateRoute(with: IndexedRouteResponse(routeResponse: routeResponse,
                                                                  routeIndex: 0),
                                       routeOptions: nil,
                                       completion: nil)
            }
        }
        
        waitForExpectations(timeout: waitForInterval) { (error) in
            XCTAssertNil(error)
        }
    }

    func testAmenitiesReporting() {
        let routeOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 35.8112, longitude: 140.397245),
            CLLocationCoordinate2D(latitude: 35.814847, longitude: 140.409267)
        ])
        
        // There is one leg and two steps in the route. Only first step contains rest stop with amenities.
        // In scope of this test perform simulation of the location changes only for the first step and
        // verify whether amenities are correctly retrieved from the Navigation Native status.
        let routeResponse = Fixture.routeResponse(from: "route-with-amenities", options: routeOptions)
        
        guard let coordinates = route.legs.first?.steps.first?.shape?.coordinates else {
            XCTFail("Coordinates should be valid.")
            return
        }
        
        let currentDate = Date()
        
        let locations = coordinates.enumerated().map {
            CLLocation(coordinate: $0.element,
                       altitude: -1,
                       horizontalAccuracy: 10,
                       verticalAccuracy: -1,
                       course: -1,
                       speed: 10,
                       timestamp: currentDate + $0.offset)
        }
        
        let replayLocationManager = ReplayLocationManager(locations: locations)
        replayLocationManager.speedMultiplier = 100
        
        navigation = MapboxNavigationService(indexedRouteResponse: IndexedRouteResponse(routeResponse: routeResponse, routeIndex: 0),
                                             credentials: Fixture.credentials,
                                             locationSource: replayLocationManager,
                                             simulating: .never)
        
        let routeControllerProgressExpectation = expectation(forNotification: .routeControllerProgressDidChange,
                                                             object: navigation.router) { notification -> Bool in
            guard let routeProgress = notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress,
                  let intersections = routeProgress.currentLegProgress.currentStep.intersections,
                  intersections.count == 6,
                  let restStop = intersections[4].restStop,
                  let amenities = restStop.amenities,
                  amenities.count == 7 else {
                return false
            }
            
            XCTAssertEqual(amenities[0].type, .toilet)
            XCTAssertNil(amenities[0].name)
            XCTAssertNil(amenities[0].brand)
            
            XCTAssertEqual(amenities[6].type, .telephone)
            XCTAssertEqual(amenities[6].name, "test_name")
            XCTAssertEqual(amenities[6].brand, "test_brand")
            
            return true
        }
        
        navigation.start()
        
        for location in locations {
            navigation.locationManager(navigation.locationManager, didUpdateLocations: [location])
        }
        
        wait(for: [routeControllerProgressExpectation], timeout: waitForInterval)
    }
}
