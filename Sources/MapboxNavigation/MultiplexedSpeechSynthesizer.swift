import AVFoundation
import MapboxDirections
import MapboxCoreNavigation
import MapboxSpeech

/// `SpeechSynthesizing`implementation, aggregating other implementations, to allow 'fallback' mechanism.
/// Can be initialized with array of synthesizers which will be called in order of appearance, until one of them is capable to vocalize current `SpokenInstruction`
open class MultiplexedSpeechSynthesizer: SpeechSynthesizing {
    
    // MARK: Speech Configuration
    
    public weak var delegate: SpeechSynthesizingDelegate?
    
    public var muted: Bool = false {
        didSet {
            applyMute()
        }
    }
    public var volume: Float = 1.0 {
        didSet {
            applyVolume()
        }
    }
    
    public var locale: Locale? = Locale.autoupdatingCurrent {
        didSet {
            applyLocale()
        }
    }
    
    private func applyMute() {
        speechSynthesizers.forEach { $0.muted = muted }
    }
    
    private func applyVolume() {
        speechSynthesizers.forEach { $0.volume = volume }
    }
    
    private func applyLocale() {
        speechSynthesizers.forEach { $0.locale = locale }
    }
    
    /// Controls if this speech synthesizer is allowed to manage the shared `AVAudioSession`.
    /// Set this field to `false` if you want to manage the session yourself, for example if your app has background music.
    /// Default value is `true`.
    public var managesAudioSession: Bool {
        get {
            speechSynthesizers.allSatisfy { $0.managesAudioSession == true }
        }
        set {
            speechSynthesizers.forEach { $0.managesAudioSession = newValue }
        }
    }
    
    // MARK: Instructions vocalization
    
    public var isSpeaking: Bool {
        return speechSynthesizers.first(where: { $0.isSpeaking }) != nil
    }
    
    public var speechSynthesizers: [SpeechSynthesizing] {
        willSet {
            var found: [SpeechSynthesizing] = []
            let duplicate = newValue.first { newSynth in
                if found.first(where: {
                    return $0 === newSynth
                }) == nil {
                    found.append(newSynth)
                    return false
                }
                return true
            }
            
            precondition(duplicate == nil, "Single `SpeechSynthesizing` object passed to `MultiplexedSpeechSynthesizer` multiple times!")
            
            speechSynthesizers.forEach {
                $0.interruptSpeaking()
                $0.delegate = nil
            }
        }
        didSet {
            speechSynthesizers.forEach { $0.delegate = self }
            applyMute()
            applyVolume()
            applyLocale()
        }
    }
    
    private var currentLegProgress: RouteLegProgress?
    
    public init(_ speechSynthesizers: [SpeechSynthesizing]? = nil, accessToken: String? = nil, host: String? = nil) {
        let synthesizers = speechSynthesizers ?? [
            MapboxSpeechSynthesizer(accessToken: accessToken, host: host),
            SystemSpeechSynthesizer()]
        self.speechSynthesizers = synthesizers
        
        // a trick to force willSet and didSet to be triggered in init()
        defer {
            self.speechSynthesizers = Array(synthesizers)
        }
    }
    
    public func prepareIncomingSpokenInstructions(_ instructions: [SpokenInstruction], locale: Locale? = nil) {
        speechSynthesizers.forEach { $0.prepareIncomingSpokenInstructions(instructions, locale: locale) }
    }
    
    public func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress, locale: Locale? = nil) {
        currentLegProgress = legProgress
        speechSynthesizers.first?.speak(instruction, during: legProgress, locale: locale)
    }
    
    public func stopSpeaking() {
        speechSynthesizers.forEach { $0.stopSpeaking() }
    }
    
    public func interruptSpeaking() {
        speechSynthesizers.forEach { $0.interruptSpeaking() }
    }
}

extension MultiplexedSpeechSynthesizer: SpeechSynthesizingDelegate {
    
    // MARK: SpeechSynthesizingDelegate Implementation
    
    public func speechSynthesizer(_ speechSynthesizer: SpeechSynthesizing, didSpeak instruction: SpokenInstruction, with error: SpeechError?) {
        if let error = error {
            if let index = speechSynthesizers.firstIndex(where: { $0 === speechSynthesizer }),
                let legProgress = currentLegProgress,
                index + 1 < speechSynthesizers.count {
                delegate?.speechSynthesizer(self,
                                            encounteredError: error)
                speechSynthesizers[index + 1].speak(instruction, during: legProgress, locale: locale)
            }
            else {
                delegate?.speechSynthesizer(self,
                                            didSpeak: instruction,
                                            with: error)
            }
        }
        else {
            delegate?.speechSynthesizer(speechSynthesizer,
                                        didSpeak: instruction,
                                        with: nil)
        }
    }
    
    // Just forward delegate calls
    
    public func speechSynthesizer(_ speechSynthesizer: SpeechSynthesizing, encounteredError error: SpeechError) {
        delegate?.speechSynthesizer(speechSynthesizer, encounteredError: error)
    }
    
    public func speechSynthesizer(_ speechSynthesizer: SpeechSynthesizing, didInterrupt interruptedInstruction: SpokenInstruction, with interruptingInstruction: SpokenInstruction) {
        delegate?.speechSynthesizer(speechSynthesizer, didInterrupt: interruptedInstruction, with: interruptingInstruction)
    }
    
    public func speechSynthesizer(_ speechSynthesizer: SpeechSynthesizing, willSpeak instruction: SpokenInstruction) -> SpokenInstruction? {
        return delegate?.speechSynthesizer(speechSynthesizer, willSpeak: instruction)
    }
}
