
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
    public func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress, completion: SpeechSynthesizerCompletion?) {
        print(instruction.text)
        
        guard let synthesizer = speechSynthesizers.first else { return }
        
        var i = 0
        var recursiveCompletion: SpeechSynthesizerCompletion?
        recursiveCompletion = { [weak self] in
            guard let self = self else {
                completion?(nil)
                return
            }
            
            if let error = $0 {
                print(error.localizedDescription)
                i += 1
                if i < self.speechSynthesizers.count {
                    self.speechSynthesizers[i].speak(instruction, during: legProgress, completion: recursiveCompletion)
                }
                else {
                    completion?(error)
                }
            }
            
            completion?(nil)
        }
        
        synthesizer.speak(instruction, during: legProgress, completion: recursiveCompletion)
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
    
    // Just forward delegate calls
    
    public func voiceController(_ voiceController: SpeechSynthesizerController, spokenInstructionsDidFailWith error: SpeechError) {
        delegate?.voiceController(voiceController, spokenInstructionsDidFailWith: error)
    }
    
    public func voiceController(_ voiceController: SpeechSynthesizerController, didInterrupt interruptedInstruction: SpokenInstruction, with interruptingInstruction: SpokenInstruction) {
        delegate?.voiceController(voiceController, didInterrupt: interruptedInstruction, with: interruptingInstruction)
    }
    
    public func voiceController(_ voiceController: SpeechSynthesizerController, willSpeak instruction: SpokenInstruction) -> SpokenInstruction? {
        return delegate?.voiceController(voiceController, willSpeak: instruction)
    }
}
