import Foundation
import AWSPolly
import AVFoundation
import MapboxCoreNavigation
import CoreLocation
import MapboxDirections

/**
 `PollyVoiceController` extends the default `RouteVoiceController` by providing support for AWSPolly. `RouteVoiceController` will be used as a fallback during poor network conditions.
 */
@objc(MBPollyVoiceController)
public class PollyVoiceController: RouteVoiceController {
    
    /**
     Forces Polly voice to always be of specified type. If not set, a localized voice will be used.
     */
    @objc public var globalVoiceId: AWSPollyVoiceId = .unknown
    
    /**
     `regionType` specifies what AWS region to use for Polly.
     */
    @objc public let regionType: AWSRegionType
    
    /**
     `identityPoolId` is a required value for using AWS Polly voice instead of iOS's built in AVSpeechSynthesizer.
     You can get a token here: http://docs.aws.amazon.com/mobile/sdkforios/developerguide/cognito-auth-aws-identity-for-ios.html
     */
    @objc public var identityPoolId: String
    
    /**
     Number of seconds a Polly request can wait before it is canceled and the default speech synthesizer speaks the instruction.
     */
    @objc public var timeoutIntervalForRequest: TimeInterval = 5
    
    /**
     Number of steps ahead of the current step to cache spoken instructions.
     */
    @objc public var stepsAheadToCache: Int = 3
    
    var pollyTask: URLSessionDataTask?
    
    let sessionConfiguration = URLSessionConfiguration.default
    var urlSession: URLSession
    
    var cacheURLSession: URLSession
    var cachePollyTask: URLSessionDataTask?
    
    var spokenInstructionsForRoute = NSCache<NSString, NSData>()
    
    let localizedErrorMessage = NSLocalizedString("FAILED_INSTRUCTION", bundle: .mapboxNavigation, value: "Unable to read instruction aloud.", comment: "Error message when the SDK is unable to read a spoken instruction.")
    
    public init(identityPoolId: String, regionType: AWSRegionType = .USEast1) {
        self.identityPoolId = identityPoolId
        self.regionType = regionType
        
        spokenInstructionsForRoute.countLimit = 200
        
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: regionType, identityPoolId: identityPoolId)
        let configuration = AWSServiceConfiguration(region: regionType, credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        sessionConfiguration.timeoutIntervalForRequest = timeoutIntervalForRequest
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
    
    func pollyURL(for instruction: String) -> AWSPollySynthesizeSpeechURLBuilderRequest {
        let input = AWSPollySynthesizeSpeechURLBuilderRequest()
        input.textType = .ssml
        input.outputFormat = .mp3
        
        let langs = Locale.preferredLocalLanguageCountryCode.components(separatedBy: "-")
        let langCode = langs[0]
        var countryCode = ""
        if langs.count > 1 {
            countryCode = langs[1]
        }
        
        switch (langCode, countryCode) {
        case ("da", _):
            input.voiceId = .naja
        case ("de", _):
            input.voiceId = .marlene
        case ("en", "CA"):
            input.voiceId = .joanna
        case ("en", "GB"):
            input.voiceId = .brian
        case ("en", "AU"):
            input.voiceId = .nicole
        case ("en", "IN"):
            input.voiceId = .raveena
        case ("en", _):
            input.voiceId = .joanna
        case ("es", "ES"):
            input.voiceId = .enrique
        case ("es", _):
            input.voiceId = .miguel
        case ("fr", _):
            input.voiceId = .celine
        case ("it", _):
            input.voiceId = .giorgio
        case ("nl", _):
            input.voiceId = .lotte
        case ("pl", _):
            input.voiceId = .ewa
        case ("pt", "PT"):
            input.voiceId = .ines
        case ("pt", "BR"):
            input.voiceId = .vitoria
        case ("ro", _):
            input.voiceId = .carmen
        case ("ru", _):
            input.voiceId = .maxim
        case ("sv", _):
            input.voiceId = .astrid
        case ("tr", _):
            input.voiceId = .filiz
        default:
            input.voiceId = .joanna
        }
        
        if globalVoiceId != .unknown {
            input.voiceId = globalVoiceId
        }
        
        input.text = instruction
        
        return input
    }
    
    public override func speak(_ instruction: SpokenInstruction) {
        assert(routeProgress != nil, "routeProgress should not be nil.")
        
        if let audioPlayer = audioPlayer, audioPlayer.isPlaying, let lastSpokenInstruction = lastSpokenInstruction {
            voiceControllerDelegate?.voiceController?(self, didInterrupt: lastSpokenInstruction, with: instruction)
        }
        let modifiedInstruction = voiceControllerDelegate?.voiceController?(self, willSpeak: instruction, routeProgress: routeProgress!) ?? instruction
        pollyTask?.cancel()
        audioPlayer?.stop()
        lastSpokenInstruction = modifiedInstruction
        
        guard spokenInstructionsForRoute.object(forKey: modifiedInstruction.ssmlText as NSString) == nil else {
            play(spokenInstructionsForRoute.object(forKey: modifiedInstruction.ssmlText as NSString)! as Data)
            return
        }
        
        let input = pollyURL(for: modifiedInstruction.ssmlText)
        
        let builder = AWSPollySynthesizeSpeechURLBuilder.default().getPreSignedURL(input)
        builder.continueWith { [weak self] (awsTask: AWSTask<NSURL>) -> Any? in
            guard let strongSelf = self else {
                return nil
            }
            
            strongSelf.handle(awsTask, instruction: modifiedInstruction)
            
            return nil
        }
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
    
    func handle(_ awsTask: AWSTask<NSURL>, instruction: SpokenInstruction) {
        guard awsTask.error == nil else {
            speakWithoutPolly(instruction, error: awsTask.error!)
            return
        }
        
        guard let url = awsTask.result else {
            speakWithoutPolly(lastSpokenInstruction!, error: NSError(code: .spokenInstructionFailed, localizedFailureReason: localizedErrorMessage))
            return
        }
        
        pollyTask = urlSession.dataTask(with: url as URL) { [weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            
            // If the task is canceled, don't speak.
            // But if it's some sort of other error, use fallback voice.
            if let error = error as? URLError, error.code == .cancelled {
                return
            } else if let error = error {
                // Cannot call super in a closure
                strongSelf.speakWithoutPolly(strongSelf.lastSpokenInstruction!, error: error)
                return
            }
            
            guard let data = data else {
                strongSelf.speakWithoutPolly(strongSelf.lastSpokenInstruction!, error: NSError(code: .spokenInstructionFailed, localizedFailureReason: strongSelf.localizedErrorMessage, spokenInstructionCode: .emptyAwsResponse))
                return
            }
            
            strongSelf.play(data)
        }
        
        pollyTask?.resume()
    }
    
    func cacheSpokenInstruction(instruction: String) {
        let pollyRequestURL = pollyURL(for: instruction)
        
        let builder = AWSPollySynthesizeSpeechURLBuilder.default().getPreSignedURL(pollyRequestURL)
        builder.continueWith { [weak self] (awsTask: AWSTask<NSURL>) -> Any? in
            guard let strongSelf = self else {
                return nil
            }
            
            guard let url = awsTask.result else { return nil }
            
            strongSelf.cachePollyTask = strongSelf.cacheURLSession.dataTask(with: url as URL) { (data, response, error) in
                
                if let error = error {
                    print(error.localizedDescription)
                }
                
                if let data = data {
                    strongSelf.spokenInstructionsForRoute.setObject(data as NSData, forKey: instruction as NSString)
                }
            }
            
            strongSelf.cachePollyTask?.resume()
            
            return nil
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
