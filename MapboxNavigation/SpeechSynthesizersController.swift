
import AVFoundation
import MapboxDirections
import MapboxCoreNavigation
import MapboxSpeech

/// `SpeechSynthesizing`implementation, aggregating other implementations, to allow 'fallback' mechanism.
/// Can be initialized with array of synthesizers which will be called in order of appearance, untill one of them is capable to vocalize current `SpokenInstruction`
open class SpeechSynthesizersController: SpeechSynthesizing {
    
    // MARK: - Properties
    
    public var delegate: SpeechSynthesizingDelegate?
    
    public var muted: Bool = false {
        didSet {
            speechSynthesizers.forEach { $0.muted = muted }
        }
    }
    public var volume: Float = 1.0 {
        didSet {
            speechSynthesizers.forEach { $0.volume = volume }
        }
    }
    public var isSpeaking: Bool {
        return speechSynthesizers.first(where: { $0.isSpeaking }) != nil
    }
    public var locale: Locale = Locale.autoupdatingCurrent {
        didSet {
            speechSynthesizers.forEach { $0.locale = locale }
        }
    }
    
    public  let speechSynthesizers: [SpeechSynthesizing]
    
    private var currentLegProgress: RouteLegProgress?
    
    // MARK: - Lifecycle
    
    public init(_ speechSynthesizers: [SpeechSynthesizing]? = nil, accessToken: String? = nil) {
        self.speechSynthesizers = speechSynthesizers ?? [
            MapboxSpeechSynthesizer(accessToken),
            SystemSpeechSynthesizer()
        ]
        
        self.speechSynthesizers.forEach { $0.delegate = self }
    }
    
    // MARK: - Public Methods
    
    public func changedIncomingSpokenInstructions(_ instructions: [SpokenInstruction]) {
        speechSynthesizers.forEach { $0.changedIncomingSpokenInstructions(instructions) }
    }
    
    public func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress) {
        print(instruction.text)
        
        guard let synthesizer = speechSynthesizers.first else {
            assert(false, "SpeechSynthesizersController has 0 speechSynthesizers")
            delegate?.speechSynthesizer(self,
                                        didSpeak: instruction,
                                        with: nil)
            return
        }
        
        currentLegProgress = legProgress
        synthesizer.speak(instruction, during: legProgress)
    }
    
    public func stopSpeaking() {
        speechSynthesizers.forEach { $0.stopSpeaking() }
    }
    
    public func interruptSpeaking() {
        speechSynthesizers.forEach { $0.interruptSpeaking() }
    }
}

extension SpeechSynthesizersController: SpeechSynthesizingDelegate {
    
    public func speechSynthesizer(_ speechSynthesizer: SpeechSynthesizing, didSpeak instruction: SpokenInstruction, with error: SpeechError?) {
        if let error = error {
            
            
            if let index = speechSynthesizers.firstIndex(where: { $0 === speechSynthesizer }),
                let legProgress = currentLegProgress,
                index + 1 < speechSynthesizers.count {
                delegate?.speechSynthesizer(self,
                                            encounteredError: error)
                speechSynthesizers[index + 1].speak(instruction, during: legProgress)
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
