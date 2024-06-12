import Combine
import Foundation
import MapboxNavigationCore
import XCTest

public class SpeechSynthesizerMock: SpeechSynthesizing {
    public var _voiceInstructions: PassthroughSubject<VoiceInstructionEvent, Never> = .init()
    public var voiceInstructions: AnyPublisher<VoiceInstructionEvent, Never> {
        _voiceInstructions.eraseToAnyPublisher()
    }

    public var muted: Bool = false
    public var volume: MapboxNavigationCore.VolumeMode = .system
    public var isSpeaking: Bool = false
    public var locale: Locale? = Locale.autoupdatingCurrent
    public var managesAudioSession = true

    public var passedLocale: Locale?
    public var passedInstruction: SpokenInstruction?
    public var passedInstructions: [SpokenInstruction]?

    public var prepareIncomingSpokenInstructionsCalled = false
    public var speakCalled = false
    public var stopSpeakingCalled = false
    public var interruptSpeakingCalled = false

    public var deinitExpectation: XCTestExpectation?
    public var speakExpectation: XCTestExpectation?
    public var speechError: SpeechError?

    public init() {}

    public func prepareIncomingSpokenInstructions(_ instructions: [SpokenInstruction], locale: Locale?) {
        prepareIncomingSpokenInstructionsCalled = true
        passedInstructions = instructions
        passedLocale = locale
    }

    public func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress, locale: Locale?) {
        speakCalled = true
        passedInstruction = instruction
        passedLocale = locale
        speakExpectation?.fulfill()
        if let speechError {
            _voiceInstructions.send(VoiceInstructionEvents.EncounteredError(error: speechError))
        }
    }

    public func stopSpeaking() {
        stopSpeakingCalled = true
    }

    public func interruptSpeaking() {
        interruptSpeakingCalled = true
    }

    deinit {
        deinitExpectation?.fulfill()
    }
}
