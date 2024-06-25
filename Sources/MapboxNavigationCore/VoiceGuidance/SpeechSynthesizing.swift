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

    /// Used to notify speech synthesizer about future spoken instructions in order to give extra time for preparations.
    /// - parameter instructions: An array of ``SpokenInstruction``s that will be encountered further.
    /// - parameter locale: A locale to be used for preparing instructions. If `nil` is passed -
    /// ``SpeechSynthesizing/locale`` will be used as 'default'.
    ///
    /// It is not guaranteed that all these instructions will be spoken. For example navigation may be re-routed.
    /// This method may be (and most likely will be) called multiple times along the route progress
    func prepareIncomingSpokenInstructions(_ instructions: [SpokenInstruction], locale: Locale?)

    /// A request to vocalize the instruction
    /// - parameter instruction: an instruction to be vocalized
    /// - parameter legProgress: current leg progress, corresponding to the instruction
    /// - parameter locale: A locale to be used for vocalizing the instruction. If `nil` is passed -
    /// ``SpeechSynthesizing/locale`` will be used as 'default'.
    ///
    /// This method is not guaranteed to be synchronous or asynchronous. When vocalizing is finished,
    /// ``VoiceInstructionEvents/DidSpeak`` should be published by ``voiceInstructions``.
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
