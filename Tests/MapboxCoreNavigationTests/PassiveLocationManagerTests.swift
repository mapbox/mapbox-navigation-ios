import MapboxDirections
import MapboxNavigationNative
import XCTest
@testable import TestHelper
@testable import MapboxCoreNavigation

class Road {
    let from: CLLocationCoordinate2D
    let to: CLLocationCoordinate2D
    let length: Double

    init(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        self.from = from
        self.to = to
        self.length = (to - from).length()
    }

    func whichCloser(a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        return proximity(of: a) > proximity(of: b) ? b : a
    }

    func proximity(of: CLLocationCoordinate2D) -> Double {
        return ((of - from).length() + (of - to).length()) / length
    }
}

extension CLLocationCoordinate2D {
    static func -(a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: a.latitude - b.latitude, longitude: a.longitude - b.longitude)
    }

    func length() -> Double {
        return sqrt(latitude * latitude + longitude * longitude)
    }
}

class PassiveLocationManagerTests: TestCase {
    private var locationManagerSpy: NavigationLocationManagerSpy!

    class Delegate: PassiveLocationManagerDelegate {
        let road: Road
        let locationUpdateExpectation: XCTestExpectation
        
        init(road: Road, locationUpdateExpectation: XCTestExpectation) {
            self.road = road
            self.locationUpdateExpectation = locationUpdateExpectation
        }
        
        func passiveLocationManagerDidChangeAuthorization(_ manager: PassiveLocationManager) {
        }
        
        func passiveLocationManager(_ manager: PassiveLocationManager, didUpdateLocation location: CLLocation, rawLocation: CLLocation) {
            print("Got location: \(rawLocation.coordinate.latitude), \(rawLocation.coordinate.longitude) → \(location.coordinate.latitude), \(location.coordinate.longitude)")
            print("Value: \(road.proximity(of: location.coordinate)) should be less or equal to \(road.proximity(of: rawLocation.coordinate))")

            XCTAssert(road.proximity(of: location.coordinate) <= road.proximity(of: rawLocation.coordinate), "Raw Location wasn't mapped to a road")
        }
        
        func passiveLocationManager(_ manager: PassiveLocationManager, didUpdateHeading newHeading: CLHeading) {
        }
        
        func passiveLocationManager(_ manager: PassiveLocationManager, didFailWithError error: Error) {
        }
    }

    private let location = CLLocation(latitude: 47.208674, longitude: 9.524650)

    private var directionsSpy: DirectionsSpy!
    private var eventsManagerType: NavigationEventsManagerSpy!
    private var navigatorSpy: NavigatorSpy!

    private var passiveLocationManager: PassiveLocationManager!
    private var delegate: PassiveLocationManagerDelegateSpy!
    
    override func setUp() {
        super.setUp()

        let bundle = Bundle(for: Fixture.self)
        let filePathURL: URL = URL(fileURLWithPath: bundle.bundlePath.appending("/tiles/liechtenstein"))
        NavigationSettings.shared.initialize(directions: .mocked, tileStoreConfiguration: TileStoreConfiguration(navigatorLocation: .custom(filePathURL), mapLocation: nil), routingProviderSource: .offline, alternativeRouteDetectionStrategy: .init())

        locationManagerSpy = NavigationLocationManagerSpy()
        directionsSpy = DirectionsSpy()
        navigatorSpy = NavigatorSpy()
        passiveLocationManager = PassiveLocationManager(directions: directionsSpy,
                                                        systemLocationManager: locationManagerSpy,
                                                        eventsManagerType: NavigationEventsManagerSpy.self,
                                                        userInfo: [:],
                                                        datasetProfileIdentifier: .cycling,
                                                        sharedNavigator: navigatorSpy)
        delegate = PassiveLocationManagerDelegateSpy()
        passiveLocationManager.delegate = delegate
    }
    
    override func tearDown() {
        super.tearDown()
        PassiveLocationManager.historyDirectoryURL = nil
        NavigationSettings.shared.initialize(directions: .mocked, tileStoreConfiguration: TileStoreConfiguration(navigatorLocation: .default, mapLocation: nil), routingProviderSource: .hybrid, alternativeRouteDetectionStrategy: .init())
        HistoryRecorder._recreateHistoryRecorder()
    }

