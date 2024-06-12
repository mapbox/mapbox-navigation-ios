import Combine
import Foundation
import MapboxDirections
import MapboxNavigationCore
@testable import MapboxNavigationUIKit
import TestHelper

class TestableDayStyle: DayStyle {
    required init() {
        super.init()
        mapStyleURL = Fixture.blankStyle
    }
}

class SpeechSynthesizerStub: SpeechSynthesizing {
    var _voiceInstructions: PassthroughSubject<VoiceInstructionEvent, Never> = .init()
    var voiceInstructions: AnyPublisher<VoiceInstructionEvent, Never> {
        _voiceInstructions.eraseToAnyPublisher()
    }

    var muted: Bool = false
    var volume: MapboxNavigationCore.VolumeMode = .system
    var isSpeaking: Bool = false
    var locale: Locale? = Locale.autoupdatingCurrent
    var managesAudioSession = true

    var passedLocale: Locale?
    var passedInstruction: SpokenInstruction?
    var passedInstructions: [SpokenInstruction]?

    var prepareIncomingSpokenInstructionsCalled = false
    var speakCalled = false
    var stopSpeakingCalled = false
    var interruptSpeakingCalled = false

    func prepareIncomingSpokenInstructions(_ instructions: [SpokenInstruction], locale: Locale?) {
        prepareIncomingSpokenInstructionsCalled = true
        passedInstructions = instructions
        passedLocale = locale
    }

    func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress, locale: Locale?) {
        speakCalled = true
        passedInstruction = instruction
        passedLocale = locale
    }

    func stopSpeaking() {
        stopSpeakingCalled = true
    }

    func interruptSpeaking() {
        interruptSpeakingCalled = true
    }
}

class NavigationLocationManagerStub: NavigationLocationManager {
    override func startUpdatingLocation() {
        return
    }

    override func startUpdatingHeading() {
        return
    }
}
