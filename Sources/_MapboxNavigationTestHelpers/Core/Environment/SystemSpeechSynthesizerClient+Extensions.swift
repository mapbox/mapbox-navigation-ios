import Foundation
@testable import MapboxNavigationCore

extension SystemSpeechSynthesizerClient {
    public static var noopValue: Self {
        Self(
            isSpeaking: { true },
            stopSpeaking: { _ in },
            speak: { _ in }
        )
    }

    public static var testValue: Self {
        Self(
            isSpeaking: {
                fatalError("not implemented")
            },
            stopSpeaking: { _ in
                fatalError("not implemented")
            },
            speak: { _ in
                fatalError("not implemented")
            }
        )
    }
}
