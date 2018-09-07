import Foundation
import MapboxSpeech
@testable import MapboxNavigation
/**
 * This class can be used as a substitute for SpeechSynthesizer under test, in order to verify whether expected calls were made.
 */


class SpeechAPISpy: SpeechSynthesizer {
    struct AudioDataCall {
        static let sound = NSDataAsset(name: "reroute-sound", bundle: .mapboxNavigation)!
        
        let options: MapboxSpeech.SpeechOptions
        let completion: SpeechSynthesizer.CompletionHandler
        
        func fulfill() {
            completion(AudioDataCall.sound.data, nil)
        }
    }

    public var audioDataCalls: [AudioDataCall] = []

    override func audioData(with options: MapboxSpeech.SpeechOptions, completionHandler: @escaping MapboxSpeech.SpeechSynthesizer.CompletionHandler) -> URLSessionDataTask {
        let call = AudioDataCall(options: options, completion: completionHandler)
        audioDataCalls.append(call)
        return DummyURLSessionDataTask()
    }

    public func reset() {
        audioDataCalls.removeAll()
    }
}
