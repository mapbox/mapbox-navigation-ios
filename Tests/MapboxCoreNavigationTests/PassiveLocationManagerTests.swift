import MapboxDirections
import MapboxNavigationNative
import XCTest
@testable import TestHelper
@testable import MapboxCoreNavigation

class PassiveLocationManagerTests: TestCase {
    private let location = CLLocation(latitude: 47.208674, longitude: 9.524650)

    private var directionsSpy: DirectionsSpy!
    private var eventsManagerType: NavigationEventsManagerSpy!
    private var navigatorSpy: CoreNavigatorSpy!
    private var locationManagerSpy: NavigationLocationManagerSpy!

    private var passiveLocationManager: PassiveLocationManager!
    private var delegate: PassiveLocationManagerDelegateSpy!
    
    override func setUp() {
        super.setUp()

        let bundle = Bundle(for: Fixture.self)
        let filePathURL: URL = URL(fileURLWithPath: bundle.bundlePath.appending("/tiles/liechtenstein"))

        let settingsValues = NavigationSettings.Values(directions: .mocked,
                                                       tileStoreConfiguration: TileStoreConfiguration(navigatorLocation: .custom(filePathURL), mapLocation: nil),
                                                       routingProviderSource: .offline,
                                                       alternativeRouteDetectionStrategy: .init())
        NavigationSettings.shared.initialize(with: settingsValues)

        locationManagerSpy = .init()
        directionsSpy = .init()
        navigatorSpy = CoreNavigatorSpy.shared
        passiveLocationManager = PassiveLocationManager(directions: directionsSpy,
                                                        systemLocationManager: locationManagerSpy,
                                                        eventsManagerType: NavigationEventsManagerSpy.self,
                                                        userInfo: [:],
                                                        datasetProfileIdentifier: .cycling,
                                                        navigatorType: CoreNavigatorSpy.self)
        delegate = PassiveLocationManagerDelegateSpy()
        passiveLocationManager.delegate = delegate
    }
    
    override func tearDown() {
        super.tearDown()
        PassiveLocationManager.historyDirectoryURL = nil
        HistoryRecorder._recreateHistoryRecorder()
    }

    func testHandleDidUpdateLocations() {
        passiveLocationManager.locationManager(locationManagerSpy, didUpdateLocations: [location])

        let eventsManagerSpy = passiveLocationManager.eventsManager as! NavigationEventsManagerSpy
        XCTAssertTrue(eventsManagerSpy.hasImmediateEvent(with: EventType.freeDrive.rawValue))
    }

    func testHandleDidUpdateHeading() {
        let callbackExpectation = expectation(description: "Heading Callback")
        let heading = CLHeading(heading: 50, accuracy: 1)!
        delegate.onHeadingUpdate = { actualHeading in
            XCTAssertEqual(actualHeading, heading)
            callbackExpectation.fulfill()
        }

        passiveLocationManager.locationManager(locationManagerSpy, didUpdateHeading: heading)
        wait(for: [callbackExpectation], timeout: 0.5)
    }

    func testHandleDidFail() {
        let callbackExpectation = expectation(description: "Fail Callback")
        let error = PassiveLocationManagerError.failedToChangeLocation
        delegate.onError = { actualError in
            XCTAssertEqual(actualError as! PassiveLocationManagerError, error)
            callbackExpectation.fulfill()
        }

        passiveLocationManager.locationManager(locationManagerSpy, didFailWithError: error)
        wait(for: [callbackExpectation], timeout: 0.5)
    }

