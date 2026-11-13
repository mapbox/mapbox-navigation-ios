import Foundation

/// Text-To-Speech configuration.
public enum TTSConfig: Equatable, Sendable {
    public static func == (lhs: TTSConfig, rhs: TTSConfig) -> Bool {
        switch (lhs, rhs) {
        case (.default, .default),
             (.localOnly, .localOnly):
            return true
        case (.custom(let lhs), .custom(let rhs)):
            return lhs === rhs
        default:
            return false
        }
    }

    case `default`
    case localOnly
    case custom(speechSynthesizer: SpeechSynthesizing)
}
