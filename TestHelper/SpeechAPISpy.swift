import Foundation
import MapboxSpeech
import AVKit
@testable import MapboxNavigation
/**
 * This class can be used as a substitute for SpeechSynthesizer under test, in order to verify whether expected calls were made.
 */


public class SpeechAPISpy: SpeechSynthesizer {
    public struct AudioDataCall {
        public static let sound = NSDataAsset(name: "reroute-sound", bundle: .mapboxNavigation)!
        
        public let options: MapboxSpeech.SpeechOptions
        public let completion: SpeechSynthesizer.CompletionHandler
        
        func fulfill() {
            completion(AudioDataCall.sound.data, nil)
        }
    }

    public var audioDataCalls: [AudioDataCall] = []

    override public func audioData(with options: MapboxSpeech.SpeechOptions, completionHandler: @escaping MapboxSpeech.SpeechSynthesizer.CompletionHandler) -> URLSessionDataTask {
        let call = AudioDataCall(options: options, completion: completionHandler)
        audioDataCalls.append(call)
        return DummyURLSessionDataTask()
    }

    public func reset() {
        audioDataCalls.removeAll()
    }
}

public class AudioPlayerDummy: AVAudioPlayer {
    public let sound = NSDataAsset(name: "reroute-sound", bundle: .mapboxNavigation)!
    
    lazy var notifier: NotificationCenter = .default
    fileprivate typealias Note = Notification.Name.MapboxVoiceTests
    
    override public func prepareToPlay() -> Bool {
        notifier.post(name: Note.prepareToPlay, object: self)
        return true
    }
    
    override public func play() -> Bool {
        notifier.post(name: Note.play, object: self)
        return true
    }
}

extension Notification.Name {
    public enum MapboxVoiceTests {
        public static let prepareToPlay = NSNotification.Name("MapboxVoiceTests.prepareToPlay")
        public static let play = NSNotification.Name("MapboxVoiceTests.play")
    }
}
