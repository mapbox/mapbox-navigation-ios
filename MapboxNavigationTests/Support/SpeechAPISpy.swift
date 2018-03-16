import Foundation
import MapboxSpeech

class DummyURLSessionDataTask: URLSessionDataTask {

}

/**
 * This class can be used as a substitute for SpeechSynthesizer under test, in order to verify whether expected calls were made.
 */
class SpeechAPISpy: SpeechSynthesizer {

    override func audioData(with options: MapboxSpeech.SpeechOptions, completionHandler: @escaping MapboxSpeech.SpeechSynthesizer.CompletionHandler) -> URLSessionDataTask {
        return DummyURLSessionDataTask()
    }
}
