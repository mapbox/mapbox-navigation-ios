import Foundation

struct RemoteSpeechSynthesizerClient {
    var audioData: @Sendable (_ options: SpeechOptions) async throws -> Data
}

struct SpeechSynthesizerClientProvider {
    var remoteSpeechSynthesizer: @Sendable (
        _ apiConfiguration: ApiConfiguration,
        _ skuTokenProvider: SkuTokenProvider
    ) -> RemoteSpeechSynthesizerClient

    var systemSpeechSynthesizer: @Sendable (
        _ avSpeechSynthesizer: SendableSpeechSynthesizer
    ) -> SystemSpeechSynthesizerClient
}

extension SpeechSynthesizerClientProvider {
    static var liveValue: Self {
        Self(
            remoteSpeechSynthesizer: { apiConfiguration, skuTokenProvider in
                let speechSynthesizer = RemoteSpeechSynthesizer(
                    apiConfiguration: apiConfiguration,
                    skuTokenProvider: skuTokenProvider
                )
                return RemoteSpeechSynthesizerClient { options in
                    try await speechSynthesizer.audioData(with: options)
                }
            },
            systemSpeechSynthesizer: { wrapper in
                SystemSpeechSynthesizerClient.client(with: wrapper)
            }
        )
    }
}
