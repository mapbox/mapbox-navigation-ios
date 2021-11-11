import Foundation
import MapboxDirections
import MapboxCoreNavigation

/**
 Protocol for implementing speech synthesizer to be used in `RouteVoiceController`.
 */
public protocol SpeechSynthesizing: AnyObject {
    
    /// A delegate that will be notified about significant events related to spoken instructions.
    var delegate: SpeechSynthesizingDelegate? { get set }
    
    /// Controls muting playback of the synthesizer
    var muted: Bool { get set }
    /// Controls volume of the voice of the synthesizer. Should respect `NavigationSettings.voiceVolume`
    var volume: Float { get set }
    /// Returns `true` if synthesizer is speaking
    var isSpeaking: Bool { get }
    /// Locale setting to vocalization. This locale will be used as 'default' if no specific locale is passed for vocalizing each individual instruction.
    var locale: Locale? { get set }
    /// Controls if this speech synthesizer is allowed to manage the shared `AVAudioSession`.
    /// Set this field to `false` if you want to manage the session yourself, for example if your app has background music.
    /// Default value is `true`.
    var managesAudioSession: Bool { get set }
    
    /// Used to notify speech synthesizer about future spoken instructions in order to give extra time for preparations.
    /// - parameter instructions: An array of `SpokenInstruction`s that will be encountered further.
    /// - parameter locale: A locale to be used for preparing instructions. If `nil` is passed - `SpeechSynthesizing.locale` will be used as 'default'.
    ///
    /// It is not guaranteed that all these instructions will be spoken. For example navigation may be re-routed.
    /// This method may be (and most likely will be) called multiple times along the route progress
    func prepareIncomingSpokenInstructions(_ instructions: [SpokenInstruction], locale: Locale?)
    
    /// A request to vocalize the instruction
    /// - parameter instruction: an instruction to be vocalized
    /// - parameter legProgress: current leg progress, corresponding to the instruction
    /// - parameter locale: A locale to be used for vocalizing the instruction. If `nil` is passed - `SpeechSynthesizing.locale` will be used as 'default'.
    ///
    /// This method is not guaranteed to be synchronous or asynchronous. When vocalizing is finished, `voiceController(_ voiceController: SpeechSynthesizing, didSpeak instruction: SpokenInstruction, with error: SpeechError?)` should be called.
    func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress, locale: Locale?)
    
    /// Tells synthesizer to stop current vocalization in a graceful manner
    func stopSpeaking()
    /// Tells synthesizer to stop current vocalization immediately
    func interruptSpeaking()
}

/**
 The `SpeechSynthesizingDelegate` protocol defines methods that allow an object to respond to significant events related to spoken instructions.
 */
public protocol SpeechSynthesizingDelegate: AnyObject, UnimplementedLogging {
    /**
     Called when the speech synthesizer encountered an error during processing, but may still be able to speak the instruction.
     - parameter speechSynthesizer: The voice controller that experienced the failure.
     - parameter error: An error explaining the failure and its cause.
     */
    func speechSynthesizer(_ speechSynthesizer: SpeechSynthesizing, encounteredError error: SpeechError)
    
    /**
     Called when the speech synthesizer finished pronouncing the instruction or encountered an error, from which it cannot recover.
     - parameter speechSynthesizer: The speech synthesizer performing the action.
     - parameter instruction: The spoken instruction pronounced or attempted to pronounce
     - parameter error: An error explaining the failure and its cause if any
     */
    func speechSynthesizer(_ speechSynthesizer: SpeechSynthesizing, didSpeak instruction: SpokenInstruction, with error: SpeechError?)
    
    /**
     Called when one spoken instruction interrupts another instruction currently being spoken.
     
     - parameter speechSynthesizer: The speech synthesizer that experienced the interruption.
     - parameter interruptedInstruction: The spoken instruction currently in progress that has been interrupted.
     - parameter interruptingInstruction: The spoken instruction that is interrupting the current instruction.
     */
    func speechSynthesizer(_ speechSynthesizer: SpeechSynthesizing, didInterrupt interruptedInstruction: SpokenInstruction, with interruptingInstruction: SpokenInstruction)
    
    /**
     Called when a spoken instruction is about to be vocalized. Useful if it is necessary to give a custom instruction instead. Note that changing the `distanceAlongStep` property on `SpokenInstruction` will have no impact on when the instruction will be said.
     
     - parameter speechSynthesizer: The speech synthesizer that will speak an instruction.
     - parameter instruction: The spoken instruction that will be said.
     */
    func speechSynthesizer(_ speechSynthesizer: SpeechSynthesizing, willSpeak instruction: SpokenInstruction) -> SpokenInstruction?
}

public extension SpeechSynthesizingDelegate {
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func speechSynthesizer(_ speechSynthesizer: SpeechSynthesizing, encounteredError error: SpeechError) {
        logUnimplemented(protocolType: SpeechSynthesizingDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func speechSynthesizer(_ speechSynthesizer: SpeechSynthesizing, didSpeak instruction: SpokenInstruction, with error: SpeechError?) {
        logUnimplemented(protocolType: SpeechSynthesizingDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func speechSynthesizer(_ speechSynthesizer: SpeechSynthesizing, didInterrupt interruptedInstruction: SpokenInstruction, with interruptingInstruction: SpokenInstruction) {
        logUnimplemented(protocolType: SpeechSynthesizingDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func speechSynthesizer(_ speechSynthesizer: SpeechSynthesizing, willSpeak instruction: SpokenInstruction) -> SpokenInstruction? {
        logUnimplemented(protocolType: SpeechSynthesizingDelegate.self, level: .debug)
        return nil
    }
}
