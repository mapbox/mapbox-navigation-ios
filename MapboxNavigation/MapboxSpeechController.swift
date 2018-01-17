import Foundation
import CoreLocation
import AVFoundation
import MapboxSpeech
import MapboxCoreNavigation
import MapboxDirections

/**
 `MapboxVoiceController` extends the default `RouteVoiceController` by providing a more robust speech synthesizer via the Mapbox Speech API. `RouteVoiceController` will be used as a fallback during poor network conditions.
 */
@objc(MBMapboxVoiceController)
public class MapboxVoiceController: RouteVoiceController {
    
    /**
     Number of seconds a request can wait before it is canceled and the default speech synthesizer speaks the instruction.
     */
    @objc public var timeoutIntervalForRequest:TimeInterval = 5
    
    /**
     Number of steps ahead of the current step to cache spoken instructions.
     */
    @objc public var stepsAheadToCache: Int = 3
    
    var audioTask: URLSessionDataTask?
    var spokenInstructionsForRoute = NSCache<NSString, NSData>()
    
    var speech: SpeechSynthesizer
    var locale: Locale?
    
    let localizedErrorMessage = NSLocalizedString("FAILED_INSTRUCTION", bundle: .mapboxNavigation, value: "Unable to read instruction aloud.", comment: "Error message when the SDK is unable to read a spoken instruction.")
    
    @objc public init(accessToken: String? = nil, host: String? = nil) {
        if let accessToken = accessToken, let host = host {
            speech = SpeechSynthesizer(accessToken: accessToken, host: host)
        } else if let accessToken = accessToken {
            speech = SpeechSynthesizer(accessToken: accessToken)
        } else {
            speech = SpeechSynthesizer.shared
        }
        
        spokenInstructionsForRoute.countLimit = 200
        
        super.init()
    }
    
    @objc open override func didPassSpokenInstructionPoint(notification: NSNotification) {
        let routeProgresss = notification.userInfo![MBRouteControllerDidPassSpokenInstructionPointRouteProgressKey] as! RouteProgress
        locale = routeProgresss.route.routeOptions.locale
        
        for (stepIndex, step) in routeProgresss.currentLegProgress.leg.steps.suffix(from: routeProgresss.currentLegProgress.stepIndex).enumerated() {
            let adjustedStepIndex = stepIndex + routeProgresss.currentLegProgress.stepIndex
            
            guard adjustedStepIndex < routeProgresss.currentLegProgress.stepIndex + stepsAheadToCache else { continue }
            guard let instructions = step.instructionsSpokenAlongStep else { continue }
            
            for instruction in instructions {
                guard spokenInstructionsForRoute.object(forKey: instruction.ssmlText as NSString) == nil else { continue }
                
                cacheSpokenInstruction(instruction: instruction)
            }
        }
        
        super.didPassSpokenInstructionPoint(notification: notification)
    }
    
    @objc open override func speak(_ instruction: SpokenInstruction) {
        if let audioPlayer = audioPlayer, audioPlayer.isPlaying, let lastSpokenInstruction = lastSpokenInstruction {
            voiceControllerDelegate?.voiceController?(self, didInterrupt: lastSpokenInstruction, with: instruction)
        }
        audioTask?.cancel()
        audioPlayer?.stop()
        
        assert(routeProgress != nil, "routeProgress should not be nil.")
        
        let modifiedInstruction = voiceControllerDelegate?.voiceController?(self, willSpeak: instruction, routeProgress: routeProgress!) ?? instruction
        lastSpokenInstruction = modifiedInstruction
        
        guard spokenInstructionsForRoute.object(forKey: modifiedInstruction.ssmlText as NSString) == nil else {
            play(spokenInstructionsForRoute.object(forKey: modifiedInstruction.ssmlText as NSString)! as Data)
            return
        }
        
        fetch(instruction: modifiedInstruction)
    }
    
    func speakWithoutPolly(_ instruction: SpokenInstruction, error: Error) {
        audioTask?.cancel()
        
        voiceControllerDelegate?.voiceController?(self, spokenInstructionsDidFailWith: error)
        
        guard let audioPlayer = audioPlayer else {
            super.speak(instruction)
            return
        }
        
        guard !audioPlayer.isPlaying else { return }
        
        super.speak(instruction)
    }
    
    func fetch(instruction: SpokenInstruction) {
        audioTask?.cancel()
        let options = SpeechOptions(ssml: instruction.ssmlText)
        if let locale = locale {
            options.locale = locale
        }
        
        audioTask = speech.audioData(with: options) { (data, error) in
            if let error = error as? URLError, error.code == .cancelled {
                return
            } else if let error = error {
                self.speakWithoutPolly(instruction, error: error)
                return
            }
            
            guard let data = data else {
                self.speakWithoutPolly(instruction, error: NSError(code: .spokenInstructionFailed, localizedFailureReason: self.localizedErrorMessage, spokenInstructionCode: .emptyMapboxSpeechResponse))
                return
            }
            self.play(data)
            self.spokenInstructionsForRoute.setObject(data as NSData, forKey: instruction.ssmlText as NSString)
        }
        
        audioTask?.resume()
    }
    
    func cacheSpokenInstruction(instruction: SpokenInstruction) {
        let options = SpeechOptions(ssml: instruction.ssmlText)
        if let locale = locale {
            options.locale = locale
        }
        
        speech.audioData(with: options) { (data, error) in
            guard let data = data else { return }
            self.spokenInstructionsForRoute.setObject(data as NSData, forKey: instruction.ssmlText as NSString)
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
