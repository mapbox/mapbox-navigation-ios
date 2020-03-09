
import Foundation
import MapboxDirections
import MapboxCoreNavigation

public protocol SpeechSynthesizerController: class {
    
//    var delegate: SpeechSynthesizerDelegate?
    // typealias AudioControlFailureHandler = (SpeechError) -> Void
    
    ///
    var muted: Bool { get set }
    ///
    var volume: Float { get set }
    ///
    var isSpeaking: Bool { get }
    ///
    var locale: Locale { get set }
    
    ///
    func changedIncomingSpokenInstructions(_ instructions: [SpokenInstruction])
    ///
    @discardableResult
    func speak(_ instruction: SpokenInstruction) -> Error? // or String?
    
    ///
    func stopSpeaking()
    ///
    func interruptSpeaking() // ??
}

public protocol SpeechSynthesizerDelegate {
    
    func speechController(_ controller: SpeechSynthesizerController, didFinishSpeaking instruction: SpokenInstruction)
    
    func speechController(_ controller: SpeechSynthesizerController, didFail error: SpeechError)
}
