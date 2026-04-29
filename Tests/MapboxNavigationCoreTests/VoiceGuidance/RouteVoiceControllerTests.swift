@testable import _MapboxNavigationTestHelpers
import Combine
import MapboxDirections
@testable import MapboxNavigationCore
@testable import MapboxNavigationNative_Private
import XCTest

final class RouteVoiceControllerTests: BaseTestCase {
    var speechSynthesizer: SpeechSynthesizerMock!
    var routeProgress: CurrentValueSubject<RouteProgressState?, Never>!
    var rerouteSoundTrigger: PassthroughSubject<Void, Never>!

    @MainActor
    private func makeRouteVoiceController() -> RouteVoiceController {
        RouteVoiceController(
            routeProgressing: routeProgress.eraseToAnyPublisher(),
            rerouteSoundTrigger: rerouteSoundTrigger.eraseToAnyPublisher(),
            speechSynthesizer: speechSynthesizer
        )
    }

    @MainActor
    override func setUp() {
        super.setUp()

        Environment.switchEnvironment(to: .test)
        routeProgress = .init(nil)
        rerouteSoundTrigger = .init()
        speechSynthesizer = SpeechSynthesizerMock()
    }

    override func tearDown() {
        Environment.switchEnvironment(to: .live)
        super.tearDown()
    }

    @MainActor
    func testRerouteSoundLoaded() async {
        let loadExpectation = expectation(description: "Sounds loaded")
        Environment.set(\.audioPlayerClient.load) { _ in
            loadExpectation.fulfill()
        }

        let routeVoiceController = makeRouteVoiceController()
        defer { _ = routeVoiceController }
        await fulfillment(of: [loadExpectation], timeout: 1.0)
    }

    @MainActor
    func testDoesNotSpeakIfNoInstruction() async {
        Environment.set(\.audioPlayerClient.load, AudioPlayerClient.noopValue.load)
        let routeVoiceController = makeRouteVoiceController()
        defer { _ = routeVoiceController }

        speechSynthesizer.locale = .current
        await routeProgress.send(.mock(optionsLocale: .jaJP, voiceLocale: .enUS, includesSpokenInstruction: false))

        XCTAssertFalse(speechSynthesizer.prepareIncomingSpokenInstructionsCalled)
        XCTAssertFalse(speechSynthesizer.speakCalled)
        XCTAssertEqual(speechSynthesizer.locale, .current)
    }

    @MainActor
    func testPassVoiceAndOptionsLocale() async {
        Environment.set(\.audioPlayerClient.load, AudioPlayerClient.noopValue.load)
        let routeVoiceController = makeRouteVoiceController()
        defer { _ = routeVoiceController }

        await routeProgress.send(.mock(optionsLocale: .jaJP, voiceLocale: .enUS))

        XCTAssertEqual(speechSynthesizer.locale, .jaJP)
        XCTAssertTrue(speechSynthesizer.speakCalled)
        XCTAssertEqual(speechSynthesizer.passedLocale, .enUS)
        XCTAssertEqual(speechSynthesizer.passedInstruction, .turnLeft)
    }

    @MainActor
    func testRerouteStopsSpeakingAndPlaysSound() async {
        Environment.set(\.audioPlayerClient.load, AudioPlayerClient.noopValue.load)
        let routeVoiceController = makeRouteVoiceController()
        defer { _ = routeVoiceController }

        let stopSpeakingExpectation = expectation(description: "Stop speaking")
        speechSynthesizer.stopSpeakingExpectation = stopSpeakingExpectation

        let playExpectation = expectation(description: "Stop speaking")
        Environment.set(\.audioPlayerClient.play) { _ in
            playExpectation.fulfill()
            return true
        }

        rerouteSoundTrigger.send(())
        await fulfillment(of: [stopSpeakingExpectation, playExpectation], timeout: 1.0)
    }

    @MainActor
    func testRerouteDoesNotStopSpeakingAndPlaySoundWhenDisabled() async {
        Environment.set(\.audioPlayerClient.load, AudioPlayerClient.noopValue.load)
        let routeVoiceController = makeRouteVoiceController()
        defer { _ = routeVoiceController }

        routeVoiceController.playsRerouteSound = false

        let stopSpeakingExpectation = expectation(description: "Stop speaking")
        stopSpeakingExpectation.isInverted = true
        speechSynthesizer.stopSpeakingExpectation = stopSpeakingExpectation

        let playExpectation = expectation(description: "Stop speaking")
        playExpectation.isInverted = true
        Environment.set(\.audioPlayerClient.play) { _ in
            playExpectation.fulfill()
            return true
        }

        rerouteSoundTrigger.send(())
        await fulfillment(of: [stopSpeakingExpectation, playExpectation], timeout: 1.0)
    }

    @MainActor
    func testRerouteDoesNotStopSpeakingAndPlaySoundWhenSpeechSynthesizerIsMuted() async {
        Environment.set(\.audioPlayerClient.load, AudioPlayerClient.noopValue.load)
        let routeVoiceController = makeRouteVoiceController()
        defer { _ = routeVoiceController }

        routeVoiceController.speechSynthesizer.muted = true

        let stopSpeakingExpectation = expectation(description: "Stop speaking")
        stopSpeakingExpectation.isInverted = true
        speechSynthesizer.stopSpeakingExpectation = stopSpeakingExpectation

        let playExpectation = expectation(description: "Stop speaking")
        playExpectation.isInverted = true
        Environment.set(\.audioPlayerClient.play) { _ in
            playExpectation.fulfill()
            return true
        }

        rerouteSoundTrigger.send(())
        await fulfillment(of: [stopSpeakingExpectation, playExpectation], timeout: 1.0)
    }
}

extension RouteProgressState {
    fileprivate static func mock(
        optionsLocale: Locale,
        voiceLocale: Locale?,
        includesSpokenInstruction: Bool = true
    ) async -> RouteProgressState {
        let uri = RouteInterfaceMock.realRequestUri + "&language=\(optionsLocale.identifier)"
        let mainRoute = NavigationRoute.mock(
            route: .mock(speechLocale: voiceLocale),
            nativeRoute: RouteInterfaceMock(requestUri: uri)
        )
        let navigationRoutes = await NavigationRoutes.mock(mainRoute: mainRoute)
        var progress = RouteProgress.mock(navigationRoutes: navigationRoutes)

        if includesSpokenInstruction {
            progress.update(using: .mock(voiceInstruction: .turnLeft))
        }
        return RouteProgressState(routeProgress: progress)
    }
}

extension Locale {
    fileprivate static var jaJP: Locale { Locale(identifier: "ja_JP") }
    fileprivate static var enUS: Locale { Locale(identifier: "en_US") }
}

extension VoiceInstruction {
    fileprivate static var turnLeft: VoiceInstruction {
        VoiceInstruction(
            ssmlAnnouncement: "turn left",
            announcement: "turn left",
            remainingStepDistance: 5,
            index: 0
        )
    }
}

extension SpokenInstruction {
    static var turnLeft: SpokenInstruction {
        SpokenInstruction(
            distanceAlongStep: 5,
            text: "turn left",
            ssmlText: "turn left"
        )
    }
}
