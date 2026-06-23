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
    func testDidFinishForCurrentUtteranceSendsDidSpeak() async {
        let utterance = await speakAndCaptureUtterance()
        let didSpeakEmitted = expectation(description: "DidSpeak emitted")
        synthesizer.voiceInstructions
            .filter { $0 is VoiceInstructionEvents.DidSpeak }
            .sink { _ in didSpeakEmitted.fulfill() }
            .store(in: &cancellables)
        synthesizer.speechSynthesizer(AVSpeechSynthesizer(), didFinish: utterance)
        await fulfillment(of: [didSpeakEmitted], timeout: 0.5)
    }

    @MainActor
    func testDidFinishForSupersededUtteranceSkipsDidSpeak() async {
        await speakAndCaptureUtterance()
        let didSpeakNotEmitted = expectation(description: "DidSpeak not emitted for superseded")
        didSpeakNotEmitted.isInverted = true
        synthesizer.voiceInstructions
            .filter { $0 is VoiceInstructionEvents.DidSpeak }
            .sink { _ in didSpeakNotEmitted.fulfill() }
            .store(in: &cancellables)
        synthesizer.speechSynthesizer(AVSpeechSynthesizer(), didFinish: AVSpeechUtterance(string: "old utterance"))
        await fulfillment(of: [didSpeakNotEmitted], timeout: 0.3)
    }

    @MainActor
    func testDidCancelForCurrentUtteranceSendsDidSpeak() async {
        let utterance = await speakAndCaptureUtterance()
        let didSpeakEmitted = expectation(description: "DidSpeak emitted")
        synthesizer.voiceInstructions
            .filter { $0 is VoiceInstructionEvents.DidSpeak }
            .sink { _ in didSpeakEmitted.fulfill() }
            .store(in: &cancellables)
        synthesizer.speechSynthesizer(AVSpeechSynthesizer(), didCancel: utterance)
        await fulfillment(of: [didSpeakEmitted], timeout: 0.5)
    }

    @MainActor
    func testDidCancelForSupersededUtteranceSkipsDidSpeak() async {
        await speakAndCaptureUtterance()
        let didSpeakNotEmitted = expectation(description: "DidSpeak not emitted for superseded")
        didSpeakNotEmitted.isInverted = true
        synthesizer.voiceInstructions
            .filter { $0 is VoiceInstructionEvents.DidSpeak }
            .sink { _ in didSpeakNotEmitted.fulfill() }
            .store(in: &cancellables)
        synthesizer.speechSynthesizer(AVSpeechSynthesizer(), didCancel: AVSpeechUtterance(string: "old utterance"))
        await fulfillment(of: [didSpeakNotEmitted], timeout: 0.3)
    }

    // MARK: - Helpers

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

    @MainActor
    @discardableResult
    private func speakAndCaptureUtterance() async -> AVSpeechUtterance {
        let speakCalled = expectation(description: "speak called")
        var capturedUtterance: AVSpeechUtterance?
        var client = SystemSpeechSynthesizerClient.testValue
        client.isSpeaking = { false }
        client.stopSpeaking = { _ in }
        client.speak = { utterance in
            capturedUtterance = utterance
            speakCalled.fulfill()
        }
        Environment.set(\.speechSynthesizerClientProvider, .value(with: client))
        synthesizer = SystemSpeechSynthesizer()
        synthesizer.managesAudioSession = false
        synthesizer.speak(instruction, during: routeLegProgress, locale: locale)
        await fulfillment(of: [speakCalled], timeout: 0.5)
        return capturedUtterance!
    }
}