    func testHandleDidUpdateLocations() {
        passiveLocationManager.locationManager(locationManagerSpy, didUpdateLocations: [location])

        let eventsManagerSpy = passiveLocationManager.eventsManager as! NavigationEventsManagerSpy
        XCTAssertTrue(eventsManagerSpy.hasImmediateEvent(with: EventType.freeDrive.rawValue))
    }

    func testHandleDidUpdateHeading() {
        let callbackExpectation = expectation(description: "Callback")
        let heading = CLHeading(heading: 50, accuracy: 1)!
        delegate.onHeadingUpdate = { actualHeading in
            XCTAssertEqual(actualHeading, heading)
            callbackExpectation.fulfill()
        }

        passiveLocationManager.locationManager(locationManagerSpy, didUpdateHeading: heading)
        wait(for: [callbackExpectation], timeout: 2)
    }

    func testHandleDidFail() {
        let callbackExpectation = expectation(description: "Callback")
        let error = PassiveLocationManagerError.failedToChangeLocation
        delegate.onError = { actualError in
            XCTAssertEqual(actualError as! PassiveLocationManagerError, error)
            callbackExpectation.fulfill()
        }

        passiveLocationManager.locationManager(locationManagerSpy, didFailWithError: error)
        wait(for: [callbackExpectation], timeout: 2)
    }

    func testReturnLocation() {
        XCTAssertNil(passiveLocationManager.location)

        let rawLocation = CLLocation(latitude: 47.208674, longitude: 9.524650)
        passiveLocationManager.updateLocation(rawLocation)
        XCTAssertEqual(passiveLocationManager.location, rawLocation)

        let snappedLocation = CLLocation(latitude: 37.208674, longitude: 19.524650)
        passiveLocationManager.snappedLocation = snappedLocation
        XCTAssertEqual(passiveLocationManager.location, snappedLocation)
    }

    func testReturnTileStore() {
        XCTAssertEqual(passiveLocationManager.navigatorTileStore, navigatorSpy.tileStore)
    }

    func testReturnNativeNavigator() {
        XCTAssertEqual(passiveLocationManager.navigator, navigatorSpy.navigator)
    }

    func testStartNavigation() {
        passiveLocationManager.startUpdatingLocation()
        XCTAssertTrue(locationManagerSpy.startUpdatingLocationCalled)
    }

    func testDidNoThrowIfDidUpdateNilLocation() {
        XCTAssertNoThrow(passiveLocationManager.updateLocation(nil))
        XCTAssertNil(navigatorSpy.location)
    }

    func testUpdatedLocationIfSuccess() {
        passiveLocationManager.updateLocation(location) { result in
            guard case .success(let updatedLocation) = result else {
                return XCTFail("Expected a success but got a failure with \(result)")
            }
            XCTAssertEqual(updatedLocation, self.location)
        }
        XCTAssertTrue(locationManagerSpy.stopUpdatingLocationCalled)
        XCTAssertTrue(locationManagerSpy.stopUpdatingHeadingCalled)

        XCTAssertTrue(navigatorSpy.updateLocationCalled)
        XCTAssertEqual(navigatorSpy.location, location)

        let eventsManagerSpy = passiveLocationManager.eventsManager as! NavigationEventsManagerSpy
        XCTAssertTrue(eventsManagerSpy.hasImmediateEvent(with: EventType.freeDrive.rawValue))

        eventsManagerSpy.reset()
        passiveLocationManager.updateLocation(location)
        XCTAssertFalse(eventsManagerSpy.hasImmediateEvent(with: EventType.freeDrive.rawValue), "Do not report navigation twice")
    }

    func testUpdatedLocationIfFailure() {
        navigatorSpy.onUpdateLocation = { passedLocation in
            XCTAssertEqual(passedLocation, self.location)
            return false
        }
        passiveLocationManager.updateLocation(location) { result in
            guard case .failure(let error) = result else {
                return XCTFail("Expected a failure but got a success with \(result)")
            }
            XCTAssertEqual(error as! PassiveLocationManagerError, PassiveLocationManagerError.failedToChangeLocation)
        }
        let eventsManagerSpy = passiveLocationManager.eventsManager as! NavigationEventsManagerSpy
        XCTAssertTrue(eventsManagerSpy.hasImmediateEvent(with: EventType.freeDrive.rawValue))
    }

