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
 The speech engine that encountered issues with audio control.
 - seealso: SpeechError
 */
public enum SpeechEngine {
    /**
     An API Audio Engine. Associated with a `SpeechSynthesizer`.
     */
    case api(_: SpeechSynthesizer?)
    /**
     A native speech engine. Associated with an `AVSpeechSynthesizer`.
     */
    case native(_: AVSpeechSynthesizer)

    /**
     An unkown speech engine. Associated with an unknown object.
     */
    case unknown(_: AnyObject)
}

/**
    A error type returned when encountering errors in the speech engine.
 */
public enum SpeechError: LocalizedError {
    /**
     The Speech API Did not successfully return a response.
     - parameter instruction: the instruction that failed.
     - parameter options: the SpeechOptions that were used to make the API request.
     - parameter underlying: the underlying `Error` returned by the API.
     */
    case apiError(instruction: SpokenInstruction, options: SpeechOptions, underlying: Error?)
    
    /**
     The Speech API Did not return any data.
     - parameter instruction: the instruction that failed.
     - parameter options: the SpeechOptions that were used to make the API request.
     */
    case noData(instruction: SpokenInstruction, options: SpeechOptions)
    
    /**
     The speech engine was unable to perform an action on the system audio service.
     - parameter instruction: The instruction that failed.
     - parameter action: a `SpeechFailureAction` that describes the action attempted
     - parameter engine: the `SpeechEngine` that tried to perform the action.
     - parameter underlying: the `Error` that was optrionally returned by the audio service.
     */
    case unableToControlAudio(instruction: SpokenInstruction?, action: SpeechFailureAction, engine: SpeechEngine, underlying: Error?)
    
    /**
     The speech engine was unable to initalize an audio player.
     - parameter playerType: the type of `AVAudioPlayer` that failed to initalize.
     - parameter instruction: The instruction that failed.
     - parameter engine: The `SpeechEngine` that attempted the initalization.
     - parameter underlying: the `Error` that was returned by the system audio service.
     */
    case unableToInitializePlayer(playerType: AVAudioPlayer.Type, instruction: SpokenInstruction, engine: SpeechEngine, underlying: Error)
    
    /**
     The active `RouteProgress` did not contain a speech locale.
     - parameter instruction: The instruction that failed.
     - parameter progress: the offending `RouteProgress` that omits the expected `SpeechLocale`.
     */
    case undefinedSpeechLocale(instruction: SpokenInstruction, progress: RouteProgress)
}
