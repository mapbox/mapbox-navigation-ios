import _MapboxNavigationTestHelpers
import AVFoundation
import Combine
import MapboxDirections
@_spi(MapboxInternal) @testable import MapboxNavigationCore
import XCTest

final class SystemSpeechSynthesizerTests: XCTestCase {
    let locale = Locale(identifier: "en-US")
    let fallbackLocale = Locale(identifier: "ja_JP")
    let instruction = SpokenInstruction.mock()

    var synthesizer: SystemSpeechSynthesizer!
    var cancellables: Set<AnyCancellable>!
    var routeLegProgress: RouteLegProgress!

    @MainActor
    override func setUp() {
        super.setUp()

        Environment.switchEnvironment(to: .test)
        synthesizer = SystemSpeechSynthesizer()
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
    func testPrepareInstructions() async {
        let expectation = expectation(description: "Error")
        synthesizer.voiceInstructions.sink { _ in
            expectation.fulfill()
        }.store(in: &cancellables)
        expectation.isInverted = true

        synthesizer.prepareIncomingSpokenInstructions([instruction], locale: locale)
        await fulfillment(of: [expectation], timeout: 0.5)
    }

    @MainActor
    func testStopSpeaking() async {
        let callExpectation = expectation(description: "stop")
        var client = SystemSpeechSynthesizerClient.testValue
        client.stopSpeaking = { boundary in
            XCTAssertEqual(boundary, .word)
            callExpectation.fulfill()
        }
        let provider = SpeechSynthesizerClientProvider.value(with: client)
        Environment.set(\.speechSynthesizerClientProvider, provider)

        synthesizer = SystemSpeechSynthesizer()
        synthesizer.stopSpeaking()
        await fulfillment(of: [callExpectation], timeout: 0.5)
    }

    @MainActor
    func testInterruptSpeaking() async {
        let callExpectation = expectation(description: "interrupt")
        var client = SystemSpeechSynthesizerClient.testValue
        client.stopSpeaking = { boundary in
            XCTAssertEqual(boundary, .immediate)
            callExpectation.fulfill()
        }
        let provider = SpeechSynthesizerClientProvider.value(with: client)
        Environment.set(\.speechSynthesizerClientProvider, provider)

        synthesizer = SystemSpeechSynthesizer()
        synthesizer.interruptSpeaking()
        await fulfillment(of: [callExpectation], timeout: 0.5)
    }

    @MainActor
    func testSpeakIfNilDefaultLocale() async {
        let expectation = undefinedSpeechLocaleExpectation()
        synthesizer.locale = nil

        synthesizer.speak(instruction, during: routeLegProgress, locale: nil)

        await fulfillment(of: [expectation], timeout: 0.5)
    }

    @MainActor
    func testFallbackToDefaultLocale() async {
        let callExpectation = expectation(description: "stop")
        let expectedUtterance = AVSpeechUtterance(string: instruction.text)
        expectedUtterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        var client = SystemSpeechSynthesizerClient.testValue
        client.speak = { utterance in
            XCTAssertEqual(utterance.voice, expectedUtterance.voice)
            XCTAssertEqual(utterance.speechString, expectedUtterance.speechString)
            callExpectation.fulfill()
        }
        client.isSpeaking = { false }
        let provider = SpeechSynthesizerClientProvider.value(with: client)
        Environment.set(\.speechSynthesizerClientProvider, provider)

        synthesizer = SystemSpeechSynthesizer()
        synthesizer.locale = fallbackLocale

        synthesizer.speak(instruction, during: routeLegProgress, locale: nil)
        await fulfillment(of: [callExpectation], timeout: 0.5)
    }

    @MainActor
    func testSpeakWithPassedLocale() async {
        let callExpectation = expectation(description: "stop")
        let expectedUtterance = AVSpeechUtterance(string: instruction.text)
        expectedUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        var client = SystemSpeechSynthesizerClient.testValue
        client.speak = { utterance in
            XCTAssertEqual(utterance.voice, expectedUtterance.voice)
            XCTAssertEqual(utterance.speechString, expectedUtterance.speechString)
            callExpectation.fulfill()
        }
        client.isSpeaking = { false }
        let provider = SpeechSynthesizerClientProvider.value(with: client)
        Environment.set(\.speechSynthesizerClientProvider, provider)

        synthesizer = SystemSpeechSynthesizer()
        synthesizer.locale = fallbackLocale

        synthesizer.speak(instruction, during: routeLegProgress, locale: locale)
        await fulfillment(of: [callExpectation], timeout: 0.5)
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
