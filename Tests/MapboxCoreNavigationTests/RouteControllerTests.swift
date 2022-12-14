import XCTest
import Turf
import MapboxDirections
import CoreLocation
@testable import MapboxCoreNavigation
import TestHelper
import MapboxNavigationNative
@_implementationOnly import MapboxCommon_Private
@_implementationOnly import MapboxNavigationNative_Private

class RouteControllerTests: TestCase {
    private let expectationsTimeout = 0.5
    
    private var locationManagerSpy: NavigationLocationManagerSpy!
    private var navigatorSpy: CoreNavigatorSpy!
    private var nativeNavigatorSpy: NativeNavigatorSpy!
    private var routingProvider: RoutingProviderSpy!
    private var delegate: RouterDelegateSpy!
    private var indexedRouteResponse: IndexedRouteResponse!
    private var rerouteController: RerouteControllerSpy!
    private var dataSource: RouterDataSourceSpy!
    private var routeProgress: RouteProgress!
    private var nativeRoute: RouteInterface!
    
    private var routeController: RouteController!

    private var routeResponse: RouteResponse!
    private var singleRouteResponse: RouteResponse!
    private var multilegRouteResponse: RouteResponse!
    
    private let rawLocation = CLLocation(latitude: 47.208674, longitude: 9.524650)
    private var locationWithDate: CLLocation {
        let coordinate = CLLocationCoordinate2D(latitude: 59.337928, longitude: 18.076841)
        return CLLocation(coordinate: coordinate,
                          altitude: 0,
                          horizontalAccuracy: 0,
                          verticalAccuracy: 0,
                          timestamp: Date())
    }

    private var options: RouteOptions {
        let from = Waypoint(coordinate: .init(latitude: 37.33243586131637, longitude: -122.03140541047281))
        let to = Waypoint(coordinate: .init(latitude: 37.33318065375225, longitude: -122.03148874952787))
        let options = RouteOptions(waypoints: [from, to])
        options.shapeFormat = .geoJSON
        return options
    }

    private var bannerInstruction: BannerInstruction {
        let bannerSection = BannerSection(text: "", type: nil, modifier: nil, degrees: nil, drivingSide: nil, components: nil)
        return BannerInstruction(primary: bannerSection,
                                 view: nil,
                                 secondary: nil,
                                 sub: nil,
                                 remainingStepDistance: 10,
                                 index: 6)
    }

    private var route: Route {
        return routeResponse.routes![0]
    }
    
    override func setUp() {
        super.setUp()

        delegate = .init()
        locationManagerSpy = .init()
        routingProvider = .init()
        navigatorSpy = CoreNavigatorSpy.shared
        nativeNavigatorSpy = navigatorSpy.navigatorSpy
        rerouteController = CoreNavigatorSpy.shared.rerouteController as? RerouteControllerSpy
        dataSource = .init()
        routingProvider = .init()
        routeResponse = makeRouteResponse()
        indexedRouteResponse = IndexedRouteResponse(routeResponse: routeResponse, routeIndex: 0)
        routeProgress = .init(route: routeResponse.routes![0], options: options)
        nativeRoute = TestRouteProvider.createRoute(routeResponse: makeRouteResponse())

        singleRouteResponse = makeSingleRouteResponse()
        multilegRouteResponse = makeMultilegRouteResponse()

        routeController = makeRouteController()
        routeController.delegate = delegate
    }
    
    override func tearDown() {
        delegate = nil
        routeController = nil
        RouteParserSpy.returnedRoutes = nil
        RouteParserSpy.returnedError = nil
        MapboxRoutingProvider.__testRoutesStub = nil
        
        super.tearDown()
    }

    func testConfigureInstance() {
        let controller = RouteController(indexedRouteResponse: indexedRouteResponse,
                                         customRoutingProvider: routingProvider,
                                         dataSource: dataSource)
        XCTAssertEqual(controller.indexedRouteResponse.currentRoute, indexedRouteResponse.currentRoute)
        XCTAssertTrue(controller.dataSource === dataSource)
        XCTAssertEqual(controller.routeProgress.legIndex, 0)
    }

    func testConfigureRefreshesRoute() {
        indexedRouteResponse.validatedRouteOptions.refreshingEnabled = true
        indexedRouteResponse.validatedRouteOptions.profileIdentifier = .automobileAvoidingTraffic
        let controller1 = RouteController(indexedRouteResponse: indexedRouteResponse,
                                          customRoutingProvider: routingProvider,
                                          dataSource: dataSource)
        XCTAssertTrue(controller1.refreshesRoute, "Should refresh for automobileAvoidingTraffic")

        indexedRouteResponse.validatedRouteOptions.profileIdentifier = .automobile
        let controller2 = RouteController(indexedRouteResponse: indexedRouteResponse,
                                          customRoutingProvider: routingProvider,
                                          dataSource: dataSource)
        XCTAssertFalse(controller2.refreshesRoute, "Should not refresh for automobile")
    }
    
    func testReturnIsFirstLocation() {
        XCTAssertTrue(routeController.isFirstLocation)
        routeController.rawLocation = CLLocation(latitude: 59.337928, longitude: 18.076841)
        XCTAssertFalse(routeController.isFirstLocation)
    }
    
    func testReturnSnappedLocation() {
        XCTAssertNil(routeController.snappedLocation)
        
        routeController.rawLocation = CLLocation(latitude: 59.337928, longitude: 18.076841)
        XCTAssertNil(routeController.snappedLocation)
        
        routeController.rawLocation = self.locationWithDate
        XCTAssertNil(routeController.snappedLocation)
        
        navigatorSpy.mostRecentNavigationStatus = TestNavigationStatusProvider.createNavigationStatus(routeState: .invalid)
        XCTAssertNil(routeController.snappedLocation)
        
        navigatorSpy.mostRecentNavigationStatus = TestNavigationStatusProvider.createNavigationStatus(routeState: .tracking)
        XCTAssertEqual(routeController.snappedLocation?.coordinate, navigatorSpy.mostRecentNavigationStatus?.location.coordinate)
        
        navigatorSpy.mostRecentNavigationStatus = TestNavigationStatusProvider.createNavigationStatus(routeState: .complete)
        XCTAssertEqual(routeController.snappedLocation?.coordinate, navigatorSpy.mostRecentNavigationStatus?.location.coordinate)
    }

    func testReturnIsValidNavigationStatus() {
        let statusWithCorrectLegIndex = TestNavigationStatusProvider.createNavigationStatus(stepIndex: 1)
        XCTAssertTrue(routeController.isValidNavigationStatus(statusWithCorrectLegIndex))

        let statusWithIncorrectLegIndex = TestNavigationStatusProvider.createNavigationStatus(stepIndex: 11)
        XCTAssertFalse(routeController.isValidNavigationStatus(statusWithIncorrectLegIndex))
    }
    
    func testReturnLocation() {
        XCTAssertNil(routeController.location)
        
        let rawLocation = CLLocation(latitude: 47.208674, longitude: 9.524650)
        routeController.locationManager(locationManagerSpy, didUpdateLocations: [rawLocation])
        XCTAssertEqual(routeController.location, rawLocation)
    }
    
    func testSetDatasetProfileIdentifier() {
        CoreNavigatorSpy.datasetProfileIdentifier = .walking
        _ = makeRouteController()
        XCTAssertEqual(CoreNavigatorSpy.datasetProfileIdentifier, indexedRouteResponse.validatedRouteOptions.profileIdentifier)
    }
    
    func testReturnTileStore() {
        XCTAssertEqual(makeRouteController().navigatorTileStore, navigatorSpy.tileStore)
    }
    
    func testReturnResolvedRoutingProvider() {
        let resolvedRoutingProvider = makeRouteController().resolvedRoutingProvider as? RoutingProviderSpy
        XCTAssertTrue(resolvedRoutingProvider === routingProvider)
        XCTAssertNotNil(makeRouteController(routingProvider: nil).resolvedRoutingProvider)
    }
    
    func testReturnRouteProgress() {
        XCTAssertEqual(routeController.routeProgress.legIndex, 0)
        XCTAssertEqual(routeController.routeProgress.currentLegProgress.stepIndex, 0)
        
        let status = TestNavigationStatusProvider.createNavigationStatus(stepIndex: 1)
        routeController.updateIndexes(status: status, progress: routeController.routeProgress)
        XCTAssertEqual(routeController.routeProgress.currentLegProgress.stepIndex, 1)
    }
    
    func testReturnRoute() {
        XCTAssertEqual(routeController.route, route)
    }
    
    func testReturnRoadGraph() {
        XCTAssertTrue(makeRouteController().roadGraph === navigatorSpy.roadGraph)
    }
    
    func testReturnRoadObjectStore() {
        XCTAssertTrue(makeRouteController().roadObjectStore === navigatorSpy.roadObjectStore)
    }
    
    func testReturnRoadObjectMatcher() {
        XCTAssertTrue(makeRouteController().roadObjectMatcher === navigatorSpy.roadObjectMatcher)
    }
    
    func testReturnUserIsOnRoute() {
        let status = TestNavigationStatusProvider.createNavigationStatus()
        XCTAssertTrue(routeController.userIsOnRoute(rawLocation))
        XCTAssertTrue(routeController.userIsOnRoute(rawLocation, status: status))
        
        rerouteController.returnedUserIsOnRoute = false
        XCTAssertFalse(routeController.userIsOnRoute(rawLocation))
        XCTAssertFalse(routeController.userIsOnRoute(rawLocation, status: status))
    }
    
