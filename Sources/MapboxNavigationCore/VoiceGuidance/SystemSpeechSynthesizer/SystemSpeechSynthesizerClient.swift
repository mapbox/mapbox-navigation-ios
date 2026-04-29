import AVFAudio
import Foundation

struct SystemSpeechSynthesizerClient {
    var isSpeaking: @Sendable @MainActor () -> Bool
    var stopSpeaking: @Sendable @MainActor (_ boundary: AVSpeechBoundary) -> Void
    var speak: @Sendable @MainActor (_ utterance: AVSpeechUtterance) -> Void
}

extension SystemSpeechSynthesizerClient {
    static func client(with wrapper: SendableSpeechSynthesizer) -> Self {
        return Self(
            isSpeaking: {
                wrapper.speechSynthesizer.isSpeaking
            },
            stopSpeaking: { boundary in
                wrapper.speechSynthesizer.stopSpeaking(at: boundary)
            },
            speak: { utterance in
                wrapper.speechSynthesizer.speak(utterance)
            }
        )
    }
}

@MainActor
final class SendableSpeechSynthesizer: Sendable {
    let speechSynthesizer: AVSpeechSynthesizer

    init(_ speechSynthesizer: AVSpeechSynthesizer) {
        self.speechSynthesizer = speechSynthesizer
    }
}
