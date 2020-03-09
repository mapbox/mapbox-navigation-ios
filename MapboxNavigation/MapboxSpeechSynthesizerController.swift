
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
    @discardableResult
    public func speak(_ instruction: SpokenInstruction) -> Error? {
        print(instruction.text)
        
        _ = speechSynthesizers.first(where: { $0.speak(instruction) == nil })
        
        return nil
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
