import Foundation
import MapboxSpeech
import AVFoundation
import MapboxCoreNavigation
import CoreLocation
import MapboxDirections

/**
 `PollyVoiceController` extends the default `RouteVoiceController` by providing support for AWSPolly. `RouteVoiceController` will be used as a fallback during poor network conditions.
 */
@objc(MBMapboxSpeechController)
public class MapboxSpeechController: RouteVoiceController {
    
    /**
     Number of seconds a Polly request can wait before it is canceled and the default speech synthesizer speaks the instruction.
     */
    @objc public var timeoutIntervalForRequest:TimeInterval = 5
    
    /**
     Number of steps ahead of the current step to cache spoken instructions.
     */
    @objc public var stepsAheadToCache: Int = 3
    
    /**
     Locale used to decide on language for spoken instruction.
     
     By default, the users device will be used to decide on the locale.
     */
    @objc public var locale: Locale?
    
    var pollyTask: URLSessionDataTask?
    
    let sessionConfiguration = URLSessionConfiguration.default
    var urlSession: URLSession
    var cacheURLSession: URLSession
    var cachePollyTask: URLSessionDataTask?
    
    var mapboxSpeechSynth: SpeechSynthesizer
    
    var spokenInstructionsForRoute = NSCache<NSString, NSData>()
    let localizedErrorMessage = NSLocalizedString("FAILED_INSTRUCTION", bundle: .mapboxNavigation, value: "Unable to read instruction aloud.", comment: "Error message when the SDK is unable to read a spoken instruction.")
    
    public init(accessToken: String? = nil, host: String? = nil) {
        
        if let accessToken = accessToken, let host = host {
            mapboxSpeechSynth = SpeechSynthesizer(accessToken: accessToken, host: host)
        } else if let accessToken = accessToken {
            mapboxSpeechSynth = SpeechSynthesizer(accessToken: accessToken)
        } else {
            mapboxSpeechSynth = SpeechSynthesizer.shared
        }
        
        spokenInstructionsForRoute.countLimit = 200
        sessionConfiguration.timeoutIntervalForRequest = timeoutIntervalForRequest;
        urlSession = URLSession(configuration: sessionConfiguration)
        cacheURLSession = URLSession(configuration: URLSessionConfiguration.default)
        
        super.init()
    }
    
    @objc public override func didPassSpokenInstructionPoint(notification: NSNotification) {
        let routeProgresss = notification.userInfo![MBRouteControllerDidPassSpokenInstructionPointRouteProgressKey] as! RouteProgress
        for (stepIndex, step) in routeProgresss.currentLegProgress.leg.steps.suffix(from: routeProgresss.currentLegProgress.stepIndex).enumerated() {
            let adjustedStepIndex = stepIndex + routeProgresss.currentLegProgress.stepIndex
            
            guard adjustedStepIndex < routeProgresss.currentLegProgress.stepIndex + stepsAheadToCache else { continue }
            guard let instructions = step.instructionsSpokenAlongStep else { continue }
            
            for instruction in instructions {
                guard spokenInstructionsForRoute.object(forKey: instruction.ssmlText as NSString) == nil else { continue }
                
                cacheSpokenInstruction(instruction: instruction.ssmlText)
            }
        }
        
        super.didPassSpokenInstructionPoint(notification: notification)
    }
    
    public override func speak(_ instruction: SpokenInstruction) {
        if let audioPlayer = audioPlayer, audioPlayer.isPlaying, let lastSpokenInstruction = lastSpokenInstruction {
            voiceControllerDelegate?.voiceController?(self, didInterrupt: lastSpokenInstruction, with: instruction)
        }
        pollyTask?.cancel()
        audioPlayer?.stop()
        lastSpokenInstruction = instruction
        
        guard spokenInstructionsForRoute.object(forKey: instruction.ssmlText as NSString) == nil else {
            play(spokenInstructionsForRoute.object(forKey: instruction.ssmlText as NSString)! as Data)
            return
        }
        
        cacheSpokenInstruction(instruction: instruction.ssmlText, alsoPlay: true)
    }
    
    func speakWithoutPolly(_ instruction: SpokenInstruction, error: Error) {
        pollyTask?.cancel()
        
        voiceControllerDelegate?.voiceController?(self, spokenInstructionsDidFailWith: error)
        
        guard let audioPlayer = audioPlayer else {
            super.speak(instruction)
            return
        }
        
        guard !audioPlayer.isPlaying else { return }
        
        super.speak(instruction)
    }
    
    func cacheSpokenInstruction(instruction: String, alsoPlay: Bool = false) {
        let options = SpeechOptions(ssml: instruction)
        if let locale = locale {
            options.locale = locale
        }
        mapboxSpeechSynth.audioData(with: options) { (data, error) in
            guard let data = data else { return }
            self.spokenInstructionsForRoute.setObject(data as NSData, forKey: instruction as NSString)
            
            if alsoPlay {
                self.play(data)
            }
        }
    }
    
    func play(_ data: Data) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                self.audioPlayer = try AVAudioPlayer(data: data)
                let prepared = self.audioPlayer?.prepareToPlay() ?? false
                
                guard prepared else {
                    self.speakWithoutPolly(self.lastSpokenInstruction!, error: NSError(code: .spokenInstructionFailed, localizedFailureReason: self.localizedErrorMessage, spokenInstructionCode: .audioPlayerFailedToPlay))
                    return
                }
                
                self.audioPlayer?.delegate = self
                try super.duckAudio()
                let played = self.audioPlayer?.play() ?? false
                
                guard played else {
                    self.speakWithoutPolly(self.lastSpokenInstruction!, error: NSError(code: .spokenInstructionFailed, localizedFailureReason: self.localizedErrorMessage, spokenInstructionCode: .audioPlayerFailedToPlay))
                    return
                }
                
            } catch  let error as NSError {
                self.speakWithoutPolly(self.lastSpokenInstruction!, error: error)
            }
        }
    }
}