    func testFallbackToOffline() {
        RouteParserSpy.returnedRoutes = [nativeRoute]
        NotificationCenter.default.post(name: .navigationDidSwitchToFallbackVersion, object: nil, userInfo: nil)
        XCTAssertTrue(navigatorSpy.setRoutesCalled)
        XCTAssertTrue(navigatorSpy.passedRoute === nativeRoute)
        XCTAssertEqual(navigatorSpy.passedUuid, routeController.sessionUUID)
        XCTAssertEqual(navigatorSpy.passedLegIndex, UInt32(routeController.routeProgress.legIndex))
    }
    
    func testRestoreToOnline() {
        RouteParserSpy.returnedRoutes = [nativeRoute]
        NotificationCenter.default.post(name: .navigationDidSwitchToTargetVersion, object: nil, userInfo: nil)
        XCTAssertTrue(navigatorSpy.setRoutesCalled)
        XCTAssertTrue(navigatorSpy.passedRoute === nativeRoute)
        XCTAssertEqual(navigatorSpy.passedUuid, routeController.sessionUUID)
        XCTAssertEqual(navigatorSpy.passedLegIndex, UInt32(routeController.routeProgress.legIndex))
    }
    
    func testStartUpdatingElectronicHorizon() {
        let options = MapboxCoreNavigation.ElectronicHorizonOptions(length: 100,
                                                                    expansionLevel: 10,
                                                                    branchLength: 100,
                                                                    minTimeDeltaBetweenUpdates: nil)
        routeController.startUpdatingElectronicHorizon(with: options)
        XCTAssertTrue(navigatorSpy.startUpdatingElectronicHorizonCalled)
        XCTAssertNotNil(navigatorSpy.passedElectronicHorizonOptions)
    }
    
    func testStopUpdatingElectronicHorizon() {
        routeController.stopUpdatingElectronicHorizon()
        XCTAssertTrue(navigatorSpy.stopUpdatingElectronicHorizonCalled)
    }
    
    func testAdvanceLegIndexIfFinished() {
        routeController.finishRouting()
        routeController.advanceLegIndex()
        XCTAssertNil(nativeNavigatorSpy.passedLeg)
    }
    
    func testAdvanceLegIndexIfSuccessFromNavNative() {
        let callbackExpectation = expectation(description: "Advance leg index should be called")
        routeController.advanceLegIndex() { result in
            guard case .success(let routeProgress) = result else {
                return XCTFail("Expected a success but got a failure with \(result)")
            }
            XCTAssertEqual(routeProgress.legIndex, 0, "Leg index not changed until notification")
            callbackExpectation.fulfill()
        }
        XCTAssertEqual(nativeNavigatorSpy.passedLeg, 1)
        waitForExpectations(timeout: expectationsTimeout)
    }
    
    func testAdvanceLegIndexIfFailureFromNavNative() {
        let callbackExpectation = expectation(description: "Advance leg index should be called")
        nativeNavigatorSpy.returnedChangeLegResult = false
        routeController.advanceLegIndex() { result in
            guard case .failure(let error) = result else {
                return XCTFail("Expected a failure but got a success with \(result)")
            }
            let expectedError = RouteControllerError.failedToChangeRouteLeg
            XCTAssertEqual(error as? RouteControllerError, expectedError)
            callbackExpectation.fulfill()
        }
        XCTAssertEqual(nativeNavigatorSpy.passedLeg, 1)
        waitForExpectations(timeout: expectationsTimeout)
    }
    
    func testUpdateRouteLegIndex() {
        let expectation = XCTestExpectation(description: "Change leg should be called.")
        let legIndexToSet = 13
        
        routeController.updateRouteLeg(to: legIndexToSet) { result in
            guard case .success(let routeProgress) = result else {
                return XCTFail("Expected a success but got a failure with \(result)")
            }
            XCTAssertEqual(routeProgress.legIndex, 0, "Leg index not changed until notification")
            expectation.fulfill()
        }
        
        XCTAssertEqual(nativeNavigatorSpy.passedLeg, UInt32(legIndexToSet))
        wait(for: [expectation], timeout: expectationsTimeout)
    }
    
    func testReturnInitialManeuverAvoidanceRadius() {
        rerouteController.initialManeuverAvoidanceRadius = 3.0
        XCTAssertEqual(routeController.initialManeuverAvoidanceRadius, 3.0)

        routeController.initialManeuverAvoidanceRadius = 4.0
        XCTAssertEqual(routeController.initialManeuverAvoidanceRadius, 4.0)
        XCTAssertEqual(rerouteController.initialManeuverAvoidanceRadius, 4.0)
    }
    
    func testDidUpdateLocationIfShouldDiscard() {
        let callbackExpectation = expectation(description: "Discard should called")
        delegate.onShouldDiscard = { passedLocation in
            XCTAssertEqual(passedLocation, self.rawLocation)
            callbackExpectation.fulfill()
            return true
        }
        routeController.locationManager(locationManagerSpy, didUpdateLocations: [rawLocation])
        XCTAssertFalse(navigatorSpy.updateLocationCalled)
        waitForExpectations(timeout: expectationsTimeout)
    }
    
    func testDidUpdateLocationIfShouldNotDiscard() {
        let callbackExpectation = expectation(description: "Discard should called")
        delegate.onShouldDiscard = { passedLocation in
            XCTAssertEqual(passedLocation, self.rawLocation)
            callbackExpectation.fulfill()
            return false
        }
        routeController.locationManager(locationManagerSpy, didUpdateLocations: [rawLocation])
        XCTAssertTrue(navigatorSpy.updateLocationCalled)
        XCTAssertEqual(navigatorSpy.passedLocation, rawLocation)
        waitForExpectations(timeout: expectationsTimeout)
    }
    
    func testUpdatedHeading() {
        XCTAssertNil(routeController.heading)
        
        let heading = CLHeading(heading: 50, accuracy: 1)!
        routeController.locationManager(locationManagerSpy, didUpdateHeading: heading)
        XCTAssertEqual(routeController.heading, heading)
        
        let headingAfterFinished = CLHeading(heading: 10, accuracy: 1)!
        routeController.finishRouting()
        routeController.locationManager(locationManagerSpy, didUpdateHeading: headingAfterFinished)
        XCTAssertEqual(routeController.heading, heading)
    }

