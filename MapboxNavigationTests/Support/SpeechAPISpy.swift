import Foundation
import MapboxSpeech

/**
 * This class can be used as a substitute for SpeechSynthesizer under test, in order to verify whether expected calls were made.
 */
class SpeechAPISpy: SpeechSynthesizer {

    typealias AudioDataCall = (MapboxSpeech.SpeechOptions, SpeechSynthesizer.CompletionHandler)

    public var audioDataCalls: [AudioDataCall] = []

    override func audioData(with options: MapboxSpeech.SpeechOptions, completionHandler: @escaping MapboxSpeech.SpeechSynthesizer.CompletionHandler) -> URLSessionDataTask {
        let call = (options, completionHandler)
        audioDataCalls.append(call)
        return DummyURLSessionDataTask()
    }

    public func reset() {
        audioDataCalls.removeAll()
    }
}
