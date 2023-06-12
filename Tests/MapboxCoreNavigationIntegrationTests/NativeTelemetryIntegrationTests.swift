import XCTest
import MapboxDirections
import MapboxNavigationNative
import CoreLocation
import AVFoundation
import Polyline
@testable import TestHelper
@_implementationOnly import MapboxCommon_Private
@testable @_spi(MapboxInternal) import MapboxCoreNavigation

class NativeTelemetryIntegrationTests: TestCase {
    let expectationsTimeout: Double = 2
    var navigationService: NavigationService!
    var locationManager: ReplayLocationManager!
    var passiveLocationManager: PassiveLocationManager!

    var indexedRouteResponse: IndexedRouteResponse!
    var route: Route!
    var routeResponse: RouteResponse!
    var alternateRouteResponse: RouteResponse!
    var alternateRoute: Route!

    var directions: Directions!
    var navigator: MapboxCoreNavigation.Navigator!
    var eventsAPI: EventsService!
    var telemetryObserver: TelemetryObserver!
    let userInfo = [
        "userId": "user_id_value",
        "sessionId": "session_id_value",
        "name": "name_value",
        "version": "version_value",
    ]
    var dictionaryUserInfo: NSDictionary {
        NSDictionary(dictionary: userInfo)
    }

    private var device: UIDevice { UIDevice.current }
    private var screenBrightness: Int { Int(UIScreen.main.brightness * 100) }
    private var deviceString: String { "\(device.model) (\(cpu); Simulator)" }
    private var platformName: String { device.systemName }
    private var platformVersion: String { ProcessInfo.processInfo.operatingSystemVersionString }
    private var volumeLevel: Int { Int(AVAudioSession.sharedInstance().outputVolume * 100) }
    private var batteryPluggedIn: Bool { [.charging, .full].contains(UIDevice.current.batteryState) }

    private var geometry: String!

