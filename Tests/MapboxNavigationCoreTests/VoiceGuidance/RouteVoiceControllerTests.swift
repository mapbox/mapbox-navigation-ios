import _MapboxNavigationTestHelpers
import Combine
import MapboxDirections
@testable import MapboxNavigationCore
@testable import MapboxNavigationNative_Private
import XCTest

final class RouteVoiceControllerTests: BaseTestCase {
    var routeVoiceController: RouteVoiceController!
    var speechSynthesizer: SpeechSynthesizerMock!

    var routeProgressPublisher: CurrentValueSubject<RouteProgressState?, Never>!
    var rerouteSoundTrigger: CurrentValueSubject<Void, Never>!

    let voiceInstruction = VoiceInstruction(
        ssmlAnnouncement: "ssml text",
        announcement: "text",
        remainingStepDistance: 5,
        index: 0
    )

    let spokenInstruction = SpokenInstruction(distanceAlongStep: 5, text: "text", ssmlText: "ssml text")

    @MainActor
    override func setUp() {
        super.setUp()

        routeProgressPublisher = .init(nil)
        rerouteSoundTrigger = .init(())

        speechSynthesizer = SpeechSynthesizerMock()
        routeVoiceController = RouteVoiceController(
            routeProgressing: routeProgressPublisher.eraseToAnyPublisher(),
            rerouteSoundTrigger: rerouteSoundTrigger.eraseToAnyPublisher(),
            speechSynthesizer: speechSynthesizer
        )
    }

    @MainActor
    func testDoesNotSpeakIfNoInstruction() async {
        speechSynthesizer.locale = .current
        let optionsLocale = Locale(identifier: "ja_JP")
        let voiceLocale = Locale(identifier: "en_US")
        let progress = await routeProgress(
            optionsLocale: optionsLocale,
            voiceLocale: voiceLocale,
            includesSpokenInstruction: false
        )
        routeProgressPublisher.send(progress)

        XCTAssertFalse(speechSynthesizer.prepareIncomingSpokenInstructionsCalled)
        XCTAssertFalse(speechSynthesizer.speakCalled)
        XCTAssertEqual(speechSynthesizer.locale, .current)
    }

    @MainActor
    func testPassVoiceAndOptionsLocale() async {
        let optionsLocale = Locale(identifier: "ja_JP")
        let voiceLocale = Locale(identifier: "en_US")
        let progress = await routeProgress(optionsLocale: optionsLocale, voiceLocale: voiceLocale)
        routeProgressPublisher.send(progress)

        XCTAssertEqual(speechSynthesizer.locale, optionsLocale)
        XCTAssertTrue(speechSynthesizer.speakCalled)
        XCTAssertEqual(speechSynthesizer.passedLocale, voiceLocale)
        XCTAssertEqual(speechSynthesizer.passedInstruction, spokenInstruction)
    }

    private func routeProgress(
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
            let status = NavigationStatus.mock(voiceInstruction: voiceInstruction)
            progress.update(using: status)
        }
        return RouteProgressState(routeProgress: progress)
    }
}
