import _MapboxNavigationTestHelpers
import Combine
import MapboxDirections
@_spi(MapboxInternal) @testable import MapboxNavigationCore
@testable import MapboxNavigationNative
import XCTest

final class MapboxSpeechSynthesizerTests: XCTestCase {
    let locale = Locale(identifier: "en-US")
    let data = "response".data(using: .utf8)!
    let instruction = SpokenInstruction.mock()

    var synthesizer: MapboxSpeechSynthesizer!
    var cancellables: Set<AnyCancellable>!
    var routeLegProgress: RouteLegProgress!

    @MainActor
    override func setUp() {
        super.setUp()

        Environment.switchEnvironment(to: .test)
        synthesizer = Self.makeMapboxSpeechSynthesizer()
        routeLegProgress = .mock()
        cancellables = []
    }

    override func tearDown() {
        cancellables = []
        synthesizer = nil
        Environment.switchEnvironment(to: .live)
        super.tearDown()
    }

    @MainActor
    private static func makeMapboxSpeechSynthesizer() -> MapboxSpeechSynthesizer {
        MapboxSpeechSynthesizer(
            apiConfiguration: .mock(),
            skuTokenProvider: .init(skuToken: { "token" })
        )
    }

    @MainActor
    func testPrepareIncomingSpokenInstructionsIfEmptyInstructions() async {
        let expectation = expectation(description: "Publisher should not emit any events")
        expectation.isInverted = true
        synthesizer.voiceInstructions.sink { _ in
            expectation.fulfill()
        }.store(in: &cancellables)

        synthesizer.prepareIncomingSpokenInstructions([], locale: locale)
        await fulfillment(of: [expectation], timeout: 0.5)
    }

    @MainActor
    func testPrepareIncomingSpokenInstructionsIfNilLocale() async {
        let expectation = undefinedSpeechLocaleExpectation()

        synthesizer.prepareIncomingSpokenInstructions([instruction], locale: nil)
        await fulfillment(of: [expectation], timeout: 0.5)
    }

    @MainActor
    func testPrepareIncomingSpokenInstructions() async {
        let callExpectation = expectation(description: "audioData expectation")
        let expectedOptions = SpeechOptions(ssml: instruction.ssmlText, locale: locale)

        let client = RemoteSpeechSynthesizerClient { options in
            XCTAssertEqual(options, expectedOptions)
            callExpectation.fulfill()
            return self.data
        }
        let provider = SpeechSynthesizerClientProvider.value(with: client)
        Environment.set(\.speechSynthesizerClientProvider, provider)

        synthesizer = Self.makeMapboxSpeechSynthesizer()

        let eventExpectation = expectation(description: "voice instructions")
        eventExpectation.isInverted = true
        synthesizer.voiceInstructions.sink { _ in
            eventExpectation.fulfill()
        }.store(in: &cancellables)

        synthesizer.prepareIncomingSpokenInstructions([instruction], locale: locale)

        await fulfillment(of: [eventExpectation, callExpectation], timeout: 0.5)

        let cachedRecord = synthesizer.cachedDataForKey(instruction.ssmlText, with: locale)
        XCTAssertEqual(cachedRecord, data)
    }

    @MainActor
    func testSpeakIfCached() async {
        let eventExpectation = expectation(description: "will speak")
        synthesizer.voiceInstructions.first()
            .sink { event in
                guard let typedEvent = event as? VoiceInstructionEvents.WillSpeak
                else {
                    XCTFail("incorrect event")
                    return
                }
                XCTAssertEqual(typedEvent.instruction, self.instruction)
                eventExpectation.fulfill()
            }.store(in: &cancellables)

        synthesizer.cache(data, forKey: instruction.ssmlText, with: locale)

        synthesizer.speak(instruction, during: routeLegProgress, locale: locale)

        await fulfillment(of: [eventExpectation], timeout: 0.5)
    }

    @MainActor
    func testSpeakIfNonCached() async {
        let callExpectation = expectation(description: "audioData expectation")
        let expectedOptions = SpeechOptions(ssml: instruction.ssmlText, locale: locale)

        let client = RemoteSpeechSynthesizerClient { options in
            XCTAssertEqual(options, expectedOptions)
            callExpectation.fulfill()
            return self.data
        }
        let provider = SpeechSynthesizerClientProvider.value(with: client)
        Environment.set(\.speechSynthesizerClientProvider, provider)

        synthesizer = Self.makeMapboxSpeechSynthesizer()

        let eventExpectation = expectation(description: "will speak")
        synthesizer.voiceInstructions.first()
            .sink { event in
                guard let typedEvent = event as? VoiceInstructionEvents.WillSpeak
                else {
                    XCTFail("incorrect event")
                    return
                }
                XCTAssertEqual(typedEvent.instruction, self.instruction)
                eventExpectation.fulfill()
            }.store(in: &cancellables)

        synthesizer.speak(instruction, during: routeLegProgress, locale: locale)

        await fulfillment(of: [callExpectation], timeout: 0.5)

        let cachedRecord = synthesizer.cachedDataForKey(instruction.ssmlText, with: locale)
        XCTAssertEqual(cachedRecord, data)
        await fulfillment(of: [eventExpectation], timeout: 0.5)
    }

    @MainActor
    func testSpeakIfNilLocale() async {
        let expectation = undefinedSpeechLocaleExpectation()
        synthesizer.speak(instruction, during: routeLegProgress, locale: nil)
        await fulfillment(of: [expectation], timeout: 0.5)
    }

    @MainActor
    func testSpeakIfMuted() async {
        synthesizer.muted = true
        let expectation = expectation(description: "Error")
        synthesizer.voiceInstructions.sink { _ in
            expectation.fulfill()
        }.store(in: &cancellables)
        expectation.isInverted = true

        synthesizer.speak(instruction, during: routeLegProgress, locale: locale)
        await fulfillment(of: [expectation], timeout: 0.5)
    }

    @MainActor
    private func undefinedSpeechLocaleExpectation() -> XCTestExpectation {
        let expectation = expectation(description: "Error")
        synthesizer.voiceInstructions.sink { event in
            guard let errorEvent = event as? VoiceInstructionEvents.EncounteredError,
                  case .undefinedSpeechLocale(instruction: let errorInstruction) = errorEvent.error
            else {
                XCTFail("incorrect event")
                return
            }
            XCTAssertEqual(errorInstruction, self.instruction)
            expectation.fulfill()
        }.store(in: &cancellables)
        return expectation
    }
}