    override func setUp() {
        super.setUp()

        NavigationTelemetryConfiguration.useNavNativeTelemetryEvents = true
        directions = .mocked
        configureEventsObserver()

        let routeOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 9.519172, longitude: 47.210823),
            CLLocationCoordinate2D(latitude: 9.52222, longitude: 47.214268),
            CLLocationCoordinate2D(latitude: 47.212326, longitude: 9.512569),
        ])
        routeOptions.includesAlternativeRoutes = false
        let jsonFileName = "multileg-route"
        routeResponse = Fixture.routeResponse(from: jsonFileName, options: routeOptions)
        let responseData = Fixture.JSONFromFileNamed(name: "multileg-route")
        let json = try? JSONSerialization.jsonObject(with: responseData, options: .allowFragments) as? [String: Any]
        let routesData = json?["routes"] as? [[String: Any]]
        let geometryRawValue = (routesData?[0]["geometry"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\", with: "\\\\") ?? ""
        geometry = "\"" + geometryRawValue + "\""
        route = routeResponse.routes!.first!
        indexedRouteResponse = IndexedRouteResponse(routeResponse: routeResponse, routeIndex: 0)
        alternateRouteResponse = Fixture.routeResponse(from: jsonFileName, options: routeOptions)
        alternateRoute = Fixture.route(from: jsonFileName, options: routeOptions)

        let customConfig = ["telemetry": ["eventsPriority": "Immediate"]]
        UserDefaults.standard.set(customConfig, forKey: customConfigKey)

        UserDefaults.standard.set("Location Usage Description", forKey: "NSLocationWhenInUseUsageDescription")
        UserDefaults.standard.set("Location Usage Description", forKey: "NSLocationAlwaysAndWhenInUseUsageDescription")

        Navigator.shared.rerouteController.reroutesProactively = false

        let steps = route.legs[0].steps
        var coordinates: [CLLocationCoordinate2D] = []
        if let firstStep = steps[0].shape, let secondStep = steps[1].shape {
            coordinates = firstStep.coordinates + secondStep.coordinates.prefix(1)
        }

        locationManager = ReplayLocationManager(locations: coordinates
            .map { CLLocation(coordinate: $0) }
            .shiftedToPresent())

        locationManager.speedMultiplier = 10
        navigator = .shared
    }

    override func tearDown() {
        Navigator.shared.rerouteController.reroutesProactively = true
        navigationService = nil
        passiveLocationManager = nil
        navigator = nil
        UserDefaults.resetStandardUserDefaults()
        eventsAPI.unregisterObserver(for: telemetryObserver)
        telemetryObserver = nil
        NavigationSessionManagerImp.shared.reportStopNavigation()
        NavigationTelemetryConfiguration.useNavNativeTelemetryEvents = false

        super.tearDown()
    }

    func testStartFreeDrive() {
        let firstLocation = locationManager.locations.first!
        telemetryObserver.expectedEvents = [
            freeDriveEvent(eventType: "start", coordinate: firstLocation.coordinate)
        ]

        startPassiveNavigation()

        wait(for: [telemetryObserver.expectation], timeout: expectationsTimeout)
    }

    // Tracking issue: NAVIOS-1240
    func disabled_testStartActiveNavigation() {
        updateLocation()
        let firstLocation = locationManager.locations.first!
        configureActiveNavigation()

        var activeAttributesKeys = activeNoValueCheckAttributesKeys
        activeAttributesKeys.insert("locationsAfter")
        telemetryObserver.expectedEvents = [
            activeNavigationEvent(eventName: "navigation.navigationStateChanged",
                                  state: "navigation_started",
                                  routeProgress: navigationService.routeProgress,
                                  coordinate: firstLocation.coordinate),
        ]
        startActiveNavigation()

        wait(for: [telemetryObserver.expectation], timeout: expectationsTimeout)
    }

    func testStartActiveNavigationAfterFreeRide() {
        let firstLocation = locationManager.locations.first!
        telemetryObserver.expectedEvents = [
            freeDriveEvent(eventType: "start", coordinate: firstLocation.coordinate)
        ]

        startPassiveNavigation()

        wait(for: [telemetryObserver.expectation], timeout: expectationsTimeout)
        telemetryObserver.reset()

        configureActiveNavigation()

        telemetryObserver.expectedEvents = [
            freeDriveEvent(eventType: "stop", coordinate: firstLocation.coordinate),
            activeNavigationEvent(eventName: "navigation.navigationStateChanged",
                                  state: "navigation_started",
                                  routeProgress: navigationService.routeProgress,
                                  coordinate: firstLocation.coordinate),
        ]
        startActiveNavigation()

        wait(for: [telemetryObserver.expectation], timeout: expectationsTimeout)
    }

    func testFinishRoute() {
        let firstLocation = locationManager.locations.first!
        telemetryObserver.expectedEvents = [
            freeDriveEvent(eventType: "start", coordinate: firstLocation.coordinate)
        ]

        startPassiveNavigation()

        wait(for: [telemetryObserver.expectation], timeout: expectationsTimeout)
        telemetryObserver.reset()

        configureActiveNavigation()

        var activeAttributesKeys = activeNoValueCheckAttributesKeys
        activeAttributesKeys.insert("locationsAfter")
        telemetryObserver.expectedEvents = [
            freeDriveEvent(eventType: "stop", coordinate: firstLocation.coordinate),
            activeNavigationEvent(eventName: "navigation.navigationStateChanged",
                                  state: "navigation_started",
                                  routeProgress: navigationService.routeProgress,
                                  coordinate: firstLocation.coordinate),
        ]
        startActiveNavigation()

        let navigationFinished = expectation(description: "Navigation finished")
        locationManager.replayCompletionHandler = { [weak self] _ in
            navigationFinished.fulfill()
            self?.navigationService.endNavigation(feedback: nil)
            return false
        }

        wait(for: [telemetryObserver.expectation, navigationFinished], timeout: expectationsTimeout)
    }

    func testStartFreeRideAfterActiveNavigation() {
        let firstLocation = locationManager.locations.first!
        telemetryObserver.expectedEvents = [
            freeDriveEvent(eventType: "start", coordinate: firstLocation.coordinate)
        ]

        startPassiveNavigation()

        wait(for: [telemetryObserver.expectation], timeout: expectationsTimeout)

        telemetryObserver.reset()
        configureActiveNavigation()

        telemetryObserver.expectedEvents = [
            freeDriveEvent(eventType: "stop", coordinate: firstLocation.coordinate),
            activeNavigationEvent(eventName: "navigation.navigationStateChanged",
                                  state: "navigation_started",
                                  routeProgress: navigationService.routeProgress,
                                  coordinate: firstLocation.coordinate),
        ]
        startActiveNavigation()

        wait(for: [telemetryObserver.expectation], timeout: expectationsTimeout)

        telemetryObserver.reset()

        var activeAttributesKeys = activeNoValueCheckAttributesKeys
        activeAttributesKeys.insert("locationsBefore")
        telemetryObserver.expectedEvents = [
            activeNavigationEvent(eventName: "navigation.cancel",
                                  routeProgress: navigationService.routeProgress,
                                  coordinate: firstLocation.coordinate,
                                 noValueCheckAttributesKeys: activeAttributesKeys),
            activeNavigationEvent(eventName: "navigation.navigationStateChanged",
                                  state: "navigation_ended",
                                  routeProgress: navigationService.routeProgress,
                                  coordinate: firstLocation.coordinate),
            freeDriveEvent(eventType: "start", coordinate: firstLocation.coordinate),
        ]
        navigationService.router.finishRouting()
        startPassiveNavigation()

        wait(for: [telemetryObserver.expectation], timeout: expectationsTimeout)
    }

    struct Event: Equatable {
        let eventName: String
        let attributes: [String: Any]
        let approximateValueCheckAttributes: [String: (Double, Double)]
        let noValueCheckAttributesKeys: Set<String>

        static func ==(lhs: NativeTelemetryIntegrationTests.Event, rhs: NativeTelemetryIntegrationTests.Event) -> Bool {
            lhs.eventName == rhs.eventName &&
            lhs.attributes == rhs.attributes &&
            lhs.noValueCheckAttributesKeys == rhs.noValueCheckAttributesKeys &&
            lhs.approximateValueCheckAttributes.count == rhs.approximateValueCheckAttributes.count &&
            lhs.approximateValueCheckAttributes.allSatisfy { key, value in
                guard let rightValue = rhs.approximateValueCheckAttributes[key] else { return false }
                return abs(value.0 - rightValue.0) <= value.1
            }
        }
    }

    final class TelemetryObserver: EventsServiceObserver {
        var actualEvents: [Event] = []
        var expectedEvents: [Event] = []

        var shouldSkipEventsCount: Int = 0
        private(set) var skippedEventsCount: Int = 0

        var expectation = XCTestExpectation(description: "Events sent expectation")

        func reset() {
            actualEvents = []
            expectation = XCTestExpectation(description: "Events sent expectation")
        }

        func didEncounterError(forError error: EventsServiceError, events: Any) {
            DispatchQueue.main.async { [weak self] in
                self?.handleEvents(events)
            }
        }

        func didSendEvents(forEvents events: Any) {
            DispatchQueue.main.async { [weak self] in
                self?.handleEvents(events)
            }
        }

        private func handleEvents(_ events: Any) {
            guard let eventAttributes = events as? [[String: Any]] else {
                return XCTFail("Events has incorrect type")
            }
            for event in eventAttributes {
                handleEvent(event)
            }
        }

        private func handleEvent(_ event: [String: Any]) {
            guard skippedEventsCount >= shouldSkipEventsCount else {
                skippedEventsCount += 1
                return
            }

            guard let eventName = event["event"] as? String else {
                return XCTFail("Event \(event) has no name")
            }

            guard actualEvents.count < expectedEvents.count else {
                expectation.fulfill()
                return
            }

            print("\(eventName) event revieved. Details \(event)")
            let expectedEvent = expectedEvents[actualEvents.count]
            let typedEvent = Event(eventName: eventName,
                                   attributes: event,
                                   expectedEvent: expectedEvent)
            actualEvents.append(typedEvent)
            XCTAssertEqual(typedEvent, expectedEvent)

            if expectedEvents.count == actualEvents.count {
                expectation.fulfill()
            }
        }
    }

    fileprivate var navigationBaseAttributes: [String: Any] {
        [
            "sdkIdentifier": "mapbox-navigation-ios",
            "eventVersion": 2.4,
            "version": 2.4,
            "operatingSystem": "\(platformName) \(platformVersion)",
            "device": deviceString,
            "simulation": 0,
            "locationEngine": "sim:0,acc:0",
            "volumeLevel": volumeLevel,
            "audioType": "speaker",
            "screenBrightness": screenBrightness,
            "percentTimeInForeground": 100,
            "percentTimeInPortrait": 100,
            "batteryPluggedIn": batteryPluggedIn as NSNumber,
            "appMetadata": dictionaryUserInfo
        ]
    }

    private var passiveNoValueCheckAttributesKeys: Set<String> {
        [
            "created",
            "createdMonotime",
            "driverModeStartTimestamp",
            "driverModeStartTimestampMonotime",
            "driverModeId",
            "connectivity",
        ]
    }

    private var activeNoValueCheckAttributesKeys: Set<String> {
        let attributes: Set<String> = [
            "originalRequestIdentifier",
            "requestIdentifier",
            "connectivity",
            "distanceRemaining",
            "durationRemaining",
            // TODO: fix flaky check of voiceIndex & bannerIndex
            "voiceIndex",
            "bannerIndex"
        ]
        return attributes.union(passiveNoValueCheckAttributesKeys)
    }

    private var cpu: String {
#if arch(x86_64)
        return "x86_64"
#elseif arch(arm)
        return "arm"
#elseif arch(arm64)
        return "arm64"
#else
        return ""
#endif
    }

    private func stepLocations(legIndex: Int = 0, stepIndex: Int = 0) -> [CLLocation] {
        guard let shape = route.legs[legIndex].steps[stepIndex].shape else { return [] }
        let now = Date()
        return shape.coordinates.enumerated().map {
            CLLocation(coordinate: $0.element,
                       altitude: -1,
                       horizontalAccuracy: 10,
                       verticalAccuracy: -1,
                       course: -1,
                       speed: 10,
                       timestamp: now + $0.offset)
        }
    }

    private func configureEventsObserver() {
        let accessToken = Fixture.credentials.accessToken ?? ""
        let options = EventsServerOptions(
            token: accessToken,
            userAgentFragment: MapboxNavigationNative.Navigator.getUserAgentFragment(),
            deferredDeliveryServiceOptions: nil
        )
        eventsAPI = EventsService.getOrCreate(for: options)
        telemetryObserver = TelemetryObserver()
        eventsAPI.registerObserver(for: telemetryObserver)
    }

    private func startPassiveNavigation() {
        passiveLocationManager = PassiveLocationManager(directions: directions,
                                                        systemLocationManager: locationManager,
                                                        userInfo: userInfo)
        updateLocation()
    }

    private func startActiveNavigation() {
        navigationService?.start()
        updateLocation()
    }

    private func configureActiveNavigation() {
        navigationService = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                                    customRoutingProvider: MapboxRoutingProvider(.offline),
                                                    credentials: Fixture.credentials,
                                                    locationSource: locationManager,
                                                    simulating: .never,
                                                    userInfo: userInfo)
        navigationService.eventsManager.userInfo = userInfo
    }

    private func updateLocation() {
        let firstLocation = locationManager.locations.first!
        navigator.updateLocation(firstLocation) { _ in }
    }

    private func freeDriveEvent(eventType: String,
                                coordinate: CLLocationCoordinate2D) -> Event {
        let attributes: [String: Any] = [
            "eventType": eventType,
            "driverMode": "freeDrive",
            "lat": coordinate.latitude,
            "lng": coordinate.longitude,
        ]
        return event(with: "navigation.freeDrive",
                     attributes: attributes,
                     approximateValueCheckAttributes: [:],
                     noValueCheckAttributesKeys: passiveNoValueCheckAttributesKeys)
    }

    private func activeNavigationEvent(eventName: String,
                                       state: String? = nil,
                                       routeProgress: RouteProgress,
                                       coordinate: CLLocationCoordinate2D,
                                       originalRoute: Route? = nil,
                                       rerouteCount: Int = 0,
                                       noValueCheckAttributesKeys: Set<String>? = nil) -> Event {
        let route = routeProgress.route
        let originalRoute = originalRoute ?? route
        let lastCoordinate = route.shape!.coordinates.last!
        let location = CLLocation(coordinate: coordinate)
        var attributes: [String: Any] = [
            "originalStepCount": originalRoute.legs.map({$0.steps.count}).reduce(0, +),
            "stepCount": routeProgress.route.legs.reduce(0) { $0 + $1.steps.count },
            "driverMode": "trip",
            "lat": coordinate.latitude,
            "lng": coordinate.longitude,
            "profile": "driving-traffic",
            "originalGeometry": geometry ?? "",
            "originalGeometryFormat": "precision_6",
            "geometry": geometry ?? "",
            "geometryFormat": "precision_6",
            "stepIndex": routeProgress.currentLegProgress.stepIndex,
            "legIndex": routeProgress.legIndex,
            "legCount": routeProgress.route.legs.count,
            "estimatedDuration": Int(route.expectedTravelTime),
            "estimatedDistance": Int(route.distance),
            "rerouteCount": rerouteCount
        ]
        if let state = state {
            attributes["state"] = state
        }
        let approximateValueCheckAttributes = [
            "absoluteDistanceToDestination": (location.distance(from: CLLocation(latitude: lastCoordinate.latitude, longitude: lastCoordinate.longitude)), 10.0),
            "distanceCompleted": (routeProgress.distanceTraveled, 10.0),
            // TODO: return value check after NN fix
//            "distanceRemaining": (routeProgress.distanceRemaining, 10.0),
//            "durationRemaining": (routeProgress.durationRemaining, 1.0),
        ]
        let attributesKeys = noValueCheckAttributesKeys ?? activeNoValueCheckAttributesKeys
        return event(with: eventName,
                     attributes: attributes,
                     approximateValueCheckAttributes: approximateValueCheckAttributes,
                     noValueCheckAttributesKeys: attributesKeys)
    }

    private func event(with eventName: String,
                       attributes: [String: Any],
                       approximateValueCheckAttributes: [String: (Double, Double)],
                       noValueCheckAttributesKeys: Set<String>) -> Event {
        var eventAttributes: [String: Any] = [
            "event": eventName
        ]
        eventAttributes.merge(navigationBaseAttributes) { _, new in new }
        eventAttributes.merge(attributes) { _, new in new }
        return Event(eventName: eventName,
                     attributes: eventAttributes,
                     approximateValueCheckAttributes: approximateValueCheckAttributes,
                     noValueCheckAttributesKeys: noValueCheckAttributesKeys)
    }
}

