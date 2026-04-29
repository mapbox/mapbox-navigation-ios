import Foundation

/// Text-To-Speech configuration.
public enum TTSConfig: Equatable, Sendable {
    public static func == (lhs: TTSConfig, rhs: TTSConfig) -> Bool {
        switch (lhs, rhs) {
        case (.default, .default),
             (.localOnly, .localOnly),
             (.custom, .custom):
            return true
        default:
            return false
        }
    }

    case `default`
    case localOnly
    case custom(speechSynthesizer: SpeechSynthesizing)
}