    func testUpdatedLocationNoRunningBillingSession() {
        BillingHandler.__replaceSharedInstance(with: BillingHandler.__createMockedHandler(with: billingServiceMock))
        passiveLocationManager.updateLocation(location) { result in
            guard case .failure(let error) = result else {
                return XCTFail("Expected a failure but got a success with \(result)")
            }
            XCTAssertEqual(error as! PassiveLocationManagerError, PassiveLocationManagerError.sessionIsNotRunning)
        }
        XCTAssertFalse(navigatorSpy.updateLocationCalled)
    }

    func testStartTripSessionWhenCreated() {
        billingServiceMock.assertEvents([.beginBillingSession(.freeDrive)])
    }

    func testPauseTripSession() {
        passiveLocationManager.pauseTripSession()
        let expectedEvents: [BillingServiceMock.Event] = [
            .beginBillingSession(.freeDrive),
            .pauseBillingSession(.freeDrive)
        ]
        billingServiceMock.assertEvents(expectedEvents)
    }

    func testResumeTripSession() {
        passiveLocationManager.pauseTripSession()
        passiveLocationManager.resumeTripSession()
        let expectedEvents: [BillingServiceMock.Event] = [
            .beginBillingSession(.freeDrive),
            .pauseBillingSession(.freeDrive),
            .resumeBillingSession(.freeDrive)
        ]
        billingServiceMock.assertEvents(expectedEvents)
    }

    func testStartUpdatingElectronicHorizon() {
        let options: MapboxCoreNavigation.ElectronicHorizonOptions = .init(length: 100,
                                                                           expansionLevel: 10,
                                                                           branchLength: 100,
                                                                           minTimeDeltaBetweenUpdates: nil)
        passiveLocationManager.startUpdatingElectronicHorizon(with: options)
        XCTAssertTrue(navigatorSpy.startUpdatingElectronicHorizonCalled)
        XCTAssertNotNil(navigatorSpy.electronicHorizonOptions)
    }

    func testStopUpdatingElectronicHorizon() {
        passiveLocationManager.stopUpdatingElectronicHorizon()
        XCTAssertTrue(navigatorSpy.stopUpdatingElectronicHorizonCalled)
    }

    func testReturnRoadGraph() {
        XCTAssertTrue(passiveLocationManager.roadGraph === navigatorSpy.roadGraph)
    }

    func testReturnRoadObjectStore() {
        XCTAssertTrue(passiveLocationManager.roadObjectStore === navigatorSpy.roadObjectStore)
    }

    func testReturnRoadObjectMatcher() {
        XCTAssertTrue(passiveLocationManager.roadObjectMatcher === navigatorSpy.roadObjectMatcher)
    }

    func testHandleNotificationNavigationStatusDidChangeIfIncorrectStatus() {
        let userInfo = [Navigator.NotificationUserInfoKey.statusKey : "status"]
        NotificationCenter.default.post(name: .navigationStatusDidChange, object: nil, userInfo: userInfo)
    }

    func testHandleNotificationNavigationStatusDidChangeIfNilRawLocation() {
        let status = navigationStatus()
        let userInfo = [Navigator.NotificationUserInfoKey.statusKey : status]
        NotificationCenter.default.post(name: .navigationStatusDidChange, object: nil, userInfo: userInfo)

        XCTAssertNil(passiveLocationManager.location)
    }

