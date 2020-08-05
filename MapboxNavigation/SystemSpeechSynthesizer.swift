
import AVFoundation
import MapboxDirections
import MapboxCoreNavigation
import MapboxSpeech

/**
 `SpeechSynthesizing` implementation, using `AVSpeechSynthesizer`.
 */
open class SystemSpeechSynthesizer: NSObject, SpeechSynthesizing {
    
    // MARK: - Properties
    
    public weak var delegate: SpeechSynthesizingDelegate?
    public var muted: Bool = false {
        didSet {
            if isSpeaking {
                interruptSpeaking()
            }
        }
    }
    public var volume: Float {
        get {
            return NavigationSettings.shared.voiceVolume
        }
        set {
            // Do Nothing
            // AVSpeechSynthesizer uses 'AVAudioSession.sharedInstance().outputVolume' by default
        }
    }
    public var isSpeaking: Bool { return speechSynthesizer.isSpeaking }
    public var locale: Locale? = Locale.autoupdatingCurrent
    
    private var speechSynthesizer: AVSpeechSynthesizer
    private var previousInstrcution: SpokenInstruction?
    
    // MARK: - Lifecycle
    
    override public init() {
        speechSynthesizer = AVSpeechSynthesizer()
        super.init()
        speechSynthesizer.delegate = self
    }
    
    deinit {
        interruptSpeaking()
    }
    
    // MARK: - Public methods
    
    open func prepareIncomingSpokenInstructions(_ instructions: [SpokenInstruction], locale: Locale?) {
        // Do nothing
    }
    
    open func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress, locale: Locale? = nil) {
        guard !muted else {
            delegate?.speechSynthesizer(self,
                                        didSpeak: instruction,
                                        with: nil)
            return
        }
        
        guard let locale = locale ?? self.locale else {
            self.delegate?.speechSynthesizer(self,
                                             encounteredError: SpeechError.undefinedSpeechLocale(instruction: instruction))
            return
        }
        
        var utterance: AVSpeechUtterance?
        let localeCode = [locale.languageCode, locale.regionCode].compactMap{$0}.joined(separator: "-")
        
        if localeCode == "en-US" {
            // Alex can’t handle attributed text.
            utterance = AVSpeechUtterance(string: instruction.text)
            utterance!.voice = AVSpeechSynthesisVoice(identifier: AVSpeechSynthesisVoiceIdentifierAlex)
        }
        
        let modifiedInstruction = delegate?.speechSynthesizer(self, willSpeak: instruction) ?? instruction
        
        if utterance?.voice == nil {
            utterance = AVSpeechUtterance(attributedString: modifiedInstruction.attributedText(for: legProgress))
        }
        
        // Only localized languages will have a proper fallback voice
        if utterance?.voice == nil {
            utterance?.voice = AVSpeechSynthesisVoice(language: localeCode)
        }
        
        guard let utteranceToSpeak = utterance else {
            delegate?.speechSynthesizer(self,
                                        didSpeak: instruction,
                                        with: SpeechError.unsupportedLocale(locale: Locale.nationalizedCurrent))
            return
        }
        if let previousInstrcution = previousInstrcution, speechSynthesizer.isSpeaking {
            delegate?.speechSynthesizer(self,
                                        didInterrupt: previousInstrcution,
                                        with: modifiedInstruction)
        }
        
        previousInstrcution = modifiedInstruction
        speechSynthesizer.speak(utteranceToSpeak)
    }
    
    open func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .word)
    }
    
    open func interruptSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
    
    // MARK: - Methods
    
    private func safeDuckAudio() {
        
        if let error = AVAudioSession.sharedInstance().tryDuckAudio() {
            guard let instruction = previousInstrcution else {
                assert(false, "Speech Synthesizer finished speaking 'nil' instruction")
                return
            }
            
            delegate?.speechSynthesizer(self,
                                        encounteredError: SpeechError.unableToControlAudio(instruction: instruction,
                                                                                           action: .duck,
                                                                                           underlying: error))
        }
    }
    
    private func safeUnduckAudio() {
        if let error = AVAudioSession.sharedInstance().tryUnduckAudio() {
            guard let instruction = previousInstrcution else {
                assert(false, "Speech Synthesizer finished speaking 'nil' instruction")
                return
            }
            
            delegate?.speechSynthesizer(self,
                                        encounteredError: SpeechError.unableToControlAudio(instruction: instruction,
                                                                                           action: .unduck,
                                                                                           underlying: error))
        }
    }
}

extension SystemSpeechSynthesizer: AVSpeechSynthesizerDelegate {
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        safeDuckAudio()
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        safeDuckAudio()
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        safeUnduckAudio()
        guard let instruction = previousInstrcution else {
            assert(false, "Speech Synthesizer finished speaking 'nil' instruction")
            return
        }
        delegate?.speechSynthesizer(self,
                                    didSpeak: instruction,
                                    with: nil)
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        safeUnduckAudio()
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        safeUnduckAudio()
        guard let instruction = previousInstrcution else {
            assert(false, "Speech Synthesizer finished speaking 'nil' instruction")
            return
        }
        delegate?.speechSynthesizer(self,
                                    didSpeak: instruction,
                                    with: nil)
    }
}
