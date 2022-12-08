import XCTest
import MapboxDirections
@testable import MapboxNavigation

class SpeechSynthesizingDelegateSpy: SpeechSynthesizingDelegate {
    var encounteredErrorCalled = false
    var didSpeakCalled = false
    var didInterruptCalled = false
    var willSpeakCalled = false

    var passedSpeechSynthesizer: SpeechSynthesizing!

    func speechSynthesizer(_ speechSynthesizer: SpeechSynthesizing, encounteredError error: SpeechError) {
        encounteredErrorCalled = true
        passedSpeechSynthesizer = speechSynthesizer
    }

    func speechSynthesizer(_ speechSynthesizer: SpeechSynthesizing, didSpeak instruction: SpokenInstruction, with error: SpeechError?) {
        didSpeakCalled = true
        passedSpeechSynthesizer = speechSynthesizer
    }

    func speechSynthesizer(_ speechSynthesizer: SpeechSynthesizing, didInterrupt interruptedInstruction: SpokenInstruction, with interruptingInstruction: SpokenInstruction) {
        didInterruptCalled = true
        passedSpeechSynthesizer = speechSynthesizer
    }

    func speechSynthesizer(_ speechSynthesizer: SpeechSynthesizing, willSpeak instruction: SpokenInstruction) -> SpokenInstruction? {
        willSpeakCalled = true
        passedSpeechSynthesizer = speechSynthesizer
        return instruction
    }

}

final class MultiplexedSpeechSynthesizerTests: XCTestCase {
    var synthesizer: MultiplexedSpeechSynthesizer!
    var delegate: SpeechSynthesizingDelegateSpy!
    
    var innerSynthesizer1: SpeechSynthesizerStub!
    var innerSynthesizer2: SpeechSynthesizerStub!

    let spokenInstruction = SpokenInstruction(distanceAlongStep: 100, text: "Text", ssmlText: "ssml text")

    override func setUp() {
        super.setUp()

        innerSynthesizer1 = SpeechSynthesizerStub()
        innerSynthesizer2 = SpeechSynthesizerStub()
        delegate = SpeechSynthesizingDelegateSpy()
        synthesizer = MultiplexedSpeechSynthesizer([innerSynthesizer1, innerSynthesizer2])
        synthesizer.delegate = delegate

        innerSynthesizer1.interruptSpeakingCalled = false
        innerSynthesizer2.interruptSpeakingCalled = false
    }

    func testWillSpeakIfNoOtherSynthesizersAreSpeaking() {
        let instruction = synthesizer.speechSynthesizer(innerSynthesizer1, willSpeak: spokenInstruction)

        XCTAssertEqual(instruction, spokenInstruction)
        XCTAssertTrue(delegate.passedSpeechSynthesizer === innerSynthesizer1)
        XCTAssertTrue(delegate.willSpeakCalled)

        XCTAssertFalse(innerSynthesizer1.interruptSpeakingCalled)
        XCTAssertFalse(innerSynthesizer2.interruptSpeakingCalled)
    }

    func testWillSpeakIfOtherSynthesizerIsSpeaking() {
        innerSynthesizer1.isSpeaking = true

        let instruction = synthesizer.speechSynthesizer(innerSynthesizer2, willSpeak: spokenInstruction)

        XCTAssertEqual(instruction, spokenInstruction)
        XCTAssertTrue(innerSynthesizer1.interruptSpeakingCalled)
        XCTAssertFalse(innerSynthesizer2.interruptSpeakingCalled)
    }

}
