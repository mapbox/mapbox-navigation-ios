
import AVFoundation
import MapboxDirections
import MapboxCoreNavigation
import MapboxSpeech

///
open class MapboxSpeechSynthesizerController: NSObject, SpeechSynthesizerController {
    
    // MARK: - Properties
    
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
    }
        
    // MARK: - Public Methods
    
    public func changedIncomingSpokenInstructions(_ instructions: [SpokenInstruction]) {
        speechSynthesizers.forEach { $0.changedIncomingSpokenInstructions(instructions) }
    }
    
    ///
    public func speak(_ instruction: SpokenInstruction, completion: SpeechSynthesizerCompletion?) {
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
                    self.speechSynthesizers[i].speak(instruction, completion: recursiveCompletion)
                }
                else {
                    completion?(error)
                }
            }
            
            completion?(nil)
        }
        
        synthesizer.speak(instruction, completion: recursiveCompletion)
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
