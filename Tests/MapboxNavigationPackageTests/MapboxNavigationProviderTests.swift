import Combine
import CoreLocation
@testable import MapboxNavigationCore
import TestHelper
import XCTest

extension MapboxNavigationCore.Environment {
    static let noop = Environment(
        audioPlayerClient: .noopValue,
        routerClientProvider: .liveValue,
        routeParserClient: .liveValue,
        speechSynthesizerClientProvider: .liveValue
    )
}

extension AudioPlayerClient {
    static var noopValue: AudioPlayerClient {
        Self(
            play: { _ in return false },
            load: { _ in }
        )
    }
}

final class MapboxNavigationProviderTests: TestCase {
    override func setUp() {
        super.setUp()
        Environment.switchEnvironment(to: .noop)
    }

    override func tearDown() {
        Environment.switchEnvironment(to: .live)
        super.tearDown()
    }

    func testRouteVoiceControllerRerouteSoundTriggerPerRerouteReason() async {
        await routeVoiceControllerRerouteSoundTrigger(on: nil)
        await routeVoiceControllerRerouteSoundTrigger(on: .deviation)
        await routeVoiceControllerRerouteSoundTrigger(on: .closure)
        await routeVoiceControllerRerouteSoundTrigger(on: .parametersChange)
        await routeVoiceControllerRerouteSoundTrigger(on: .insufficientCharge)
    }

    func testRouteVoiceControllerNoRerouteSoundTriggerOnRouteInvalidation() async {
        let navigator = await navigationProvider.navigation() as! MapboxNavigator
        _ = await navigationProvider.routeVoiceController

        let playExpectation = configuredRerouteExpectation()
        playExpectation.isInverted = true

        let event = ReroutingStatus.Events.Fetched(reason: .routeInvalidated)
        await navigator.send(ReroutingStatus(event: event))

        await fulfillment(of: [playExpectation], timeout: 0.1)
    }

    func testRouteVoiceControllerRerouteSoundTriggerForFasterRoute() async {
        let navigator = await navigationProvider.navigation() as! MapboxNavigator
        _ = await navigationProvider.routeVoiceController

        let playExpectation = configuredRerouteExpectation()
        let event = FasterRoutesStatus.Events.Applied()
        await navigator.send(FasterRoutesStatus(event: event))

        await fulfillment(of: [playExpectation], timeout: 0.1)

        let noPlayExpectation = configuredRerouteExpectation()
        noPlayExpectation.isInverted = true
        let event2 = FasterRoutesStatus.Events.Detected()
        await navigator.send(FasterRoutesStatus(event: event2))

        await fulfillment(of: [noPlayExpectation], timeout: 0.1)
    }

    func testRouteVoiceControllerNoRerouteSoundTriggerForAnyReroutingStatus() async {
        let navigator = await navigationProvider.navigation() as! MapboxNavigator
        _ = await navigationProvider.routeVoiceController

        let playExpectation1 = configuredRerouteExpectation()
        playExpectation1.isInverted = true
        await navigator.send(ReroutingStatus(event: ReroutingStatus.Events.FetchingRoute()))
        await fulfillment(of: [playExpectation1], timeout: 0.1)

        let playExpectation2 = configuredRerouteExpectation()
        playExpectation2.isInverted = true
        await navigator.send(ReroutingStatus(event: ReroutingStatus.Events.Failed(error: .noData)))
        await fulfillment(of: [playExpectation2], timeout: 0.1)

        let playExpectation3 = configuredRerouteExpectation()
        playExpectation3.isInverted = true
        await navigator.send(ReroutingStatus(event: ReroutingStatus.Events.Interrupted()))
        await fulfillment(of: [playExpectation3], timeout: 0.1)
    }

    @MainActor
    func testApplyingSameLocationSourceKeepsLocationClient() async {
        _ = navigationProvider.navigation()
        navigationProvider.multiplexLocationClient.startUpdatingLocation()
        await waitForPendingMainQueueWork()

        var deliveredLocations: [CLLocation] = []
        let subscription = navigationProvider.multiplexLocationClient.locationClient.locations
            .sink { deliveredLocations.append($0) }
        defer { subscription.cancel() }

        let locationClient = LocationClientCounter(location: CLLocation(latitude: 1, longitude: 1))
        coreConfig.locationSource = .custom(locationClient.client)
        navigationProvider.apply(coreConfig: coreConfig)
        await waitUntil { deliveredLocations.count == 1 }
        for _ in 0..<2 {
            navigationProvider.apply(coreConfig: coreConfig)
            for _ in 0..<3 {
                await waitForPendingMainQueueWork()
            }
        }

        let nextLocationClient = LocationClientCounter(location: CLLocation(latitude: 2, longitude: 2))
        coreConfig.locationSource = .custom(nextLocationClient.client)
        navigationProvider.apply(coreConfig: coreConfig)
        await waitUntil { deliveredLocations.last === nextLocationClient.location }

        XCTAssertEqual(locationClient.startCount, 1)
        XCTAssertEqual(locationClient.stopCount, 1)
        XCTAssertEqual(locationClient.subscriptionCount, 1)
        XCTAssertEqual(nextLocationClient.startCount, 1)
        XCTAssertEqual(nextLocationClient.stopCount, 0)
        XCTAssertEqual(deliveredLocations, [locationClient.location, nextLocationClient.location])
    }

    @MainActor
    func testReapplyingLiveLocationSourceReusesLocationClient() async {
        let multiplexLocationClient = MultiplexLocationClient(source: .live)
        await waitForPendingMainQueueWork()
        let liveLocationClient = multiplexLocationClient.currentLocationClient

        let customLocationClient = LocationClientCounter(location: CLLocation(latitude: 1, longitude: 1))
        multiplexLocationClient.setLocationSource(.live)
        multiplexLocationClient.setLocationSource(.custom(customLocationClient.client))
        multiplexLocationClient.setLocationSource(.live)
        await waitUntil { customLocationClient.stopCount == 2 }

        XCTAssertEqual(multiplexLocationClient.currentLocationClient, liveLocationClient)
        XCTAssertEqual(customLocationClient.subscriptionCount, 1)
    }

