import Foundation
import MapboxSpeech
import AVKit
import MapboxDirections
import MapboxCoreNavigation
@testable import MapboxNavigation

/**
 This class can be used as a substitute for SpeechSynthesizer under test, in order to verify whether expected calls were made.
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

public class SpeechSynthesizerSpy: SpeechSynthesizing {
    lazy var notifier: NotificationCenter = .default
    fileprivate typealias Note = Notification.Name.MapboxVoiceTests
    
    public init() {}
    
    public var delegate: SpeechSynthesizingDelegate?
    
    public var muted = false
    
    public var volume: Float = 0
    
    public var isSpeaking = false
    
    public var locale: Locale?
    
    public func prepareIncomingSpokenInstructions(_ instructions: [SpokenInstruction], locale: Locale?) {
        notifier.post(name: Note.prepareToPlay, object: self)
    }
    
    public func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress, locale: Locale?) {
        notifier.post(name: Note.play, object: self)
    }
    
    public func stopSpeaking() {}
    
    public func interruptSpeaking() {}
}

extension Notification.Name {
    public enum MapboxVoiceTests {
        public static let prepareToPlay = NSNotification.Name("MapboxVoiceTests.prepareToPlay")
        public static let play = NSNotification.Name("MapboxVoiceTests.play")
    }
}
