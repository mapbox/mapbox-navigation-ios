
import Foundation
import MapboxDirections
import MapboxCoreNavigation

public protocol SpeechSynthesizerController: class {
    typealias SpeechSynthesizerCompletion = (Error?) -> Void
    
    ///
    var delegate: SpeechSynthesizerDelegate? { get set }
    
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
    func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress)
    
    ///
    func stopSpeaking()
    ///
    func interruptSpeaking() // ??
}

/**
The `SpeechSynthesizerDelegate` protocol defines methods that allow an object to respond to significant events related to spoken instructions.
 */
public protocol SpeechSynthesizerDelegate: class, UnimplementedLogging {
    /**
     Called when the voice controller encountered an error during processing, but may still be able to speak the instuction.
     - parameter voiceController: The voice controller that experienced the failure.
     - parameter error: An error explaining the failure and its cause.
     */
    func voiceController(_ voiceController: SpeechSynthesizerController, encounteredError error: SpeechError)
    
    /**
    Called when the voice controller finished pronouncing the instruction or encountered an error, which it cannot recover from.
    - parameter voiceController: The voice controller performing the action.
    - parameter instruction: The spoken instruction pronounced or attempted to pronounce
    - parameter error: An error explaining the failure and its cause if any
    */
    func voiceController(_ voiceController: SpeechSynthesizerController, didSpeak instruction: SpokenInstruction, with error: SpeechError?)
    
    /**
     Called when one spoken instruction interrupts another instruction currently being spoken.
     
     - parameter voiceController: The voice controller that experienced the interruption.
     - parameter interruptedInstruction: The spoken instruction currently in progress that has been interrupted.
     - parameter interruptingInstruction: The spoken instruction that is interrupting the current instruction.
     */
    func voiceController(_ voiceController: SpeechSynthesizerController, didInterrupt interruptedInstruction: SpokenInstruction, with interruptingInstruction: SpokenInstruction)
    
    /**
     Called when a spoken is about to speak. Useful if it is necessary to give a custom instruction instead. Noting, changing the `distanceAlongStep` property on `SpokenInstruction` will have no impact on when the instruction will be said.
     
     - parameter voiceController: The voice controller that will speak an instruction.
     - parameter instruction: The spoken instruction that will be said.
     - parameter routeProgress: The `RouteProgress` just before when the instruction is scheduled to be spoken.
     */
    func voiceController(_ voiceController: SpeechSynthesizerController, willSpeak instruction: SpokenInstruction) -> SpokenInstruction?
}

public extension VoiceControllerDelegate {
    
    /**
    `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    */
    func voiceController(_ voiceController: SpeechSynthesizerController, encounteredError error: SpeechError) {
        logUnimplemented(protocolType: VoiceControllerDelegate.self, level: .debug)
    }
    
    /**
    `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    */
    func voiceController(_ voiceController: SpeechSynthesizerController, didSpeak instruction: SpokenInstruction, with error: SpeechError?) {
        logUnimplemented(protocolType: VoiceControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func voiceController(_ voiceController: SpeechSynthesizerController, didInterrupt interruptedInstruction: SpokenInstruction, with interruptingInstruction: SpokenInstruction) {
        logUnimplemented(protocolType: VoiceControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func voiceController(_ voiceController: SpeechSynthesizerController, willSpeak instruction: SpokenInstruction) -> SpokenInstruction? {
        logUnimplemented(protocolType: VoiceControllerDelegate.self, level: .debug)
        return nil
    }
}
