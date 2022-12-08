import Foundation
import MapboxDirections
import MapboxCoreNavigation
import TestHelper
@testable import MapboxNavigation

class TestableDayStyle: DayStyle {
    required init() {
        super.init()
        mapStyleURL = Fixture.blankStyle
    }
}

class SpeechSynthesizerStub: SpeechSynthesizing {
    weak var delegate: SpeechSynthesizingDelegate?
    var muted: Bool = false
    var volume: Float = 1.0
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

class RouteVoiceControllerStub: RouteVoiceController {
    init(navigationService: NavigationService, speechSynthesizer: SpeechSynthesizing? = nil) {
        super.init(navigationService: navigationService,
                   speechSynthesizer: speechSynthesizer ?? SpeechSynthesizerStub())
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
