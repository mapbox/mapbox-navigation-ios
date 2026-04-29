import _MapboxNavigationTestHelpers
import MapboxDirections
@testable import MapboxNavigationCore
import XCTest

final class MultiplexedSpeechSynthesizerTests: BaseTestCase {
    var synthesizer: MultiplexedSpeechSynthesizer!

    var innerSynthesizer1: SpeechSynthesizerMock!
    var innerSynthesizer2: SpeechSynthesizerMock!

    let spokenInstruction = SpokenInstruction(distanceAlongStep: 100, text: "Text", ssmlText: "ssml text")

    @MainActor
    override func setUp() {
        super.setUp()

        innerSynthesizer1 = SpeechSynthesizerMock()
        innerSynthesizer2 = SpeechSynthesizerMock()
        synthesizer = MultiplexedSpeechSynthesizer(speechSynthesizers: [innerSynthesizer1, innerSynthesizer2])

        innerSynthesizer1.interruptSpeakingCalled = false
        innerSynthesizer2.interruptSpeakingCalled = false
    }

    @MainActor
    func testWillSpeakIfNoOtherSynthesizersAreSpeaking() {
        synthesizer.speak(spokenInstruction, during: .mock())

        XCTAssertFalse(innerSynthesizer1.interruptSpeakingCalled)
        XCTAssertFalse(innerSynthesizer2.interruptSpeakingCalled)
    }

    @MainActor
    func testInterruptSpeaking() {
        synthesizer.interruptSpeaking()
        XCTAssertTrue(innerSynthesizer1.interruptSpeakingCalled)
        XCTAssertTrue(innerSynthesizer2.interruptSpeakingCalled)
    }

    @MainActor
    func testSpeakWithoutFallback() {
        let speakExpectation = XCTestExpectation(description: "Priority Synthesizer should be called")
        let dontSpeakExpectation = XCTestExpectation(description: "Fallback Synthesizer should not be called")
        dontSpeakExpectation.isInverted = true
        innerSynthesizer1.speakExpectation = speakExpectation
        innerSynthesizer2.speakExpectation = dontSpeakExpectation

        synthesizer.speak(spokenInstruction, during: .mock())

        wait(for: [speakExpectation, dontSpeakExpectation], timeout: 2)
    }

    @MainActor
    func testSpeakWithFallback() {
        let speakExpectation = XCTestExpectation(description: "Both Synthesizers should be called")
        speakExpectation.expectedFulfillmentCount = 2
        innerSynthesizer1.speechError = .unsupportedLocale(locale: .current)
        innerSynthesizer1.speakExpectation = speakExpectation
        innerSynthesizer2.speakExpectation = speakExpectation

        synthesizer.speak(spokenInstruction, during: .mock())

        wait(for: [speakExpectation], timeout: 3)
    }

    @MainActor
    func testSpeakWithFallbackIfUnableToControlAudio() {
        let speakExpectation = XCTestExpectation(description: "Priority Synthesizer should be called")
        let dontSpeakExpectation = XCTestExpectation(description: "Fallback Synthesizer should not be called")
        dontSpeakExpectation.isInverted = true
        innerSynthesizer1.speakExpectation = speakExpectation
        innerSynthesizer2.speakExpectation = dontSpeakExpectation
        innerSynthesizer1.speechError = .unableToControlAudio(
            instruction: spokenInstruction,
            action: .duck,
            underlying: nil
        )

        synthesizer.speak(spokenInstruction, during: .mock())

        wait(for: [speakExpectation], timeout: 3)
    }

    @MainActor
    func testDeinit() {
        let deinitExpectation = expectation(description: "Speech synthesizers should deinitialize")
        deinitExpectation.expectedFulfillmentCount = 2
        innerSynthesizer1.deinitExpectation = deinitExpectation
        innerSynthesizer2.deinitExpectation = deinitExpectation
        innerSynthesizer1.speechError = .unsupportedLocale(locale: .current)

        innerSynthesizer1 = nil
        innerSynthesizer2 = nil
        synthesizer = nil

        wait(for: [deinitExpectation], timeout: 3)
    }

    @MainActor
    func testMuted() {
        synthesizer.muted = true

        XCTAssertTrue(innerSynthesizer1.muted)
        XCTAssertTrue(innerSynthesizer2.muted)

        synthesizer.muted = false

        XCTAssertFalse(innerSynthesizer1.muted)
        XCTAssertFalse(innerSynthesizer2.muted)
    }

    @MainActor
    func testApplyLocale() {
        let locale = Locale(identifier: "ja_JP")
        synthesizer.locale = locale

        XCTAssertEqual(innerSynthesizer1.locale, locale)
        XCTAssertEqual(innerSynthesizer2.locale, locale)
    }

    @MainActor
    func testApplyVolume() {
        synthesizer.volume = .override(0.5)

        XCTAssertEqual(innerSynthesizer1.volume, .override(0.5))
        XCTAssertEqual(innerSynthesizer2.volume, .override(0.5))
    }
}
