
import AVFoundation
import MapboxDirections
import MapboxCoreNavigation
import MapboxSpeech

///
open class MapboxSpeechSynthesizerController: NSObject, SpeechSynthesizerController {
    
    // MARK: - Properties
    public var delegate: SpeechSynthesizerDelegate?
    
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
    
    private var speechSynthesizers: [SpeechSynthesizerController]
    private var currentLegProgress: RouteLegProgress?
        
    // MARK: - Lifecycle
    
    init(_ accessToken: String? = nil, speechSynthesizers: [SpeechSynthesizerController]? = nil) {
        self.speechSynthesizers = speechSynthesizers ?? [
            MapboxSpeechSynthesizer(accessToken),
            SystemSpeechSynthesizer()
        ]
        
        super.init()
        self.speechSynthesizers.forEach { $0.delegate = self }
    }
        
    // MARK: - Public Methods
    
    public func changedIncomingSpokenInstructions(_ instructions: [SpokenInstruction]) {
        speechSynthesizers.forEach { $0.changedIncomingSpokenInstructions(instructions) }
    }
    
    ///
    public func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress) {
        print(instruction.text)
        
        guard let synthesizer = speechSynthesizers.first else {
            assert(false, "MapboxSpeechSynthesizerController has 0 speechSynthesizers")
            delegate?.voiceController(self,
                                      didSpeak: instruction,
                                      with: nil)
            return
        }
                
        currentLegProgress = legProgress
        synthesizer.speak(instruction, during: legProgress)
    }
    
    ///
    public func stopSpeaking() {
        speechSynthesizers.forEach { $0.stopSpeaking() }
    }
    
    ///
    public func interruptSpeaking() {
        speechSynthesizers.forEach { $0.interruptSpeaking() }
    }
}

extension MapboxSpeechSynthesizerController: SpeechSynthesizerDelegate {
    
    public func voiceController(_ voiceController: SpeechSynthesizerController, didSpeak instruction: SpokenInstruction, with error: SpeechError?) {
        if let error = error {
            
            
            if let index = speechSynthesizers.firstIndex(where: { $0 === voiceController }),
                let legProgress = currentLegProgress,
                index + 1 < speechSynthesizers.count {
                delegate?.voiceController(self,
                                          encounteredError: error)
                speechSynthesizers[index + 1].speak(instruction, during: legProgress)
            }
            else {
                delegate?.voiceController(self,
                                          didSpeak: instruction,
                                          with: error)
            }
        }
        else {
            delegate?.voiceController(voiceController,
                                      didSpeak: instruction,
                                      with: nil)
        }
    }
    
    // Just forward delegate calls
    
    public func voiceController(_ voiceController: SpeechSynthesizerController, encounteredError error: SpeechError) {
        delegate?.voiceController(voiceController, encounteredError: error)
    }
    
    public func voiceController(_ voiceController: SpeechSynthesizerController, didInterrupt interruptedInstruction: SpokenInstruction, with interruptingInstruction: SpokenInstruction) {
        delegate?.voiceController(voiceController, didInterrupt: interruptedInstruction, with: interruptingInstruction)
    }
    
    public func voiceController(_ voiceController: SpeechSynthesizerController, willSpeak instruction: SpokenInstruction) -> SpokenInstruction? {
        return delegate?.voiceController(voiceController, willSpeak: instruction)
    }
}
