
import AVFoundation
import MapboxDirections
import MapboxCoreNavigation
import MapboxSpeech

class SystemSpeechSynthesizer: NSObject, SpeechSynthesizerController {
    
    // MARK: - Properties
    
    var muted: Bool = false // ???
    var volume: Float {
        get {
            return NavigationSettings.shared.voiceVolume
        }
        set {
            // ?!?!?!
        }
    }
    var isSpeaking: Bool { return speechSynth.isSpeaking }
    var locale: Locale = Locale.autoupdatingCurrent
    
    private lazy var speechSynth: AVSpeechSynthesizer = {
        let synth = AVSpeechSynthesizer()
        synth.delegate = self
        return synth
    } ()
    
    // MARK: - Public methods
    
    func changedIncomingSpokenInstructions(_ instructions: [SpokenInstruction]) {
        // Do nothing
    }
    
    func speak(_ instruction: SpokenInstruction) -> Error? {
        print("iOS SPEAKS!")
        
        var utterance: AVSpeechUtterance?
        if Locale.preferredLocalLanguageCountryCode == "en-US" {
            // Alex can’t handle attributed text.
            utterance = AVSpeechUtterance(string: instruction.text)
            utterance!.voice = AVSpeechSynthesisVoice(identifier: AVSpeechSynthesisVoiceIdentifierAlex)
        }
        
        let modifiedInstruction = /*voiceControllerDelegate?.voiceController(self, willSpeak: instruction, routeProgress: routeProgress!) ?? */instruction
        
        if utterance?.voice == nil {
            utterance = AVSpeechUtterance(string: modifiedInstruction.text)
        }
        
        // Only localized languages will have a proper fallback voice
        if utterance?.voice == nil {
            utterance?.voice = AVSpeechSynthesisVoice(language: Locale.preferredLocalLanguageCountryCode)
        }
        
        guard let utteranceToSpeak = utterance else {
            // !?!?!?!!??!
            let options = SpeechOptions(ssml: instruction.ssmlText)
            options.locale = Locale.current
            return SpeechError.noData(instruction: instruction,
                                      options: options)
        }
        speechSynth.speak(utteranceToSpeak)
        return nil
    }
    
    func stopSpeaking() {
        speechSynth.stopSpeaking(at: .word)
    }
    
    func interruptSpeaking() {
        speechSynth.stopSpeaking(at: .immediate)
    }
    
    // MARK: - Methods
    
    @discardableResult
    private func safeDuckAudio(instruction: SpokenInstruction?) -> Error? {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            if #available(iOS 12.0, *) {
                try audioSession.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers, .mixWithOthers])
            } else {
                try audioSession.setCategory(.ambient, mode: .spokenAudio, options: [.duckOthers, .mixWithOthers])
            }
            try audioSession.setActive(true)
        } catch {
            return SpeechError.unableToControlAudio(instruction: instruction,
                                                    action: .duck,
                                                    synthesizer: speechSynth,
                                                    underlying: error)
        }
        return nil
    }
    
    @discardableResult
    private func safeUnduckAudio(instruction: SpokenInstruction?) -> Error? {
        do {
            try AVAudioSession.sharedInstance().setActive(false,
                                                          options: [.notifyOthersOnDeactivation])
        } catch {
            return SpeechError.unableToControlAudio(instruction: instruction,
                                                    action: .duck,
                                                    synthesizer: speechSynth,
                                                    underlying: error)
        }
        return nil
    }
}

extension SystemSpeechSynthesizer: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        safeDuckAudio(instruction: nil)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        safeDuckAudio(instruction: nil)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        safeUnduckAudio(instruction: nil)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        safeUnduckAudio(instruction: nil)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        safeUnduckAudio(instruction: nil)
    }
}
