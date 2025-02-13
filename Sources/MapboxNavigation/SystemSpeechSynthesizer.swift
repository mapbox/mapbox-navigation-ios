import AVFoundation
import MapboxDirections
import MapboxCoreNavigation
import MapboxSpeech

/**
 `SpeechSynthesizing` implementation, using `AVSpeechSynthesizer`.
 */
open class SystemSpeechSynthesizer: NSObject, SpeechSynthesizing {
    
    // MARK: Speech Configuration
    
    public weak var delegate: SpeechSynthesizingDelegate?
    public var muted: Bool = false {
        didSet {
            if muted, isSpeaking {
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
    
    public var locale: Locale? = Locale.autoupdatingCurrent
    
    /// Controls if this speech synthesizer is allowed to manage the shared `AVAudioSession`.
    /// Set this field to `false` if you want to manage the session yourself, for example if your app has background music.
    /// Default value is `true`.
    public var managesAudioSession = true
    
    // MARK: Speaking Instructions
    
    public var isSpeaking: Bool { return speechSynthesizer.isSpeaking }
    
    private var speechSynthesizer: AVSpeechSynthesizer
    
    private var previousInstruction: SpokenInstruction?
    
    override public init() {
        speechSynthesizer = AVSpeechSynthesizer()
        super.init()
        speechSynthesizer.delegate = self
    }
    
    deinit {
        interruptSpeaking()
        if !managesAudioSession {
            return
        }
        AVAudioSessionHelper.shared.unduckAudio(completion: nil)
    }
    
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
        if let previousInstruction = previousInstruction, speechSynthesizer.isSpeaking {
            delegate?.speechSynthesizer(self,
                                        didInterrupt: previousInstruction,
                                        with: modifiedInstruction)
        }
        
        previousInstruction = modifiedInstruction
        
        Log.debug("SystemSpeechSynthesizer: Requesting to speak: [\(utteranceToSpeak.speechString)]", category: .audio)
        safeDuckAudioAsync() { [weak self] in
            guard let self else { return }
            speechSynthesizer.speak(utteranceToSpeak)
        }
    }
    
    open func stopSpeaking() {
        Log.debug("SystemSpeechSynthesizer: Stop speaking", category: .audio)
        speechSynthesizer.stopSpeaking(at: .word)
    }
    
    open func interruptSpeaking() {
        Log.debug("SystemSpeechSynthesizer: Interrupt speaking", category: .audio)
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
    
    private func safeDuckAudioAsync(completion: (() -> Void)?) {
        guard managesAudioSession else {
            completion?()
            return
        }
        
        AVAudioSessionHelper.shared.duckAudio { [weak self] result in
            guard let self else { return }
            if case let .failure(error) = result {
                if previousInstruction == nil {
                    Log.warning("SystemSpeechSynthesizer: Speech Synthesizer finished speaking 'nil' instruction", category: .audio)
                }
                delegate?.speechSynthesizer(self,
                                            encounteredError: SpeechError.unableToControlAudio(instruction: previousInstruction,
                                                                                               action: .duck,
                                                                                               underlying: error))
            }
            completion?()
        }
    }
    
    private func safeDeferredUnduckAudio() {
        guard managesAudioSession else { return }
        let deactivationScheduled = AVAudioSessionHelper.shared.deferredUnduckAudio()
        if !deactivationScheduled {
            Log.debug(
                "SystemSpeechSynthesizer: Deactivation of AVAudioSession not scheduled - another one in progress",
                category: .audio
            )
        }
    }
}

extension SystemSpeechSynthesizer: AVSpeechSynthesizerDelegate {
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Log.debug("SystemSpeechSynthesizer: didStart utterance: [\(utterance.speechString)]", category: .audio)
    }
    
    public func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        if characterRange.location == 0 { // logging just first occurrence for utterance string
            Log.debug(
                "SystemSpeeechSynthesizer: willSpeakString utterance: [\(utterance.speechString)]",
                category: .audio
            )
        }
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        // Should never be called because AVSpeechSynthesizer's pauseSpeaking(at:) and continueSpeaking() are not used
        Log.warning(
            "SystemSpeechSynthesizer: Unexpectedly called didContinue utterance: [\(utterance.speechString)]",
            category: .audio
        )
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Log.debug(
            "SystemSpeechSynthesizer: didFinish utterance: [\(utterance.speechString), isSpeaking == \(synthesizer.isSpeaking)]",
            category: .audio
        )
        
        safeDeferredUnduckAudio()
        
        guard let instruction = previousInstruction else {
            Log.warning("SystemSpeechSynthesizer finished speaking 'nil' instruction", category: .audio)
            return
        }
        delegate?.speechSynthesizer(self,
                                    didSpeak: instruction,
                                    with: nil)
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        // Should never be called because AVSpeechSynthesizer's pauseSpeaking(at:) and continueSpeaking() are not used
        Log.warning(
            "SystemSpeechSynthesizer: Unexpectly called didPause utterance: [\(utterance.speechString)]",
            category: .audio
        )
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Log.debug(
            "SystemSpeechSynthesizer: didCancel utterance: [\(utterance.speechString), isSpeaking == \(synthesizer.isSpeaking)]",
            category: .audio
        )
        
        safeDeferredUnduckAudio()
        
        guard let instruction = previousInstruction else {
            Log.warning("SystemSpeechSynthesizer: Finished speaking 'nil' instruction", category: .audio)
            return
        }
        delegate?.speechSynthesizer(self,
                                    didSpeak: instruction,
                                    with: nil)
    }
}
