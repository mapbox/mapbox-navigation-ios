import AVKit
import Foundation
import MapboxDirections

/// The speech-related action that failed.
/// - Seealso: ``SpeechError``.
public enum SpeechFailureAction: String, Sendable {
    /// A failure occurred while attempting to mix audio.
    case mix
    /// A failure occurred while attempting to duck audio.
    case duck
    /// A failure occurred while attempting to unduck audio.
    case unduck
    /// A failure occurred while attempting to play audio.
    case play
}

/// A error type returned when encountering errors in the speech engine.
public enum SpeechError: LocalizedError {
    /// An error occurred when requesting speech assets from a server API.
    /// - Parameters:
    /// - instruction: the instruction that failed.
    /// - options: the SpeechOptions that were used to make the API request.
    /// - underlying: the underlying `Error` returned by the API.
    case apiError(instruction: SpokenInstruction, options: SpeechOptions, underlying: Error?)

    /// The speech engine did not fail with the error itself, but did not provide actual data to vocalize.
    /// - Parameters:
    /// - instruction: the instruction that failed.
    /// - options: the SpeechOptions that were used to make the API request.
    case noData(instruction: SpokenInstruction, options: SpeechOptions)

    /// The speech engine was unable to perform an action on the system audio service.
    /// - Parameters:
    /// - instruction: The instruction that failed.
    /// - action: a `SpeechFailureAction` that describes the action attempted.
    /// - underlying: the `Error` that was optrionally returned by the audio service.
    case unableToControlAudio(instruction: SpokenInstruction?, action: SpeechFailureAction, underlying: Error?)

    /// The speech engine was unable to initalize an audio player.
    /// - Parameters:
    /// - playerType: the type of `AVAudioPlayer` that failed to initalize.
    /// - instruction: The instruction that failed.
    /// - synthesizer: The speech engine that attempted the initalization.
    /// - underlying: the `Error` that was returned by the system audio service.
    case unableToInitializePlayer(
        playerType: AVAudioPlayer.Type,
        instruction: SpokenInstruction,
        synthesizer: Sendable?,
        underlying: Error
    )

    /// There was no `Locale` provided during processing instruction.
    /// - parameter instruction: The instruction that failed.
    case undefinedSpeechLocale(instruction: SpokenInstruction)

    /// The speech engine does not support provided locale
    /// - parameter locale: Offending locale.
    case unsupportedLocale(locale: Locale)
}
