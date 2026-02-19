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