    func testUpdateWhenNavigationStatusDidChangeAndActiveGuidance() {
        let callbackExpectation = expectation(description: "Progress callback should be called")
        routeController.locationManager(locationManagerSpy, didUpdateLocations: [rawLocation])

        let activeGuidanceInfo = makeActiveGuidanceInfo()
        let statusLocation = CLLocation(coordinate: route.legs[0].steps[0].maneuverLocation)
        let status = TestNavigationStatusProvider.createNavigationStatus(location: statusLocation,
                                                                         activeGuidanceInfo: activeGuidanceInfo)
        let userInfo = [Navigator.NotificationUserInfoKey.statusKey : status]

        let expectedDistanceTraveled = activeGuidanceInfo.stepProgress.distanceTraveled
        delegate.onDidUpdate = { arguments in
            let (progress, location, rawLocation) = arguments
            XCTAssertEqual(location.coordinate, statusLocation.coordinate)
            XCTAssertEqual(rawLocation, self.rawLocation)
            XCTAssertEqual(progress.currentLegProgress.currentStepProgress.distanceTraveled, expectedDistanceTraveled)
            callbackExpectation.fulfill()
        }

        expectation(forNotification: .routeControllerProgressDidChange, object: routeController) { (notification) -> Bool in
            let userInfo = notification.userInfo
            let newLocation = userInfo?[RouteController.NotificationUserInfoKey.locationKey] as? CLLocation
            let rawLocation = userInfo?[RouteController.NotificationUserInfoKey.rawLocationKey] as? CLLocation
            let updatedRoadProgress = userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress

            XCTAssertEqual(newLocation?.coordinate, statusLocation.coordinate)
            XCTAssertEqual(rawLocation?.coordinate, self.rawLocation.coordinate)
            XCTAssertEqual(updatedRoadProgress?.currentLegProgress.currentStepProgress.distanceTraveled, expectedDistanceTraveled)

            return true
        }

        NotificationCenter.default.post(name: .navigationStatusDidChange, object: nil, userInfo: userInfo)
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testUpdateWhenNavigationStatusDidChangeAndNoActiveGuidance() {
        let callbackExpectation = expectation(description: "Progress callback should be called")
        routeController.locationManager(locationManagerSpy, didUpdateLocations: [rawLocation])

        let step = route.legs[0].steps[0]
        let statusLocation = CLLocation(coordinate: step.shape!.coordinates.last!)
        let status = TestNavigationStatusProvider.createNavigationStatus(location: statusLocation)
        let userInfo = [Navigator.NotificationUserInfoKey.statusKey : status]

        let expectedDistanceTraveled = step.distance
        delegate.onDidUpdate = { arguments in
            let (progress, _, _) = arguments
            XCTAssertEqual(progress.currentLegProgress.currentStepProgress.distanceTraveled, expectedDistanceTraveled)
            callbackExpectation.fulfill()
        }

        expectation(forNotification: .routeControllerProgressDidChange, object: routeController) { (notification) -> Bool in
            let updatedRoadProgress = notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress
            XCTAssertEqual(updatedRoadProgress?.currentLegProgress.currentStepProgress.distanceTraveled, expectedDistanceTraveled)
            return true
        }

        NotificationCenter.default.post(name: .navigationStatusDidChange, object: nil, userInfo: userInfo)
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testUpdateIndexesWhenNavigationStatusDidChange() {
        let response = IndexedRouteResponse(routeResponse: multilegRouteResponse, routeIndex: 0)
        routeController = makeRouteController(routeResponse: response)
        routeController.locationManager(locationManagerSpy, didUpdateLocations: [rawLocation])

        let activeGuidanceInfo = makeActiveGuidanceInfo()
        let voiceInstruction = VoiceInstruction(ssmlAnnouncement: "a", announcement: "b", remainingStepDistance: 10, index: 5)
        let status = TestNavigationStatusProvider.createNavigationStatus(legIndex: 1,
                                                                         stepIndex: 2,
                                                                         shapeIndex: 3,
                                                                         intersectionIndex: 4,
                                                                         voiceInstruction: voiceInstruction,
                                                                         bannerInstruction: bannerInstruction,
                                                                         activeGuidanceInfo: activeGuidanceInfo)
        let userInfo = [Navigator.NotificationUserInfoKey.statusKey : status]

        expectation(forNotification: .routeControllerProgressDidChange, object: routeController) { (notification) -> Bool in
            let progress = notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress

            XCTAssertEqual(progress?.legIndex, 1)
            XCTAssertEqual(progress?.currentLegProgress.stepIndex, 2)
            XCTAssertEqual(progress?.currentLegProgress.shapeIndex, 0, "Should not use shapeIndex from status")
            XCTAssertEqual(progress?.currentLegProgress.currentStepProgress.intersectionIndex, 4)
            XCTAssertEqual(progress?.currentLegProgress.currentStepProgress.spokenInstructionIndex, 5)
            XCTAssertEqual(progress?.currentLegProgress.currentStepProgress.visualInstructionIndex, 6)
            return true
        }

        NotificationCenter.default.post(name: .navigationStatusDidChange, object: nil, userInfo: userInfo)
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testUpdateRoadName() {
        let status = TestNavigationStatusProvider.createNavigationStatus()
        expectation(forNotification: .currentRoadNameDidChange, object: routeController) { (notification) -> Bool in
            let userInfo = notification.userInfo
            let roadName = userInfo?[RouteController.NotificationUserInfoKey.roadNameKey] as? String
            let routeShieldRepresentation = userInfo?[RouteController.NotificationUserInfoKey.routeShieldRepresentationKey] as? VisualInstruction.Component.ImageRepresentation

            XCTAssertEqual(roadName, status.roadName)
            XCTAssertEqual(routeShieldRepresentation, status.routeShieldRepresentation)

            return true
        }

        routeController.updateRoadName(status: status)
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testDoNotUpdateRouteLegProgressIfTooManyStepsLeft() {
        let status = TestNavigationStatusProvider.createNavigationStatus(routeState: .complete)
        let notificationExpectation = expectation(forNotification: .didArriveAtWaypoint, object: routeController)
        notificationExpectation.isInverted = true

        routeController.updateRouteLegProgress(status: status)
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testNotifyDidArriveAtWaypointIfCompleteStatus() {
        let status = TestNavigationStatusProvider.createNavigationStatus(routeState: .complete)
        let destination = route.legs[0].destination

        expectation(forNotification: .didArriveAtWaypoint, object: routeController) { (notification) -> Bool in
            let waypoint = notification.userInfo?[RouteController.NotificationUserInfoKey.waypointKey] as? MapboxDirections.Waypoint
            XCTAssertEqual(waypoint, destination)
            return true
        }

        routeController.routeProgress.currentLegProgress.stepIndex = 4
        routeController.updateRouteLegProgress(status: status)

        XCTAssertEqual(routeController.previousArrivalWaypoint, destination)
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testNotifyWillArriveAt() {
        let status = TestNavigationStatusProvider.createNavigationStatus(routeState: .tracking)
        routeController.routeProgress.currentLegProgress.stepIndex = 4
        let legProgress = routeController.routeProgress.currentLegProgress
        let destination = route.legs[0].destination

        let callbackExpectation = expectation(description: "Will arrive should called")
        delegate.onWillArriveAt = { arguments in
            let (waypoint, remainingTimeInterval, distance) = arguments
            XCTAssertEqual(waypoint, destination)
            XCTAssertEqual(remainingTimeInterval, legProgress.durationRemaining)
            XCTAssertEqual(distance, legProgress.distanceRemaining)
            callbackExpectation.fulfill()
        }

        let notificationExpectation = expectation(forNotification: .didArriveAtWaypoint, object: routeController)
        notificationExpectation.isInverted = true

        routeController.updateRouteLegProgress(status: status)
        waitForExpectations(timeout: expectationsTimeout)
    }
    
    func testRerouteIfNilCustomRoutingProvider() {
        let routeController = makeRouteController(routingProvider: nil)
        routeController.reroute(from: rawLocation, along: routeProgress)
        XCTAssertFalse(routeController.isRerouting)
        XCTAssertTrue(rerouteController.forceRerouteCalled)
    }
    
    func testRerouteIfFinishedRouting() {
        routeController.finishRouting()
        routeController.reroute(from: rawLocation, along: routeProgress)
        XCTAssertFalse(routeController.isRerouting)
        XCTAssertFalse(rerouteController.forceRerouteCalled)
    }
    
    func testNotifyWillRerouteIfRoutingProviderFailed() {
        let willRerouteExpectation = expectation(description: "Will reroute call on delegate")
        delegate.onWillRerouteFrom = { location in
            XCTAssertEqual(location, self.rawLocation)
            willRerouteExpectation.fulfill()
        }
        
        let didFailToReroutExpectation = expectation(description: "Did fail to reroute call on delegate")
        delegate.onDidFailToRerouteWith = { error in
            XCTAssertEqual(error as! DirectionsError, .unableToRoute)
            didFailToReroutExpectation.fulfill()
        }
        
        routeController.reroute(from: rawLocation, along: routeProgress)
        XCTAssertFalse(routeController.isRerouting)
        XCTAssertFalse(rerouteController.forceRerouteCalled)
        XCTAssertTrue(routingProvider.calculateRoutesCalled)

        waitForExpectations(timeout: expectationsTimeout)
    }
    
    func testSendRerouteNotificationIfRoutingProviderFailed() {
        let heading = CLHeading(heading: 50, accuracy: 1)!
        routeController.heading = heading
        
        expectation(forNotification: .routeControllerWillReroute, object: routeController) { (notification) -> Bool in
            let userInfo = notification.userInfo
            
            let notificationLocation = userInfo?[RouteController.NotificationUserInfoKey.locationKey] as? CLLocation
            let notificationHeading = userInfo?[RouteController.NotificationUserInfoKey.headingKey] as? CLHeading
            XCTAssertEqual(notificationLocation, self.rawLocation)
            XCTAssertEqual(notificationHeading, heading)
            
            return true
        }
        
        routeController.reroute(from: rawLocation, along: routeProgress)
        XCTAssertFalse(routeController.isRerouting)
        XCTAssertFalse(rerouteController.forceRerouteCalled)
        XCTAssertTrue(routingProvider.calculateRoutesCalled)
        
        let expectedRouteOptions = routeProgress.reroutingOptions(from: rawLocation)
        XCTAssertEqual(routingProvider.passedRouteOptions, expectedRouteOptions)
        
        waitForExpectations(timeout: expectationsTimeout)
    }
    
    func testSendRerouteNotificationIfRoutingProviderSucceed() {
        let heading = CLHeading(heading: 50, accuracy: 1)!
        routeController.heading = heading
        
        let didFailToReroutExpectation = expectation(description: "Did fail to reroute call on delegate")
        didFailToReroutExpectation.isInverted = true
        delegate.onDidFailToRerouteWith = { error in
            didFailToReroutExpectation.fulfill()
        }
        
        expectation(forNotification: .routeControllerWillReroute, object: routeController) { (notification) -> Bool in
            let userInfo = notification.userInfo
            
            let notificationLocation = userInfo?[RouteController.NotificationUserInfoKey.locationKey] as? CLLocation
            let notificationHeading = userInfo?[RouteController.NotificationUserInfoKey.headingKey] as? CLHeading
            XCTAssertEqual(notificationLocation, self.rawLocation)
            XCTAssertEqual(notificationHeading, heading)
            
            return true
        }
        let response = IndexedRouteResponse(routeResponse: singleRouteResponse, routeIndex: 0)
        routingProvider.returnedRoutesResult = .success(response)
        
        routeController.reroute(from: rawLocation, along: routeProgress)
        XCTAssertFalse(routeController.isRerouting)
        XCTAssertFalse(rerouteController.forceRerouteCalled)
        XCTAssertTrue(routingProvider.calculateRoutesCalled)
        XCTAssertEqual(routeController.indexedRouteResponse.currentRoute, response.currentRoute)
        
        let expectedRouteOptions = routeProgress.reroutingOptions(from: rawLocation)
        XCTAssertEqual(routingProvider.passedRouteOptions, expectedRouteOptions)
        
        waitForExpectations(timeout: expectationsTimeout)
    }
    
    func testSendRerouteNotificationIfRoutIsEmptyRoute() {
        let heading = CLHeading(heading: 50, accuracy: 1)!
        routeController.heading = heading
        
        let didFailToReroutExpectation = expectation(description: "Did fail to reroute call on delegate")
        delegate.onDidFailToRerouteWith = { error in
            XCTAssertEqual(error as! DirectionsError, .unableToRoute)
            didFailToReroutExpectation.fulfill()
        }
        
        expectation(forNotification: .routeControllerWillReroute, object: routeController) { (notification) -> Bool in
            let userInfo = notification.userInfo
            
            let notificationLocation = userInfo?[RouteController.NotificationUserInfoKey.locationKey] as? CLLocation
            let notificationHeading = userInfo?[RouteController.NotificationUserInfoKey.headingKey] as? CLHeading
            XCTAssertEqual(notificationLocation, self.rawLocation)
            XCTAssertEqual(notificationHeading, heading)
            
            return true
        }
        
        let routeResponse = RouteResponse(httpResponse: nil,
                                          routes: [],
                                          options: .route(options),
                                          credentials: .mocked)
        let response = IndexedRouteResponse(routeResponse: routeResponse, routeIndex: 0)
        routingProvider.returnedRoutesResult = .success(response)
        
        routeController.reroute(from: rawLocation, along: routeProgress)
        XCTAssertFalse(routeController.isRerouting)
        XCTAssertFalse(rerouteController.forceRerouteCalled)
        XCTAssertTrue(routingProvider.calculateRoutesCalled)
        
        let expectedRouteOptions = routeProgress.reroutingOptions(from: rawLocation)
        XCTAssertEqual(routingProvider.passedRouteOptions, expectedRouteOptions)
        
        waitForExpectations(timeout: expectationsTimeout)
    }
    
    func testRerouteWhenReroutingAndNavigatorSucceed() {
        let response = IndexedRouteResponse(routeResponse: singleRouteResponse, routeIndex: 0)
        routingProvider.returnedRoutesResult = .success(response)
        
        routeController.reroute(from: rawLocation, along: routeProgress)
        XCTAssertTrue(navigatorSpy.setRoutesCalled)
        XCTAssertEqual(navigatorSpy.passedUuid, routeController.sessionUUID)
        XCTAssertEqual(navigatorSpy.passedLegIndex, 0)
        XCTAssertEqual(navigatorSpy.passedAlternativeRoutes?.count, 0)
        
        XCTAssertFalse(routeController.isRerouting)
        XCTAssertFalse(routeController.didProactiveReroute)
        
        XCTAssertTrue(routeController.routeProgress.route === response.currentRoute)
        guard case .route(let expectedRouteOptions) = singleRouteResponse.options else {
            XCTFail()
            return
        }
        XCTAssertEqual(routeController.routeProgress.routeOptions, expectedRouteOptions)
    }
    
    func testRerouteWhenReroutingAndNavigatorFailed() {
        let response = IndexedRouteResponse(routeResponse: singleRouteResponse, routeIndex: 0)
        routingProvider.returnedRoutesResult = .success(response)
        navigatorSpy.returnedSetRoutesResult = .failure(DirectionsError.unableToRoute)
        
        routeController.reroute(from: rawLocation, along: routeProgress)
        XCTAssertTrue(navigatorSpy.setRoutesCalled)
        XCTAssertFalse(routeController.isRerouting)
    }
    
    func testHandleDidDetectRerouteEventIfShouldReroute() {
        let callbackExpectation = expectation(description: "Reroute should called")
        routeController.rawLocation = rawLocation
        delegate.onShouldRerouteFrom = { location in
            XCTAssertEqual(location, self.rawLocation)
            callbackExpectation.fulfill()
            return true
        }
        XCTAssertTrue(routeController.rerouteControllerDidDetectReroute(rerouteController))
        XCTAssertTrue(routeController.isRerouting)

        waitForExpectations(timeout: expectationsTimeout)
    }
    
    func testHandleDidDetectRerouteEventIfShouldNotReroute() {
        routeController.rawLocation = rawLocation
        delegate.onShouldRerouteFrom = { location in
            return false
        }
        XCTAssertFalse(routeController.rerouteControllerDidDetectReroute(rerouteController))
        XCTAssertFalse(routeController.isRerouting)
    }
    
    func testHandleDidDetectRerouteEventIfDefaultBehavior() {
        routeController.rawLocation = rawLocation
        routeController.delegate = nil
        XCTAssertTrue(routeController.rerouteControllerDidDetectReroute(rerouteController))
        XCTAssertTrue(routeController.isRerouting)
    }
    
    func testHandleDidRecieveRerouteEvent() {
        let response = IndexedRouteResponse(routeResponse: singleRouteResponse, routeIndex: 0)
        routingProvider.returnedRoutesResult = .success(response)
        _ = routeController.rerouteControllerDidDetectReroute(rerouteController)
        
        let routerOrigin = indexedRouteResponse.responseOrigin
        routeController.rerouteControllerDidRecieveReroute(rerouteController,
                                                           response: response.routeResponse,
                                                           options: options,
                                                           routeOrigin: routerOrigin)
        XCTAssertFalse(routeController.isRerouting)
        XCTAssertTrue(routeController.routeProgress.route === response.currentRoute)
    }

    func testHandleDidCancelRerouteEvent() {
        routeController.isRerouting = true
        routeController.rerouteControllerDidCancelReroute(rerouteController)
        XCTAssertFalse(routeController.isRerouting)
    }

    func testHandleWillModifyOptionsEvent() {
        let routeOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 9.519172, longitude: 47.210823),
            CLLocationCoordinate2D(latitude: 9.52222, longitude: 47.214268)
            ])
        let callbackExpectation = expectation(description: "Did fail to reroute call on delegate")
        delegate.onModifiedOptionsForReroute = { passedOptions in
            XCTAssertEqual(passedOptions, self.options)
            callbackExpectation.fulfill()
            return routeOptions
        }

        let rerouteOptions = routeController.rerouteControllerWillModify(options: options)
        XCTAssertEqual(rerouteOptions, routeOptions)
        waitForExpectations(timeout: expectationsTimeout)
    }
    
    func testHandleDidFailToRerouteEvent() {
        let didFailToReroutExpectation = expectation(description: "Did fail to reroute call on delegate")
        delegate.onDidFailToRerouteWith = { error in
            XCTAssertEqual(error as! DirectionsError, .noData)
            didFailToReroutExpectation.fulfill()
        }

        expectation(forNotification: .routeControllerDidFailToReroute, object: routeController) { (notification) -> Bool in
            let error = notification.userInfo?[RouteController.NotificationUserInfoKey.routingErrorKey] as? DirectionsError
            XCTAssertEqual(error, .noData)

            return true
        }

        routeController.rerouteControllerDidFailToReroute(rerouteController, with: .noData)
        waitForExpectations(timeout: expectationsTimeout)
    }
    
    func testDoNotProactiveRerouting() {
        routeController.reroutesProactively = false
        let routeExpectation = expectation(description: "Proactive ReRoute should not be called")
        routeExpectation.isInverted = true
        delegate.onShouldProactivelyRerouteFrom = { _, _ in
            routeExpectation.fulfill()
            return true
        }
        
        routeController.checkForFasterRoute(from: rawLocation, routeProgress: routeProgress)
        waitForExpectations(timeout: expectationsTimeout)
    }
    
    func testDoNotProactiveReroutingIfSmallDurationRemaining() {
        routeController.reroutesProactively = true
        let routeExpectation = expectation(description: "Proactive ReRoute should not be called")
        routeExpectation.isInverted = true
        delegate.onShouldProactivelyRerouteFrom = { _, _ in
            routeExpectation.fulfill()
            return true
        }
        
        routeController.checkForFasterRoute(from: rawLocation, routeProgress: routeProgress)
        waitForExpectations(timeout: expectationsTimeout)
    }
    
    func testDoNotProactiveReroutingIfNoNextStep() {
        routeController.reroutesProactively = true
        let routeExpectation = expectation(description: "Proactive ReRoute should not be called")
        routeExpectation.isInverted = true
        delegate.onShouldProactivelyRerouteFrom = { _, _ in
            routeExpectation.fulfill()
            return true
        }
        
        let updatedRouteProgress = self.routeProgress!
        let legProgress = Fixture.routeLegProgress(expectedTravelTime: 1000, stepDistance: 9000)
        legProgress.currentStepProgress.distanceTraveled = 2000
        updatedRouteProgress.currentLegProgress = legProgress
        routeController.checkForFasterRoute(from: rawLocation, routeProgress: updatedRouteProgress)
        waitForExpectations(timeout: expectationsTimeout)
    }
    
    func testProactiveReroutingIfNilLastProactiveRerouteDate() {
        routeController.reroutesProactively = true
        let response = IndexedRouteResponse(routeResponse: singleRouteResponse, routeIndex: 0)
        routingProvider.returnedRoutesResult = .success(response)
        let routeExpectation = expectation(description: "Proactive ReRoute should not be called")
        routeExpectation.isInverted = true
        delegate.onShouldProactivelyRerouteFrom = { _, _ in
            routeExpectation.fulfill()
            return true
        }
        
        let updatedRouteProgress = self.routeProgress!
        let legProgress = Fixture.routeLegProgress(expectedTravelTime: 1000, stepDistance: 9000, stepCount: 2)
        legProgress.currentStepProgress.distanceTraveled = 2000
        updatedRouteProgress.currentLegProgress = legProgress
        routeController.checkForFasterRoute(from: locationWithDate, routeProgress: updatedRouteProgress)
        waitForExpectations(timeout: expectationsTimeout)
    }
    
    func testProactiveReroutingIfNotMatchingSteps() {
        routeController.reroutesProactively = true
        routingProvider.returnedRoutesResult = .success(indexedRouteResponse)
        let routeExpectation = expectation(description: "Proactive ReRoute should not be called")
        routeExpectation.isInverted = true
        delegate.onShouldProactivelyRerouteFrom = { location, route in
            routeExpectation.fulfill()
            return true
        }
        
        let updatedRouteProgress = self.routeProgress!
        let legProgress = Fixture.routeLegProgress(expectedTravelTime: 1000, stepDistance: 9000, stepCount: 2)
        legProgress.currentStepProgress.distanceTraveled = 2000
        updatedRouteProgress.currentLegProgress = legProgress
        routeController.lastProactiveRerouteDate = locationWithDate.timestamp.addingTimeInterval(-121)
        routeController.checkForFasterRoute(from: locationWithDate, routeProgress: updatedRouteProgress)
        
        XCTAssertNil(routeController.lastProactiveRerouteDate)
        XCTAssertFalse(routeController.isRerouting)

        waitForExpectations(timeout: expectationsTimeout)
    }
    
    func testProactiveReroutingIfNotFasterRoad() {
        routeController.reroutesProactively = true
        routingProvider.returnedRoutesResult = .success(indexedRouteResponse)
        let routeExpectation = expectation(description: "Proactive ReRoute should not be called")
        routeExpectation.isInverted = true
        delegate.onShouldProactivelyRerouteFrom = { location, route in
            routeExpectation.fulfill()
            return true
        }
        
        let updatedRouteProgress = self.routeProgress!
        let legProgress = Fixture.routeLegProgress(expectedTravelTime: 1000, stepDistance: 9000, stepCount: 2)
        legProgress.currentStepProgress.distanceTraveled = 2000
        updatedRouteProgress.currentLegProgress = legProgress
        routeController.lastProactiveRerouteDate = locationWithDate.timestamp.addingTimeInterval(-121)
        routeController.checkForFasterRoute(from: locationWithDate, routeProgress: updatedRouteProgress)
        
        XCTAssertNil(routeController.lastProactiveRerouteDate)

        waitForExpectations(timeout: expectationsTimeout)
    }
    
    func testProactiveReroutingIfNonNilCompletion() {
        routeController.reroutesProactively = true
        indexedRouteResponse.currentRoute!.expectedTravelTime *= 0.85
        routingProvider.returnedRoutesResult = .success(indexedRouteResponse)
        let routeExpectation = expectation(description: "Proactive ReRoute should be called")
        delegate.onShouldProactivelyRerouteFrom = { location, route in
            routeExpectation.fulfill()
            return true
        }
        
        let updatedRouteProgress = self.routeProgress!
        updatedRouteProgress.currentLegProgress.currentStep.expectedTravelTime = 2000
        updatedRouteProgress.currentLegProgress.currentStepProgress.distanceTraveled = 2
        routeController.lastProactiveRerouteDate = locationWithDate.timestamp.addingTimeInterval(-121)
        routeController.checkForFasterRoute(from: locationWithDate, routeProgress: updatedRouteProgress)
        
        XCTAssertNil(routeController.lastProactiveRerouteDate)
        XCTAssertFalse(routeController.isRerouting)
        XCTAssertTrue(navigatorSpy.setRoutesCalled)
        
        XCTAssertTrue(routeController.didProactiveReroute)

        waitForExpectations(timeout: expectationsTimeout)
    }
    
    func testProactiveReroutingIfNoCompletion() {
        routeController.reroutesProactively = true
        indexedRouteResponse.currentRoute!.expectedTravelTime *= 0.85
        routingProvider.returnedRoutesResult = .success(indexedRouteResponse)
        let routeExpectation = expectation(description: "Proactive ReRoute should be called")
        delegate.onShouldProactivelyRerouteFrom = { location, route in
            routeExpectation.fulfill()
            return false
        }
        
        let updatedRouteProgress = self.routeProgress!
        updatedRouteProgress.currentLegProgress.currentStep.expectedTravelTime = 2000
        updatedRouteProgress.currentLegProgress.currentStepProgress.distanceTraveled = 2
        routeController.lastProactiveRerouteDate = locationWithDate.timestamp.addingTimeInterval(-121)
        routeController.checkForFasterRoute(from: locationWithDate, routeProgress: updatedRouteProgress)
        
        XCTAssertNil(routeController.lastProactiveRerouteDate)
        XCTAssertTrue(routeController.isRerouting)
        XCTAssertFalse(navigatorSpy.setRoutesCalled)
        XCTAssertFalse(routeController.didProactiveReroute)

        waitForExpectations(timeout: expectationsTimeout)
    }
    
    func testAlternativeRoutesNotReportedIfNoData() {
        let alternativesExpectation = expectation(description: "Alternative route should not be reported")
        alternativesExpectation.isInverted = true
        delegate.onDidUpdateAlternativeRoutes = { _, _ in
            alternativesExpectation.fulfill()
        }
        NotificationCenter.default.post(name: .navigatorDidChangeAlternativeRoutes, object: nil, userInfo: nil)

        XCTAssertFalse(navigatorSpy.setAlternativeRoutesCalled)
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testAlternativeRoutesReportedIfError() {
        let alternativesExpectation = expectation(description: "Alternative route should be reported")
        alternativesExpectation.isInverted = true
        delegate.onDidUpdateAlternativeRoutes = { newAlternatives, removedAlternatives in
            alternativesExpectation.fulfill()
        }

        let innerError = DirectionsError.noData
        navigatorSpy.returnedSetAlternativeRoutesResult = .failure(innerError)
        expectation(forNotification: .routeControllerDidFailToUpdateAlternatives, object: routeController) { (notification) -> Bool in
            let userInfo = notification.userInfo

            let alternativesError = userInfo?[RouteController.NotificationUserInfoKey.alternativesErrorKey] as? AlternativeRouteError
            let expectedError = AlternativeRouteError.failedToUpdateAlternativeRoutes(reason: innerError.localizedDescription)
            XCTAssertEqual(alternativesError?.localizedDescription, expectedError.localizedDescription)

            return true
        }

        let alternativeRoute = createRouteAlternative(id: 1)
        let removedAlternativeRoute = createRouteAlternative(id: 2)
        let userInfo = [
            Navigator.NotificationUserInfoKey.alternativesListKey: [alternativeRoute],
            Navigator.NotificationUserInfoKey.removedAlternativesKey: [removedAlternativeRoute]
        ]
        NotificationCenter.default.post(name: .navigatorDidChangeAlternativeRoutes, object: nil, userInfo: userInfo)

        waitForExpectations(timeout: expectationsTimeout)
    }
    
    func testAlternativeRoutesReportedIfEmptyCurrentContinuousAlternatives() {
        let alternativesExpectation = expectation(description: "Alternative route should be reported")
        delegate.onDidUpdateAlternativeRoutes = { newAlternatives, removedAlternatives in
            XCTAssertEqual(newAlternatives.count, 1)
            XCTAssertEqual(removedAlternatives.count, 0)
            alternativesExpectation.fulfill()
        }

        let alternativeRoute = createRouteAlternative(id: 1)
        let removedAlternativeRoute = createRouteAlternative(id: 2)
        let userInfo = [
            Navigator.NotificationUserInfoKey.alternativesListKey: [alternativeRoute],
            Navigator.NotificationUserInfoKey.removedAlternativesKey: [removedAlternativeRoute]
        ]
        navigatorSpy.returnedSetAlternativeRoutesResult = .success([alternativeRoute])
        NotificationCenter.default.post(name: .navigatorDidChangeAlternativeRoutes, object: nil, userInfo: userInfo)

        XCTAssertTrue(navigatorSpy.setAlternativeRoutesCalled)
        XCTAssertEqual(routeController.continuousAlternatives.count, 1)
        XCTAssertEqual(routeController.continuousAlternatives[0].id, 1)
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testSendAlternativeRoutesNotificationIfEmptyCurrentContinuousAlternatives() {
        expectation(forNotification: .routeControllerDidUpdateAlternatives, object: routeController) { (notification) -> Bool in
            let userInfo = notification.userInfo

            let updatedAlternatives = userInfo?[RouteController.NotificationUserInfoKey.updatedAlternativesKey] as? [AlternativeRoute]
            let removedAlternatives = userInfo?[RouteController.NotificationUserInfoKey.removedAlternativesKey] as? [AlternativeRoute]
            XCTAssertEqual(updatedAlternatives?.count, 1)
            XCTAssertEqual(removedAlternatives?.count, 0)

            return true
        }

        let alternativeRoute = createRouteAlternative(id: 1)
        let removedAlternativeRoute = createRouteAlternative(id: 2)
        let userInfo = [
            Navigator.NotificationUserInfoKey.alternativesListKey: [alternativeRoute],
            Navigator.NotificationUserInfoKey.removedAlternativesKey: [removedAlternativeRoute]
        ]
        navigatorSpy.returnedSetAlternativeRoutesResult = .success([alternativeRoute])
        NotificationCenter.default.post(name: .navigatorDidChangeAlternativeRoutes, object: nil, userInfo: userInfo)

        waitForExpectations(timeout: expectationsTimeout)
    }

    func testAlternativeRoutesReportedIfNonEmptyCurrentContinuousAlternatives() {
        navigatorSpy.returnedSetRoutesResult = .success((mainRouteInfo: nil, alternativeRoutes: [createRouteAlternative(id: 2)]))
        routeController.updateRoute(with: indexedRouteResponse, routeOptions: options, completion: nil)

        let alternativesExpectation = expectation(description: "Alternative route should be reported")
        delegate.onDidUpdateAlternativeRoutes = { newAlternatives, removedAlternatives in
            XCTAssertEqual(newAlternatives.count, 1)
            XCTAssertEqual(removedAlternatives.count, 1)
            alternativesExpectation.fulfill()
        }

        let alternativeRoute = createRouteAlternative(id: 1)
        let removedAlternativeRoute = createRouteAlternative(id: 2)
        let userInfo = [
            Navigator.NotificationUserInfoKey.alternativesListKey: [alternativeRoute],
            Navigator.NotificationUserInfoKey.removedAlternativesKey: [removedAlternativeRoute]
        ]
        navigatorSpy.returnedSetAlternativeRoutesResult = .success([alternativeRoute])
        NotificationCenter.default.post(name: .navigatorDidChangeAlternativeRoutes, object: nil, userInfo: userInfo)

        XCTAssertTrue(navigatorSpy.setAlternativeRoutesCalled)
        XCTAssertEqual(routeController.continuousAlternatives.count, 1)
        XCTAssertEqual(routeController.continuousAlternatives[0].id, 1)
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testSendAlternativeRoutesNotificationIfNonEmptyCurrentContinuousAlternatives() {
        navigatorSpy.returnedSetRoutesResult = .success((mainRouteInfo: nil, alternativeRoutes: [createRouteAlternative(id: 2)]))
        routeController.updateRoute(with: indexedRouteResponse, routeOptions: options, completion: nil)

        expectation(forNotification: .routeControllerDidUpdateAlternatives, object: routeController) { (notification) -> Bool in
            let userInfo = notification.userInfo

            let updatedAlternatives = userInfo?[RouteController.NotificationUserInfoKey.updatedAlternativesKey] as? [AlternativeRoute]
            let removedAlternatives = userInfo?[RouteController.NotificationUserInfoKey.removedAlternativesKey] as? [AlternativeRoute]
            XCTAssertEqual(updatedAlternatives?.count, 1)
            XCTAssertEqual(removedAlternatives?.count, 1)

            return true
        }

        let alternativeRoute = createRouteAlternative(id: 1)
        let removedAlternativeRoute = createRouteAlternative(id: 2)
        let userInfo = [
            Navigator.NotificationUserInfoKey.alternativesListKey: [alternativeRoute],
            Navigator.NotificationUserInfoKey.removedAlternativesKey: [removedAlternativeRoute]
        ]
        navigatorSpy.returnedSetAlternativeRoutesResult = .success([alternativeRoute])
        NotificationCenter.default.post(name: .navigatorDidChangeAlternativeRoutes, object: nil, userInfo: userInfo)

        waitForExpectations(timeout: expectationsTimeout)
    }

    func testNotifyDidFailToChangeAlternativeRoutesIfNilUserInfo() {
        let callbackExpectation = expectation(description: "Error updating aternative routes should not be reported")
        callbackExpectation.isInverted = true
        delegate.onDidFailToUpdateAlternativeRoutes = { _ in
            callbackExpectation.fulfill()
        }
        NotificationCenter.default.post(name: .navigatorDidFailToChangeAlternativeRoutes, object: nil, userInfo: nil)

        waitForExpectations(timeout: expectationsTimeout)
    }

    func testNotifyDelegateDidFailToChangeAlternativeRoutesIfNilAlternativeRouteDetectionStrategy() {
        let settingsValues = NavigationSettings.Values(directions: .mocked,
                                                       tileStoreConfiguration: .default,
                                                       routingProviderSource: .hybrid,
                                                       alternativeRouteDetectionStrategy: nil)
        NavigationSettings.shared.initialize(with: settingsValues)

        let message = "error message"
        let callbackExpectation = expectation(description: "Error updating aternative routes should not be reported")
        callbackExpectation.isInverted = true
        delegate.onDidFailToUpdateAlternativeRoutes = { _ in
            callbackExpectation.fulfill()
        }
        let userInfo = [Navigator.NotificationUserInfoKey.messageKey: message]
        NotificationCenter.default.post(name: .navigatorDidFailToChangeAlternativeRoutes, object: nil, userInfo: userInfo)

        waitForExpectations(timeout: expectationsTimeout)
    }

    func testNotifyDelegateDidFailToChangeAlternativeRoutes() {
        let message = "error message"
        let callbackExpectation = expectation(description: "Error updating aternative routes should be reported")
        delegate.onDidFailToUpdateAlternativeRoutes = { error in
            let expectedError = AlternativeRouteError.failedToUpdateAlternativeRoutes(reason: message)
            XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
            callbackExpectation.fulfill()
        }
        let userInfo = [Navigator.NotificationUserInfoKey.messageKey: message]
        NotificationCenter.default.post(name: .navigatorDidFailToChangeAlternativeRoutes, object: nil, userInfo: userInfo)

        waitForExpectations(timeout: expectationsTimeout)
    }

    func testHandleFailToChangeAlternativeRoutesEvent() {
        let message = "error message"
        expectation(forNotification: .routeControllerDidFailToUpdateAlternatives, object: routeController) { (notification) -> Bool in
            let userInfo = notification.userInfo

            let error = userInfo?[RouteController.NotificationUserInfoKey.alternativesErrorKey] as? AlternativeRouteError
            let expectedError = AlternativeRouteError.failedToUpdateAlternativeRoutes(reason: message)
            XCTAssertEqual(error?.localizedDescription, expectedError.localizedDescription)

            return true
        }

        let userInfo = [Navigator.NotificationUserInfoKey.messageKey: message]
        NotificationCenter.default.post(name: .navigatorDidFailToChangeAlternativeRoutes, object: nil, userInfo: userInfo)

        waitForExpectations(timeout: expectationsTimeout)
    }

    func testSwitchToCoincideOnlineRouteIfNilUserInfo() {
        let callbackExpectation = expectation(description: "Switch to coincident online route should not be reported")
        callbackExpectation.isInverted = true
        delegate.onDidSwitchToCoincideRoute = { _ in
            callbackExpectation.fulfill()
        }
        NotificationCenter.default.post(name: .navigatorWantsSwitchToCoincideOnlineRoute, object: nil, userInfo: nil)

        waitForExpectations(timeout: expectationsTimeout)
    }

    func testSwitchToCoincideOnlineRouteIfNavNativeFailed() {
        let route = TestRouteProvider.createRoute(routeResponse: singleRouteResponse)!
        let callbackExpectation = expectation(description: "Switch to coincident online route should be reported")
        delegate.onDidSwitchToCoincideRoute = { actualRoute in
            XCTAssertEqual(actualRoute, self.singleRouteResponse.routes?[0])
            callbackExpectation.fulfill()
        }

        expectation(forNotification: .routeControllerDidSwitchToCoincidentOnlineRoute, object: routeController) { (notification) -> Bool in
            let actualRoute = notification.userInfo?[RouteController.NotificationUserInfoKey.coincidentRouteKey] as? Route
            XCTAssertEqual(actualRoute, self.singleRouteResponse.routes?[0])
            return true
        }
        navigatorSpy.returnedSetRoutesResult = .failure(DirectionsError.unableToRoute)
        
        let userInfo = [Navigator.NotificationUserInfoKey.coincideOnlineRouteKey: route]
        NotificationCenter.default.post(name: .navigatorWantsSwitchToCoincideOnlineRoute, object: nil, userInfo: userInfo)

        XCTAssertEqual(routeController.indexedRouteResponse.routeIndex, 0)
        XCTAssertEqual(routeController.indexedRouteResponse.responseOrigin, route.getRouterOrigin())
        XCTAssertEqual(routeController.continuousAlternatives.count, 0)
        XCTAssertEqual(routeController.indexedRouteResponse.currentRoute?.legs, singleRouteResponse.routes?[0].legs)
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testSwitchToCoincideOnlineRouteIfNavNativeSucceed() {
        let route = TestRouteProvider.createRoute(routeResponse: singleRouteResponse)!
        let callbackExpectation = expectation(description: "Switch to coincident online route should be reported")
        delegate.onDidSwitchToCoincideRoute = { actualRoute in
            XCTAssertEqual(actualRoute, self.singleRouteResponse.routes?[0])
            callbackExpectation.fulfill()
        }

        expectation(forNotification: .routeControllerDidSwitchToCoincidentOnlineRoute, object: routeController) { (notification) -> Bool in
            let actualRoute = notification.userInfo?[RouteController.NotificationUserInfoKey.coincidentRouteKey] as? Route
            XCTAssertEqual(actualRoute, self.singleRouteResponse.routes?[0])
            return true
        }

        let userInfo = [Navigator.NotificationUserInfoKey.coincideOnlineRouteKey: route]
        NotificationCenter.default.post(name: .navigatorWantsSwitchToCoincideOnlineRoute, object: nil, userInfo: userInfo)

        XCTAssertEqual(routeController.indexedRouteResponse.routeIndex, 0)
        XCTAssertEqual(routeController.indexedRouteResponse.responseOrigin, route.getRouterOrigin())
        XCTAssertEqual(routeController.indexedRouteResponse.currentRoute?.legs, singleRouteResponse.routes?[0].legs)
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testRerouteAfterArrivalIfUserHasNotArrivedAtWaypoint() {
        let callbackExpectation = expectation(description: "Should prevent reroute")
        callbackExpectation.isInverted = true
        delegate.onShouldPreventReroutesWhenArrivingAt = { _ in
            callbackExpectation.fulfill()
            return true
        }
        routeController.routeProgress.currentLegProgress.userHasArrivedAtWaypoint = false
        routeController.rerouteAfterArrivalIfNeeded(rawLocation, status: nil)
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testRerouteAfterArrivalIfNotCompleteStatus() {
        let status = TestNavigationStatusProvider.createNavigationStatus(routeState: .tracking)
        routeController.rerouteAfterArrivalIfNeeded(rawLocation, status: status)

        XCTAssertFalse(navigatorSpy.setRoutesCalled)
    }

    func testPreventRerouteAfterArrivalIfDefaultPolicy() {
        routeController.delegate = nil
        routeController.routeProgress.currentLegProgress.userHasArrivedAtWaypoint = true
        let status = TestNavigationStatusProvider.createNavigationStatus(routeState: .complete)
        routeController.rerouteAfterArrivalIfNeeded(rawLocation, status: status)

        XCTAssertFalse(navigatorSpy.setRoutesCalled)
    }

    func testRerouteAfterArrivalIfNeededIfUserHasArrivedAtWaypoint() {
        let callbackExpectation = expectation(description: "Should prevent reroute")
        delegate.onShouldPreventReroutesWhenArrivingAt = { _ in
            callbackExpectation.fulfill()
            return true
        }
        routeController.routeProgress.currentLegProgress.userHasArrivedAtWaypoint = true
        routeController.rerouteAfterArrivalIfNeeded(rawLocation, status: nil)

        XCTAssertFalse(navigatorSpy.setRoutesCalled)
        XCTAssertFalse(routingProvider.calculateRoutesCalled)
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testRerouteAfterArrivalIfShouldNotPreventAndFailedReroute() {
        let callbackExpectation = expectation(description: "Should not prevent reroute")
        callbackExpectation.assertForOverFulfill = false
        delegate.onShouldPreventReroutesWhenArrivingAt = { destination in
            XCTAssertEqual(destination, self.routeProgress.currentLeg.destination)
            callbackExpectation.fulfill()
            return false
        }

        let didFailToReroutExpectation = expectation(description: "Did fail to reroute call on delegate")
        delegate.onDidFailToRerouteWith = { error in
            XCTAssertEqual(error as? DirectionsError, .unableToRoute)
            didFailToReroutExpectation.fulfill()
        }

        routeController.routeProgress.currentLegProgress.userHasArrivedAtWaypoint = true
        let status = TestNavigationStatusProvider.createNavigationStatus(routeState: .complete)
        routeController.rerouteAfterArrivalIfNeeded(rawLocation, status: status)
        
        XCTAssertFalse(navigatorSpy.setRoutesCalled)
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testRerouteAfterArrivalIfCloseToStep() {
        let didFailToReroutExpectation = expectation(description: "Did fail to reroute call on delegate")
        didFailToReroutExpectation.isInverted = true
        delegate.onDidFailToRerouteWith = { _ in
            didFailToReroutExpectation.fulfill()
        }

        let status = TestNavigationStatusProvider.createNavigationStatus(routeState: .complete)
        let newLocation = CLLocation(coordinate: indexedRouteResponse.validatedRouteOptions.waypoints[0].coordinate)
        routeController.rerouteAfterArrivalIfNeeded(newLocation, status: status)

        XCTAssertFalse(navigatorSpy.setRoutesCalled)
        XCTAssertFalse(routingProvider.calculateRoutesCalled)
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testRerouteAfterArrival() {
        let didFailToReroutExpectation = expectation(description: "Did fail to reroute call on delegate")
        didFailToReroutExpectation.isInverted = true
        delegate.onDidFailToRerouteWith = { _ in
            didFailToReroutExpectation.fulfill()
        }

        let newResponse = IndexedRouteResponse(routeResponse: singleRouteResponse, routeIndex: 0)
        routingProvider.returnedRoutesResult = .success(newResponse)

        let status = TestNavigationStatusProvider.createNavigationStatus(routeState: .complete)
        routeController.rerouteAfterArrivalIfNeeded(rawLocation, status: status)

        XCTAssertTrue(navigatorSpy.setRoutesCalled)
        XCTAssertEqual(routeController.indexedRouteResponse.currentRoute, newResponse.currentRoute)
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testDoNotUpdateRouteIfFinishedRouting() {
        let newResponse = IndexedRouteResponse(routeResponse: singleRouteResponse, routeIndex: 0)
        routeController.finishRouting()
        let expectation = expectation(description: "Should not call callback")
        expectation.isInverted = true
        routeController.updateRoute(with: newResponse, routeOptions: options) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testUpdateRouteIfNavNativeFailed() {
        let completionExpectation = expectation(description: "Should call callback")
        let newResponse = IndexedRouteResponse(routeResponse: routeResponse, routeIndex: 1)

        navigatorSpy.returnedSetRoutesResult = .failure(DirectionsError.noData)
        
        routeController.updateRoute(with: newResponse, routeOptions: options) { result in
            XCTAssertFalse(result)
            completionExpectation.fulfill()
        }
        XCTAssertEqual(routeController.route, route)
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testUpdateRouteIfIfNavNativeSucceed() {
        let completionExpectation = expectation(description: "Should call callback")
        let newResponse = IndexedRouteResponse(routeResponse: routeResponse, routeIndex: 1)

        routeController.updateRoute(with: newResponse, routeOptions: options) { result in
            XCTAssertTrue(result)
            completionExpectation.fulfill()
        }
        XCTAssertTrue(navigatorSpy.setRoutesCalled)
        XCTAssertEqual(routeController.route, routeResponse.routes?[1])
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testUpdateRouteIfRouteParserFailed() {
        RouteParserSpy.returnedError = "error"
        let newResponse = IndexedRouteResponse(routeResponse: routeResponse, routeIndex: 1)

        let completionExpectation = expectation(description: "Should call callback")
        routeController.updateRoute(with: newResponse, routeOptions: options) { result in
            XCTAssertFalse(result)
            completionExpectation.fulfill()
        }
        XCTAssertFalse(navigatorSpy.setRoutesCalled)
        XCTAssertEqual(routeController.route, routeResponse.routes?[0], "Should not change rout")
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testUpdateRouteIfRouteParserSucceedButNotEnoughRoutes() {
        RouteParserSpy.returnedRoutes = [nativeRoute]
        let newResponse = IndexedRouteResponse(routeResponse: routeResponse, routeIndex: 1)
        let completionExpectation = expectation(description: "Should call callback")

        routeController.updateRoute(with: newResponse, routeOptions: options) { result in
            XCTAssertFalse(result)
            completionExpectation.fulfill()
        }
        XCTAssertFalse(navigatorSpy.setRoutesCalled)
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testUpdateRouteIfRouteParserSucceed() {
        RouteParserSpy.returnedRoutes = [nativeRoute, nativeRoute]
        let newResponse = IndexedRouteResponse(routeResponse: routeResponse, routeIndex: 1)
        let completionExpectation = expectation(description: "Should call callback")
        
        routeController.updateRoute(with: newResponse, routeOptions: options) { result in
            XCTAssertTrue(result)
            completionExpectation.fulfill()
        }
        XCTAssertTrue(navigatorSpy.setRoutesCalled)
        XCTAssertTrue(navigatorSpy.passedRoute === nativeRoute)
        XCTAssertEqual(navigatorSpy.passedUuid, routeController.sessionUUID)
        XCTAssertEqual(navigatorSpy.passedLegIndex, UInt32(routeController.routeProgress.legIndex))
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testHandleWillSwitchToAlternativeEvent() {
        routeController.rawLocation = rawLocation
        expectation(forNotification: .routeControllerWillTakeAlternativeRoute, object: routeController) { (notification) -> Bool in
            let userInfo = notification.userInfo
            let newLocation = userInfo?[RouteController.NotificationUserInfoKey.locationKey] as? CLLocation
            let newRoute = userInfo?[RouteController.NotificationUserInfoKey.routeKey] as? Route

            XCTAssertEqual(newLocation, self.rawLocation)
            XCTAssertEqual(newRoute, self.singleRouteResponse.routes?[0])

            return true
        }

        let callbackExpectation = expectation(description: "Will take alternative route should be called")
        delegate.onWillTakeAlternativeRoute = { newRoute, newLocation in
            XCTAssertEqual(newLocation, self.rawLocation)
            XCTAssertEqual(newRoute, self.singleRouteResponse.routes?[0])
            callbackExpectation.fulfill()
        }

        routeController.rerouteControllerWantsSwitchToAlternative(rerouteController,
                                                                  response: singleRouteResponse,
                                                                  routeIndex: 0,
                                                                  options: options,
                                                                  routeOrigin: .custom)
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testHandleDidSwitchToAlternativeEventIfSuccess() {
        routeController.rawLocation = rawLocation
        expectation(forNotification: .routeControllerDidTakeAlternativeRoute, object: routeController) { (notification) -> Bool in
            let newLocation = notification.userInfo?[RouteController.NotificationUserInfoKey.locationKey] as? CLLocation
            XCTAssertEqual(newLocation, self.rawLocation)
            return true
        }

        let callbackExpectation = expectation(description: "Did take alternative route should be called")
        delegate.onDidTakeAlternativeRoute = { newLocation in
            XCTAssertEqual(newLocation, self.rawLocation)
            callbackExpectation.fulfill()
        }
        routeController.rerouteControllerWantsSwitchToAlternative(rerouteController,
                                                                  response: singleRouteResponse,
                                                                  routeIndex: 0,
                                                                  options: options,
                                                                  routeOrigin: .custom)
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testHandleDidSwitchToAlternativeEventIfFailure() {
        routeController.rawLocation = rawLocation
        navigatorSpy.returnedSetRoutesResult = .failure(DirectionsError.noData)
        expectation(forNotification: .routeControllerDidFailToTakeAlternativeRoute, object: routeController) { (notification) -> Bool in
            let newLocation = notification.userInfo?[RouteController.NotificationUserInfoKey.locationKey] as? CLLocation
            XCTAssertEqual(newLocation, self.rawLocation)
            return true
        }

        let callbackExpectation = expectation(description: "Did fail to take alternative route should be called")
        delegate.onDidFailToTakeAlternativeRoute = { newLocation in
            XCTAssertEqual(newLocation, self.rawLocation)
            callbackExpectation.fulfill()
        }
        routeController.rerouteControllerWantsSwitchToAlternative(rerouteController,
                                                                  response: singleRouteResponse,
                                                                  routeIndex: 0,
                                                                  options: options,
                                                                  routeOrigin: .custom)
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testDoNotUpdateSpokenInstructionProgressIfNilVoiceInstruction() {
        let status = TestNavigationStatusProvider.createNavigationStatus()
        let notificationExpectation = expectation(forNotification: .routeControllerDidPassSpokenInstructionPoint, object: routeController)
        notificationExpectation.isInverted = true

        routeController.updateSpokenInstructionProgress(status: status, willReRoute: false)

        waitForExpectations(timeout: expectationsTimeout)
    }
    
    func testDoNotUpdateSpokenInstructionProgressIfWillReroute() {
        let voiceInstruction = VoiceInstruction(ssmlAnnouncement: "a", announcement: "b", remainingStepDistance: 10, index: 0)
        let status = TestNavigationStatusProvider.createNavigationStatus(voiceInstruction: voiceInstruction)
        let notificationExpectation = expectation(forNotification: .routeControllerDidPassSpokenInstructionPoint, object: routeController)
        notificationExpectation.isInverted = true

        routeController.updateSpokenInstructionProgress(status: status, willReRoute: true)

        waitForExpectations(timeout: expectationsTimeout)
    }

    func testUpdateSpokenInstructionProgress() {
        let voiceInstruction = VoiceInstruction(ssmlAnnouncement: "a", announcement: "b", remainingStepDistance: 10, index: 0)
        let status = TestNavigationStatusProvider.createNavigationStatus(voiceInstruction: voiceInstruction)
        let expectedSpokenInstruction = route.legs.first?.steps.first?.instructionsSpokenAlongStep?.first

        let callbackExpectation = expectation(description: "Did pass spoken instruction should be reported")
        delegate.onDidPassSpokenInstructionPoint = { spokenInstruction, routeProgress in
            XCTAssertEqual(spokenInstruction, expectedSpokenInstruction)
            XCTAssertTrue(routeProgress === self.routeController.routeProgress)
            callbackExpectation.fulfill()
        }

        expectation(forNotification: .routeControllerDidPassSpokenInstructionPoint, object: routeController) { (notification) -> Bool in
            let userInfo = notification.userInfo
            let routeProgress = userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress
            let spokenInstruction = userInfo?[RouteController.NotificationUserInfoKey.spokenInstructionKey] as? SpokenInstruction

            XCTAssertEqual(spokenInstruction, expectedSpokenInstruction)
            XCTAssertTrue(routeProgress === self.routeController.routeProgress)

            return true
        }

        routeController.updateSpokenInstructionProgress(status: status, willReRoute: false)

        XCTAssertFalse(routeController.didProactiveReroute)
        waitForExpectations(timeout: expectationsTimeout)
    }

    func testDoNotUpdateVisualInstructionProgressIfNilBannerInstruction() {
        let status = TestNavigationStatusProvider.createNavigationStatus()
        routeController.rawLocation = rawLocation
        let notificationExpectation = expectation(forNotification: .routeControllerDidPassSpokenInstructionPoint, object: routeController)
        notificationExpectation.isInverted = true

        routeController.updateVisualInstructionProgress(status: status)

        waitForExpectations(timeout: expectationsTimeout)
    }

    func testDoNotUpdateVisualInstructionProgressIfNilFirstLocation() {
        let status = TestNavigationStatusProvider.createNavigationStatus(bannerInstruction: bannerInstruction)
        let notificationExpectation = expectation(forNotification: .routeControllerDidPassSpokenInstructionPoint, object: routeController)
        notificationExpectation.isInverted = true

        routeController.updateVisualInstructionProgress(status: status)

        waitForExpectations(timeout: expectationsTimeout)
    }

    func testDoNotUpdateVisualInstructionProgressIfNilFirstLocationVisualInstruction() {
        let status = TestNavigationStatusProvider.createNavigationStatus(bannerInstruction: bannerInstruction)
        routeController.rawLocation = rawLocation
        let notificationExpectation = expectation(forNotification: .routeControllerDidPassSpokenInstructionPoint, object: routeController)
        notificationExpectation.isInverted = true

        routeController.updateVisualInstructionProgress(status: status)

        waitForExpectations(timeout: expectationsTimeout)
    }

    func testUpdateVisualInstructionProgress() {
        let routeResponse = makeRouteResponseWithBannerInstuctions()
        let indexedRouteResponse = IndexedRouteResponse(routeResponse: routeResponse, routeIndex: 0)
        let controller = makeRouteController(routeResponse: indexedRouteResponse)
        
        let status = TestNavigationStatusProvider.createNavigationStatus(bannerInstruction: bannerInstruction)
        let route = routeResponse.routes?[0]
        let expectedVisualInstruction = route?.legs.first?.steps.first?.instructionsDisplayedAlongStep?.first
        
        let callbackExpectation = expectation(description: "Did pass spoken instruction should be reported")
        delegate.onDidPassVisualInstructionPoint = { visualInstruction, routeProgress in
            XCTAssertEqual(visualInstruction, expectedVisualInstruction)
            XCTAssertTrue(routeProgress === controller.routeProgress)
            callbackExpectation.fulfill()
        }

        expectation(forNotification: .routeControllerDidPassVisualInstructionPoint, object: controller) { (notification) -> Bool in
            let userInfo = notification.userInfo
            let routeProgress = userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress
            let visualInstruction = userInfo?[RouteController.NotificationUserInfoKey.visualInstructionKey] as? VisualInstructionBanner

            XCTAssertEqual(visualInstruction, expectedVisualInstruction)
            XCTAssertTrue(routeProgress === controller.routeProgress)

            return true
        }

        controller.updateVisualInstructionProgress(status: status)
        waitForExpectations(timeout: expectationsTimeout)
    }
    
    // MARK: Helpers

    private func createRouteAlternative(id: UInt32) -> RouteAlternative {
        let intersectionStep = route.legs[0].steps[3]
        let intersection = RouteIntersection(location: intersectionStep.maneuverLocation,
                                             geometryIndex: 6,
                                             segmentIndex: 6,
                                             legIndex: 0)
        let routeInfo = AlternativeRouteInfo(distance: intersectionStep.distance, duration: intersectionStep.expectedTravelTime)
        return .init(id: id,
                     route: TestRouteProvider.createRoute(routeResponse: routeResponse)!,
                     mainRouteFork: intersection,
                     alternativeRouteFork: intersection,
                     infoFromFork: routeInfo,
                     infoFromStart: routeInfo,
                     isNew: true)
    }

    private func makeRouteController(routeResponse: IndexedRouteResponse? = nil) -> RouteController {
        return makeRouteController(routeResponse: routeResponse,
                                   routingProvider: routingProvider)
    }

    private func makeRouteController(routeResponse: IndexedRouteResponse? = nil,
                                     routingProvider: RoutingProvider?) -> RouteController {
        let controller = RouteController(indexedRouteResponse: routeResponse ?? indexedRouteResponse,
                                         customRoutingProvider: routingProvider,
                                         dataSource: dataSource,
                                         navigatorType: CoreNavigatorSpy.self,
                                         routeParserType: RouteParserSpy.self)
        controller.delegate = delegate
        navigatorSpy.reset()
        return controller
    }

    private func makeRouteResponse() -> RouteResponse {
        return Fixture.routeResponse(from: "routeResponseWithAlternatives", options: options)
    }

    private func makeSingleRouteResponse() -> RouteResponse {
        let routeOptions = options
        routeOptions.shapeFormat = .polyline
        return Fixture.routeResponse(from: "route", options: routeOptions)
    }

    private func makeMultilegRouteResponse() -> RouteResponse {
        let routeOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 9.519172, longitude: 47.210823),
            CLLocationCoordinate2D(latitude: 9.52222, longitude: 47.214268),
            CLLocationCoordinate2D(latitude: 47.212326, longitude: 9.512569),
        ])
        return Fixture.routeResponse(from: "multileg-route", options: routeOptions)
    }

    private func makeRouteResponseWithBannerInstuctions() -> RouteResponse {
        let routeOptions = options
        routeOptions.shapeFormat = .polyline
        return Fixture.routeResponse(from: "routeWithInstructions", options: routeOptions)
    }

    private func makeActiveGuidanceInfo() -> ActiveGuidanceInfo {
        let routeProgress = ActiveGuidanceProgress(distanceTraveled: 110,
                                                   fractionTraveled: 0.11,
                                                   remainingDistance: 890,
                                                   remainingDuration: 2000)
        let legProgress = ActiveGuidanceProgress(distanceTraveled: 100,
                                                 fractionTraveled: 0.9,
                                                 remainingDistance: 200,
                                                 remainingDuration: 2000)
        let stepProgress = ActiveGuidanceProgress(distanceTraveled: 10,
                                                  fractionTraveled: 0.25,
                                                  remainingDistance: 30,
                                                  remainingDuration: 200)
        return ActiveGuidanceInfo(routeProgress: routeProgress,
                                  legProgress: legProgress,
                                  step: stepProgress)
    }
}
