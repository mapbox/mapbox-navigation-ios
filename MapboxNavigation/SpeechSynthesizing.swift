
import Foundation
import MapboxDirections
import MapboxCoreNavigation

/**
 Protocol for implementing speech synthesizer to be used in `RouteVoiceController`.
 */
public protocol SpeechSynthesizing: class {
    
    /// A delegate that will be notified about significant events related to spoken instructions.
    var delegate: SpeechSynthesizingDelegate? { get set }
    
    /// Controls muting playback of the synthesizer
    var muted: Bool { get set }
    /// Controls volume of the voice of the synthesizer. Should respect `NavigationSettings.voiceVolume`
    var volume: Float { get set }
    /// Returns `true` if synthesizer is speaking
    var isSpeaking: Bool { get }
    /// Locale setting to vocalization
    var locale: Locale { get set }
    
    /// Used to notify speech synthesizer about future spoken instructions in order to give extra time for preparations.
    /// - parameter instructions: An array of `SpokenInstruction`s that will be encountered further.
    ///
    /// It is not guaranteed that all these instructions will be spoken. For example navigation may be re-routed.
    /// This method may be (and most likely will be) called multiple times along the route progress
    func changedIncomingSpokenInstructions(_ instructions: [SpokenInstruction])
    
    /// A request to vocalize the instruction
    /// - parameter instruction: an instruction to be vocalized
    /// - parameter legProgress: current leg progress, corresponding to the instruction
    ///
    /// This method is not guaranteed to be synchronous or asynchronous. When vocalizing is finished, `voiceController(_ voiceController: SpeechSynthesizing, didSpeak instruction: SpokenInstruction, with error: SpeechError?)` should be called.
    func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress)
    
    /// Tells synthesizer to stop current vocalization in a graceful manner
    func stopSpeaking()
    /// Tells synthesizer to stop current vocalization immediately
    func interruptSpeaking()
}

/**
The `SpeechSynthesizingDelegate` protocol defines methods that allow an object to respond to significant events related to spoken instructions.
 */
public protocol SpeechSynthesizingDelegate: class, UnimplementedLogging {
    /**
     Called when the voice controller encountered an error during processing, but may still be able to speak the instuction.
     - parameter voiceController: The voice controller that experienced the failure.
     - parameter error: An error explaining the failure and its cause.
     */
    func voiceController(_ voiceController: SpeechSynthesizing, encounteredError error: SpeechError)
    
    /**
    Called when the voice controller finished pronouncing the instruction or encountered an error, which it cannot recover from.
    - parameter voiceController: The voice controller performing the action.
    - parameter instruction: The spoken instruction pronounced or attempted to pronounce
    - parameter error: An error explaining the failure and its cause if any
    */
    func voiceController(_ voiceController: SpeechSynthesizing, didSpeak instruction: SpokenInstruction, with error: SpeechError?)
    
    /**
     Called when one spoken instruction interrupts another instruction currently being spoken.
     
     - parameter voiceController: The voice controller that experienced the interruption.
     - parameter interruptedInstruction: The spoken instruction currently in progress that has been interrupted.
     - parameter interruptingInstruction: The spoken instruction that is interrupting the current instruction.
     */
    func voiceController(_ voiceController: SpeechSynthesizing, didInterrupt interruptedInstruction: SpokenInstruction, with interruptingInstruction: SpokenInstruction)
    
    /**
     Called when a spoken is about to speak. Useful if it is necessary to give a custom instruction instead. Noting, changing the `distanceAlongStep` property on `SpokenInstruction` will have no impact on when the instruction will be said.
     
     - parameter voiceController: The voice controller that will speak an instruction.
     - parameter instruction: The spoken instruction that will be said.
     - parameter routeProgress: The `RouteProgress` just before when the instruction is scheduled to be spoken.
     */
    func voiceController(_ voiceController: SpeechSynthesizing, willSpeak instruction: SpokenInstruction) -> SpokenInstruction?
}

public extension VoiceControllerDelegate {
    
    /**
    `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    */
    func voiceController(_ voiceController: SpeechSynthesizing, encounteredError error: SpeechError) {
        logUnimplemented(protocolType: VoiceControllerDelegate.self, level: .debug)
    }
    
    /**
    `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    */
    func voiceController(_ voiceController: SpeechSynthesizing, didSpeak instruction: SpokenInstruction, with error: SpeechError?) {
        logUnimplemented(protocolType: VoiceControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func voiceController(_ voiceController: SpeechSynthesizing, didInterrupt interruptedInstruction: SpokenInstruction, with interruptingInstruction: SpokenInstruction) {
        logUnimplemented(protocolType: VoiceControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func voiceController(_ voiceController: SpeechSynthesizing, willSpeak instruction: SpokenInstruction) -> SpokenInstruction? {
        logUnimplemented(protocolType: VoiceControllerDelegate.self, level: .debug)
        return nil
    }
}