    func testHandleNotificationNavigationStatusDidChange() {
        passiveLocationManager.updateLocation(location)

        let originalSpeedLimit = SpeedLimit(speedKmph: 120, localeUnit: .milesPerHour, localeSign: .mutcd)
        let status = navigationStatus(with: originalSpeedLimit)

        expectation(forNotification: .passiveLocationManagerDidUpdate, object: nil) { (notification) -> Bool in
            let userInfo = notification.userInfo
            let newLocation = userInfo?[PassiveLocationManager.NotificationUserInfoKey.locationKey] as? CLLocation
            let rawLocation = userInfo?[PassiveLocationManager.NotificationUserInfoKey.rawLocationKey] as? CLLocation
            let roadName = userInfo?[PassiveLocationManager.NotificationUserInfoKey.roadNameKey] as? String
            let matches = userInfo?[PassiveLocationManager.NotificationUserInfoKey.matchesKey] as? [Match]
            let routeShieldRepresentation = userInfo?[PassiveLocationManager.NotificationUserInfoKey.routeShieldRepresentationKey] as?  VisualInstruction.Component.ImageRepresentation
            let mapMatchingResult = userInfo?[PassiveLocationManager.NotificationUserInfoKey.mapMatchingResultKey] as? MapMatchingResult
            let speedLimit = userInfo?[PassiveLocationManager.NotificationUserInfoKey.speedLimitKey] as? Measurement<UnitSpeed>
            let signStandard = userInfo?[PassiveLocationManager.NotificationUserInfoKey.signStandardKey] as? SignStandard

            let expectedSpeedLimit = Measurement<UnitSpeed>(value: originalSpeedLimit.speedKmph as! Double,
                                                            unit: .kilometersPerHour).converted(to: .milesPerHour)
            let expectedMatches = [Match(legs: [],
                                         shape: nil,
                                         distance: -1,
                                         expectedTravelTime: -1,
                                         confidence: 42,
                                         weight: .routability(value: 1))]
            let imageBaseURL = URL(string: "base image url")
            let expectedRouteShieldRepresentation = VisualInstruction.Component.ImageRepresentation(imageBaseURL: imageBaseURL,
                                                                                                    shield: nil)

            XCTAssertEqual(newLocation?.coordinate, CLLocation(status.location).coordinate)
            XCTAssertEqual(rawLocation, self.location)
            XCTAssertEqual(roadName, "name")
            XCTAssertEqual(matches, expectedMatches)
            XCTAssertEqual(routeShieldRepresentation, expectedRouteShieldRepresentation)
            XCTAssertNotNil(mapMatchingResult)
            XCTAssertEqual(speedLimit, expectedSpeedLimit)
            XCTAssertEqual(signStandard, .mutcd)
            
            return true
        }

        let userInfo = [Navigator.NotificationUserInfoKey.statusKey : status]
        NotificationCenter.default.post(name: .navigationStatusDidChange, object: nil, userInfo: userInfo)

        XCTAssertEqual(passiveLocationManager.location?.coordinate, CLLocation(status.location).coordinate)
        waitForExpectations(timeout: 2)
    }

    func testHandleNotificationNavigationStatusDidChangeIfviennaConvention() {
        passiveLocationManager.updateLocation(location)

        let originalSpeedLimit = SpeedLimit(speedKmph: 120, localeUnit: .kilometresPerHour, localeSign: .vienna)
        let status = navigationStatus(with: originalSpeedLimit)

        expectation(forNotification: .passiveLocationManagerDidUpdate, object: nil) { (notification) -> Bool in
            let userInfo = notification.userInfo
            let speedLimit = userInfo?[PassiveLocationManager.NotificationUserInfoKey.speedLimitKey] as? Measurement<UnitSpeed>
            let signStandard = userInfo?[PassiveLocationManager.NotificationUserInfoKey.signStandardKey] as? SignStandard

            let expectedSpeedLimit = Measurement<UnitSpeed>(value: originalSpeedLimit.speedKmph as! Double,
                                                            unit: .kilometersPerHour)

            XCTAssertEqual(speedLimit, expectedSpeedLimit)
            XCTAssertEqual(signStandard, .viennaConvention)

            return true
        }

        let userInfo = [Navigator.NotificationUserInfoKey.statusKey : status]
        NotificationCenter.default.post(name: .navigationStatusDidChange, object: nil, userInfo: userInfo)

        waitForExpectations(timeout: 2)
    }

    func testHandleNotificationNavigationStatusDidChangeIfNilSpeedLimit() {
        passiveLocationManager.updateLocation(location)
        let status = navigationStatus()

        expectation(forNotification: .passiveLocationManagerDidUpdate, object: nil) { (notification) -> Bool in
            let userInfo = notification.userInfo

            XCTAssertNil(userInfo?[PassiveLocationManager.NotificationUserInfoKey.speedLimitKey])
            XCTAssertNil(userInfo?[PassiveLocationManager.NotificationUserInfoKey.signStandardKey])

            return true
        }

        let userInfo = [Navigator.NotificationUserInfoKey.statusKey : status]
        NotificationCenter.default.post(name: .navigationStatusDidChange, object: nil, userInfo: userInfo)

        waitForExpectations(timeout: 2)
    }