extension NativeTelemetryIntegrationTests.Event {
    var approximateValueCheckAttributesKeys: Set<String> {
        Set(approximateValueCheckAttributes.keys)
    }
    var specialCheckAttributesKeys: Set<String> {
        noValueCheckAttributesKeys.union(approximateValueCheckAttributesKeys)
    }

    init(eventName: String,
         attributes: [String: Any],
         expectedEvent:  NativeTelemetryIntegrationTests.Event) {
        let specialCheckAttributeKeys = expectedEvent.specialCheckAttributesKeys
        let eventAttributes = attributes.filter { !specialCheckAttributeKeys.contains($0.key) }
        let approximateValueCheckAttributes: [String: (Double, Double)] = attributes
            .filter { expectedEvent.approximateValueCheckAttributesKeys.contains($0.key) }
            .reduce(into: [:]) { result, element in
                guard let doubleValue = element.value as? Double,
                      let eps = expectedEvent.approximateValueCheckAttributes[element.key]?.1
                else { return }

                result[element.key] = (doubleValue, eps)
            }
        let noValueCheckAttributesKeys = attributes.keys.filter { expectedEvent.noValueCheckAttributesKeys.contains($0) }
        self.init(eventName: eventName,
                  attributes: eventAttributes,
                  approximateValueCheckAttributes: approximateValueCheckAttributes,
                  noValueCheckAttributesKeys: Set(noValueCheckAttributesKeys))
    }
}

private func ==(lhs: [String: Any], rhs: [String: Any] ) -> Bool {
    guard Set(lhs.keys) == Set(rhs.keys) else { return false }
    return lhs.keys.allSatisfy { key in
        let leftValue = lhs[key]!
        let rightValue = rhs[key]!
        let result = NSDictionary(dictionary: [key: leftValue]).isEqual(to: [key: rightValue])

        if (!result) {
            print("Found diff between events \(lhs["event"] ?? "").\(lhs["state"] ?? "")) with key=\(key), actual \(leftValue), expected \(rightValue)")
        }
        return result
    }
}
