import Foundation
import MapboxCoreNavigation
import MapboxDirections
import MapboxSpeech
import AVKit

/**
 The speech-related action that failed.
 - seealso: SpeechError
 */
public enum SpeechFailureAction: String {
    /**
     A failure occurred while attempting to mix audio.
     */
    case mix
    /**
     A failure occurred while attempting to duck audio.
     */
    case duck
    /**
     A failure occurred while attempting to unduck audio.
     */
    case unduck
    /**
     A failure occurred while attempting to play audio.
     */
    case play
}

/**
 A error type returned when encountering errors in the speech engine.
 */
public enum SpeechError: LocalizedError {
    /**
     An error occurred when requesting speech assets from a server API.
     - parameter instruction: the instruction that failed.
     - parameter options: the SpeechOptions that were used to make the API request.
     - parameter underlying: the underlying `Error` returned by the API.
     */
    case apiError(instruction: SpokenInstruction, options: SpeechOptions, underlying: Error?)
    
    /**
     The speech engine did not fail with the error itself, but did not provide actual data to vocalize.
     - parameter instruction: the instruction that failed.
     - parameter options: the SpeechOptions that were used to make the API request.
     */
    case noData(instruction: SpokenInstruction, options: SpeechOptions)
    
    /**
     The speech engine was unable to perform an action on the system audio service.
     - parameter instruction: The instruction that failed.
     - parameter action: a `SpeechFailureAction` that describes the action attempted
     - parameter underlying: the `Error` that was optrionally returned by the audio service.
     */
    case unableToControlAudio(instruction: SpokenInstruction?, action: SpeechFailureAction, underlying: Error?)
    
    /**
     The speech engine was unable to initalize an audio player.
     - parameter playerType: the type of `AVAudioPlayer` that failed to initalize.
     - parameter instruction: The instruction that failed.
     - parameter synthesizer: The speech engine that attempted the initalization.
     - parameter underlying: the `Error` that was returned by the system audio service.
     */
    case unableToInitializePlayer(playerType: AVAudioPlayer.Type, instruction: SpokenInstruction, synthesizer: Any?, underlying: Error)
    
    /**
     There was no `Locale` provided during processing instruction.
     - parameter instruction: The instruction that failed.
     */
    case undefinedSpeechLocale(instruction: SpokenInstruction)
    
    /**
     The speech engine does not support provided locale
     - parameter locale: Offending locale
     */
    case unsupportedLocale(locale: Locale)
}
