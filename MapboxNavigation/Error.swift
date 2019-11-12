import Foundation
import MapboxCoreNavigation
import MapboxDirections
import MapboxSpeech
import AVKit

/**
 A enum representing the reason why the speech API request failed.
 - seealso: SpeechError
 */
public enum SpeechRequestFailureReason: String {
    /**
     No data was returned from the service.
     */
    case noData
    /**
     An erroneous response was returned from the server.
     */
    case apiError
}

/**
 An enum representing the action that failed to complete successfully.
 - seealso: SpeechError
 */
public enum SpeechFailureAction: String {
    /**
    A failure was encountered while attempting to mix audio.
     */
    case mix
    /**
    A failure was encountered while attempting to duck audio.
     */
    case duck
    /**
    A failure was encountered while attempting to unduck audio.
     */
    case unduck
    /**
    A failure was encountered while attempting to play audio.
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
     - parameter reason: a `SpeechRequestFailureReason` describing why the request failed.
     - parameter underlying: the underlying `Error` returned by the API.
     */
    case apiRequestFailed(instruction: SpokenInstruction, options: SpeechOptions, reason: SpeechRequestFailureReason, underlying: Error?)
    
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
    case unableToInitalizePlayer(playerType: AVAudioPlayer.Type, instruction: SpokenInstruction, engine: SpeechEngine, underlying: Error)
    
    /**
     The active `RouteProgress` did not contain a speech locale.
     - parameter instruction: The instruction that failed.
     - parameter progress: the offending `RouteProgress` that omits the expected `SpeechLocale`.
     */
    case undefinedSpeechLocale(instruction: SpokenInstruction, progress: RouteProgress)
}