    func testHandleDidChangeAuthorization() {
        guard #available(iOS 14.0, *) else { return }

        let callbackExpectation = expectation(description: "Authorization Callback")
        callbackExpectation.assertForOverFulfill = false
        delegate.onAuthorizationChange = {
            callbackExpectation.fulfill()
        }

        passiveLocationManager.locationManager(locationManagerSpy, didChangeAuthorization: .authorizedAlways)
        wait(for: [callbackExpectation], timeout: 0.5)
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
        XCTAssertNil(navigatorSpy.passedLocation)
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
        XCTAssertEqual(navigatorSpy.passedLocation, location)

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
        let options = MapboxCoreNavigation.ElectronicHorizonOptions(length: 100,
                                                                    expansionLevel: 10,
                                                                    branchLength: 100,
                                                                    minTimeDeltaBetweenUpdates: nil)
        passiveLocationManager.startUpdatingElectronicHorizon(with: options)
        XCTAssertTrue(navigatorSpy.startUpdatingElectronicHorizonCalled)
        XCTAssertNotNil(navigatorSpy.passedElectronicHorizonOptions)
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

    func testHandleNotificationNavigationStatusDidChangeIfIncorrectStatusNotCrash() {
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

        expectation(forNotification: .passiveLocationManagerDidUpdate, object: passiveLocationManager) { (notification) -> Bool in
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
            XCTAssertEqual(newLocation?.coordinate, CLLocation(status.location).coordinate)
            XCTAssertEqual(rawLocation, self.location)
            XCTAssertEqual(roadName, "name")
            XCTAssertEqual(matches, expectedMatches)
            XCTAssertEqual(routeShieldRepresentation, status.routeShieldRepresentation)
            XCTAssertNotNil(mapMatchingResult)
            XCTAssertEqual(speedLimit, expectedSpeedLimit)
            XCTAssertEqual(signStandard, .mutcd)
            
            return true
        }

        let userInfo = [Navigator.NotificationUserInfoKey.statusKey : status]
        NotificationCenter.default.post(name: .navigationStatusDidChange, object: nil, userInfo: userInfo)

        XCTAssertEqual(passiveLocationManager.location?.coordinate, CLLocation(status.location).coordinate)
        waitForExpectations(timeout: 0.5)
    }

    func testHandleNotificationNavigationStatusDidChangeIfViennaConvention() {
        passiveLocationManager.updateLocation(location)

        let originalSpeedLimit = SpeedLimit(speedKmph: 120, localeUnit: .kilometresPerHour, localeSign: .vienna)
        let status = navigationStatus(with: originalSpeedLimit)

        expectation(forNotification: .passiveLocationManagerDidUpdate, object: passiveLocationManager) { (notification) -> Bool in
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

        waitForExpectations(timeout: 0.5)
    }

    func testHandleNotificationNavigationStatusDidChangeIfNilSpeedLimit() {
        passiveLocationManager.updateLocation(location)
        let status = navigationStatus()

        expectation(forNotification: .passiveLocationManagerDidUpdate, object: passiveLocationManager) { (notification) -> Bool in
            let userInfo = notification.userInfo

            XCTAssertNil(userInfo?[PassiveLocationManager.NotificationUserInfoKey.speedLimitKey])
            XCTAssertNil(userInfo?[PassiveLocationManager.NotificationUserInfoKey.signStandardKey])

            return true
        }

        let userInfo = [Navigator.NotificationUserInfoKey.statusKey : status]
        NotificationCenter.default.post(name: .navigationStatusDidChange, object: nil, userInfo: userInfo)

        waitForExpectations(timeout: 0.5)
    }

    func testCallDelegateDidUpdateLocation() {
        let callbackExpectation = expectation(description: "Progress Callback")
        let status = navigationStatus()
        passiveLocationManager.updateLocation(location)

        delegate.onProgressUpdate = { (location, rawLocation) in
            XCTAssertEqual(location.coordinate, CLLocation(status.location).coordinate)
            XCTAssertEqual(rawLocation, self.location)
            callbackExpectation.fulfill()
        }

        let userInfo = [Navigator.NotificationUserInfoKey.statusKey : status]
        NotificationCenter.default.post(name: .navigationStatusDidChange, object: nil, userInfo: userInfo)
        wait(for: [callbackExpectation], timeout: 0.5)
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

    func testManagerDelegate() {
        XCTAssertTrue(locationManagerSpy.delegate === passiveLocationManager)
    }

    func testSetDatasetProfileIdentifier() {
        _ = PassiveLocationManager(directions: directionsSpy,
                                   systemLocationManager: locationManagerSpy,
                                   eventsManagerType: NavigationEventsManagerSpy.self,
                                   userInfo: [:],
                                   datasetProfileIdentifier: .walking,
                                   navigatorType: CoreNavigatorSpy.self)
        XCTAssertEqual(CoreNavigatorSpy.datasetProfileIdentifier, .walking)
    }

    func testCreateDefaultManager() {
        let manager = PassiveLocationManager(datasetProfileIdentifier: .walking)
        XCTAssertEqual(manager.directions, NavigationSettings.shared.directions)
        XCTAssertEqual(manager.navigator, Navigator.shared.navigator)
    }

    private func navigationStatus(with speedLimit: SpeedLimit? = nil) -> NavigationStatus {
        return TestNavigationStatusProvider.createNavigationStatus(speedLimit: speedLimit)
    }
}