    func testManualLocations() {
        let locationUpdateExpectation = expectation(description: "Location manager takes some time to start mapping locations to a road graph")
        locationUpdateExpectation.expectedFulfillmentCount = 1
        
        let road = Road(from: CLLocationCoordinate2D(latitude: 47.207966, longitude: 9.527012), to: CLLocationCoordinate2D(latitude: 47.209518, longitude: 9.522167))
        let delegate = Delegate(road: road, locationUpdateExpectation: locationUpdateExpectation)
        let date = Date()
        let locationManager = PassiveLocationManager()
        locationManager.updateLocation(CLLocation(latitude: 47.208674, longitude: 9.524650, timestamp: date.addingTimeInterval(-5)))
        locationManager.delegate = delegate
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            Navigator.shared.navigator.reset {
                locationManager.updateLocation(CLLocation(latitude: 47.208943, longitude: 9.524707, timestamp: date.addingTimeInterval(-4)))
                locationManager.updateLocation(CLLocation(latitude: 47.209082, longitude: 9.524319, timestamp: date.addingTimeInterval(-3)))
                locationManager.updateLocation(CLLocation(latitude: 47.209229, longitude: 9.523838, timestamp: date.addingTimeInterval(-2)))
                locationManager.updateLocation(CLLocation(latitude: 47.209612, longitude: 9.522629, timestamp: date.addingTimeInterval(-1)))
                locationManager.updateLocation(CLLocation(latitude: 47.209842, longitude: 9.522377, timestamp: date.addingTimeInterval(0)))

                locationUpdateExpectation.fulfill()
            }
        }
        wait(for: [locationUpdateExpectation], timeout: 5)
    }
    
    func testNoHistoryRecording() {
        PassiveLocationManager.historyDirectoryURL = nil
        PassiveLocationManager.startRecordingHistory()
                
        let historyCallbackExpectation = XCTestExpectation(description: "History callback should be called")
        PassiveLocationManager.stopRecordingHistory { url in
            XCTAssertNil(url)
            historyCallbackExpectation.fulfill()
        }
        wait(for: [historyCallbackExpectation], timeout: 3)
    }
    
    func testHistoryRecording() {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("test")
        
        PassiveLocationManager.historyDirectoryURL = supportDir
        withExtendedLifetime(HistoryRecorder.shared) { _ in
            PassiveLocationManager.startRecordingHistory()

            let historyCallbackExpectation = XCTestExpectation(description: "History callback should be called")
            PassiveLocationManager.stopRecordingHistory { url in
                XCTAssertNotNil(url)
                historyCallbackExpectation.fulfill()
            }
            wait(for: [historyCallbackExpectation], timeout: 3)
        }
    }

    private func navigationStatus(with speedLimit: SpeedLimit? = nil) -> NavigationStatus {
        let location = FixLocation(CLLocation(latitude: 37.788443, longitude: -122.4020258))
        let road = MapboxNavigationNative.Road(text: "name", imageBaseUrl: "base image url", shield: nil)
        let mapMatch = MapMatch(position: .init(edgeId: 0, percentAlong: 0), proba: 42)
        let mapMatcherOutput = MapMatcherOutput(matches: [mapMatch], isTeleport: false)
        return .init(routeState: .tracking,
                                                          locatedAlternativeRouteId: nil,
                                                          stale: false,
                                                          location: location,
                                                          routeIndex: 0,
                                                          legIndex: 0,
                                                          step: 0,
                                                          isFallback: false,
                                                          inTunnel: false,
                                                          predicted: 10,
                                                          geometryIndex: 0,
                                                          shapeIndex: 0,
                                                          intersectionIndex: 0,
                                                          roads: [road],
                                                          voiceInstruction: nil,
                                                          bannerInstruction: nil,
                                                          speedLimit: speedLimit,
                                                          keyPoints: [],
                                                          mapMatcherOutput: mapMatcherOutput,
                                                          offRoadProba: 0,
                                                          activeGuidanceInfo: nil,
                                                          upcomingRouteAlerts: [],
                                                          nextWaypointIndex: 0,
                                                          layer: nil)
    }
}

private extension CLLocation {
    convenience init(latitude: CLLocationDegrees, longitude: CLLocationDegrees, timestamp: Date) {
        self.init(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: 0,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            timestamp: timestamp
        )
    }
}
