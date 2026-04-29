import Combine
import Foundation
import MapboxDirections

/// Protocol for implementing speech synthesizer to be used in ``RouteVoiceController``.
@MainActor
public protocol SpeechSynthesizing: AnyObject, Sendable {
    var voiceInstructions: AnyPublisher<VoiceInstructionEvent, Never> { get }

    /// Controls muting playback of the synthesizer
    var muted: Bool { get set }
    /// Controls volume of the voice of the synthesizer.
    var volume: VolumeMode { get set }
    /// Returns `true` if synthesizer is speaking
    var isSpeaking: Bool { get }
    /// Locale setting to vocalization. This locale will be used as 'default' if no specific locale is passed for
    /// vocalizing each individual instruction.
    var locale: Locale? { get set }
    /// Controls if this speech synthesizer is allowed to manage the shared `AVAudioSession`.
    /// Set this field to `false` if you want to manage the session yourself, for example if your app has background
    /// music.
    /// Default value is `true`.
    var managesAudioSession: Bool { get set }

    /// Notifies the speech synthesizer about future spoken instructions to give time for preloading and preparation.
    ///
    /// This method helps reduce latency by preloading audio for instructions that will be spoken soon. It attempts to
    /// download and cache the audio for each provided instruction, using the specified locale for synthesis.
    /// It is not guaranteed that all these instructions will be spoken. For example, navigation may be re-routed.
    /// This method may be (and most likely will be) called multiple times along the route progress
    /// - Parameters:
    ///   - instructions: An array of upcoming ``SpokenInstruction`` instances that should be prepared in advance.
    ///   - locale: The locale to use for preparing the spoken instructions. If `nil`, an error will be sent to the
    /// ``SpeechSynthesizing/voiceInstructions`` stream indicating a missing speech locale.
    func prepareIncomingSpokenInstructions(_ instructions: [SpokenInstruction], locale: Locale?)

    /// Requests the vocalization of a given spoken instruction.
    ///
    /// This method handles the playback of a spoken instruction, using cached audio data if available.
    /// If no cached data is found, it initiates a download before speaking.
    /// When vocalizing is finished, ``VoiceInstructionEvents/DidSpeak`` should be published by
    /// ``SpeechSynthesizing/voiceInstructions``.
    /// - Parameters:
    ///   - instruction: The ``SpokenInstruction`` to be vocalized.
    ///   - legProgress: The current ``RouteLegProgress`` associated with the instruction.
    ///   - locale: The `Locale` to be used for speech synthesis.
    func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress, locale: Locale?)

    /// Tells synthesizer to stop current vocalization in a graceful manner.
    func stopSpeaking()
    /// Tells synthesizer to stop current vocalization immediately.
    func interruptSpeaking()
}

public protocol VoiceInstructionEvent {}

public enum VoiceInstructionEvents {
    public struct WillSpeak: VoiceInstructionEvent, Equatable {
        public let instruction: SpokenInstruction

        public init(instruction: SpokenInstruction) {
            self.instruction = instruction
        }
    }

    public struct DidSpeak: VoiceInstructionEvent, Equatable {
        public let instruction: SpokenInstruction

        public init(instruction: SpokenInstruction) {
            self.instruction = instruction
        }
    }

    public struct DidInterrupt: VoiceInstructionEvent, Equatable {
        public let interruptedInstruction: SpokenInstruction
        public let interruptingInstruction: SpokenInstruction

        public init(interruptedInstruction: SpokenInstruction, interruptingInstruction: SpokenInstruction) {
            self.interruptedInstruction = interruptedInstruction
            self.interruptingInstruction = interruptingInstruction
        }
    }

    public struct EncounteredError: VoiceInstructionEvent {
        public let error: SpeechError

        public init(error: SpeechError) {
            self.error = error
        }
    }
}

public enum VolumeMode: Equatable, Sendable {
    case system
    case override(Float)
}