    @MainActor
    func testReapplyingSimulationLocationSourceRecreatesLocationClient() async {
        let multiplexLocationClient = MultiplexLocationClient(source: .simulation())
        await waitForPendingMainQueueWork()
        let simulatedLocationClient = multiplexLocationClient.currentLocationClient

        multiplexLocationClient.setLocationSource(.simulation())
        await waitUntil { multiplexLocationClient.currentLocationClient != simulatedLocationClient }
    }

    @MainActor
    func testApplyingSameSpeechConfigKeepsSpeechSynthesizer() async {
        let routeVoiceController = navigationProvider.routeVoiceController
        let speechSynthesizer = routeVoiceController.speechSynthesizer

        navigationProvider.apply(coreConfig: coreConfig)
        navigationProvider.apply(coreConfig: coreConfig)
        coreConfig.locale = Locale(identifier: "fr_CA")
        navigationProvider.apply(coreConfig: coreConfig)
        await waitUntil { routeVoiceController.speechSynthesizer.locale == Locale(identifier: "fr_CA") }
        XCTAssertTrue(routeVoiceController.speechSynthesizer === speechSynthesizer)

        coreConfig.ttsConfig = .localOnly
        navigationProvider.apply(coreConfig: coreConfig)
        await waitUntil { routeVoiceController.speechSynthesizer !== speechSynthesizer }
        XCTAssertEqual(routeVoiceController.speechSynthesizer.locale, Locale(identifier: "fr_CA"))
    }

    @MainActor
    func testApplyingCustomSpeechSynthesizerReplacesPreviousOne() async {
        let routeVoiceController = navigationProvider.routeVoiceController
        let customSpeechSynthesizer = MultiplexedSpeechSynthesizer(speechSynthesizers: [])
        coreConfig.ttsConfig = .custom(speechSynthesizer: customSpeechSynthesizer)
        navigationProvider.apply(coreConfig: coreConfig)
        await waitUntil { routeVoiceController.speechSynthesizer === customSpeechSynthesizer }

        let nextCustomSpeechSynthesizer = MultiplexedSpeechSynthesizer(speechSynthesizers: [])
        coreConfig.ttsConfig = .custom(speechSynthesizer: nextCustomSpeechSynthesizer)
        navigationProvider.apply(coreConfig: coreConfig)
        await waitUntil { routeVoiceController.speechSynthesizer === nextCustomSpeechSynthesizer }
    }

    @MainActor
    private func waitUntil(_ condition: () -> Bool, timeout: TimeInterval = 1) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            await waitForPendingMainQueueWork()
        }
        XCTAssertTrue(condition())
    }

    private func waitForPendingMainQueueWork() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                continuation.resume()
            }
        }
    }

    @MainActor
    func testPredictiveCacheManagerIsSharedWithNavigator() throws {
        let manager = try XCTUnwrap(navigationProvider.predictiveCacheManager)
        XCTAssertTrue(navigationProvider.predictiveCacheManager === manager)

        _ = navigationProvider.navigation()

        XCTAssertTrue(manager.navigator === navigationProvider.nativeHandlersFactory.navigator)
    }

    @MainActor
    func testNavigationCalledTwiceAttachesOnce() throws {
        let manager = try XCTUnwrap(navigationProvider.predictiveCacheManager)
        _ = navigationProvider.navigation()
        let navigationController = manager.navigationController

        _ = navigationProvider.navigation()

        XCTAssertNotNil(navigationController)
        XCTAssertTrue(manager.navigationController === navigationController)
    }

    @MainActor
    func testPredictiveCacheManagerIsNilWithoutPredictiveCacheConfig() {
        navigationProvider = nil
        var config: CoreConfig = coreConfig
        config.predictiveCacheConfig = nil
        navigationProvider = MapboxNavigationProvider(coreConfig: config)

        XCTAssertNil(navigationProvider.predictiveCacheManager)
    }

    private func routeVoiceControllerRerouteSoundTrigger(on rerouteReason: RerouteReason?) async {
        let navigator = await navigationProvider.navigation() as! MapboxNavigator
        _ = await navigationProvider.routeVoiceController

        let playExpectation = configuredRerouteExpectation()
        let event = ReroutingStatus.Events.Fetched(reason: rerouteReason)
        await navigator.send(ReroutingStatus(event: event))
        await fulfillment(of: [playExpectation], timeout: 0.1)
    }

    private func configuredRerouteExpectation() -> XCTestExpectation {
        let playExpectation = expectation(description: "Play reroute sound")
        Environment.set(\.audioPlayerClient.play) { url in
            XCTAssertTrue(url.absoluteString.contains("reroute-sound.pcm"))
            playExpectation.fulfill()
            return true
        }
        return playExpectation
    }
}

private final class LocationClientCounter {
    let location: CLLocation
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private(set) var subscriptionCount = 0

    private(set) lazy var client = LocationClient(
        locations: Just(location)
            .handleEvents(receiveSubscription: { [weak self] _ in self?.subscriptionCount += 1 })
            .eraseToAnyPublisher(),
        headings: Empty().eraseToAnyPublisher(),
        startUpdatingLocation: { [weak self] in self?.startCount += 1 },
        stopUpdatingLocation: { [weak self] in self?.stopCount += 1 },
        startUpdatingHeading: {},
        stopUpdatingHeading: {}
    )

    init(location: CLLocation) {
        self.location = location
    }
}
