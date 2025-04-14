import Foundation
@testable import MapboxNavigationCore

extension RemoteSpeechSynthesizerClient {
    public static var noopValue: Self {
        Self { _ in
            Data()
        }
    }

    public static var testValue: Self {
        Self { _ in
            fatalError("not implemented")
        }
    }
}

extension SpeechSynthesizerClientProvider {
    public static var noopValue: Self {
        Self(
            remoteSpeechSynthesizer: { _, _ in .noopValue },
            systemSpeechSynthesizer: { _ in .noopValue }
        )
    }

    public static var testValue: Self {
        Self(
            remoteSpeechSynthesizer: { _, _ in .testValue },
            systemSpeechSynthesizer: { _ in .testValue }
        )
    }

    public static func value(with remoteClient: RemoteSpeechSynthesizerClient) -> Self {
        Self(
            remoteSpeechSynthesizer: { _, _ in remoteClient },
            systemSpeechSynthesizer: { _ in .testValue }
        )
    }

    public static func value(with systemClient: SystemSpeechSynthesizerClient) -> Self {
        Self(
            remoteSpeechSynthesizer: { _, _ in .testValue },
            systemSpeechSynthesizer: { _ in systemClient }
        )
    }
}
