import Foundation
import AWSPolly
import AVFoundation
import MapboxCoreNavigation
import CoreLocation

/**
 `PollyVoiceController` extends the default `RouteVoiceController` by providing support for AWSPolly. `RouteVoiceController` will be used as a fallback during poor network conditions.
 */
@objc(MBPollyVoiceController)
public class PollyVoiceController: RouteVoiceController {
    
    /**
     Forces Polly voice to always be of specified type. If not set, a localized voice will be used.
     */
    public var globalVoiceId: AWSPollyVoiceId?
    
    /**
     `regionType` specifies what AWS region to use for Polly.
     */
    public var regionType: AWSRegionType = .USEast1
    
    /**
     `identityPoolId` is a required value for using AWS Polly voice instead of iOS's built in AVSpeechSynthesizer.
     You can get a token here: http://docs.aws.amazon.com/mobile/sdkforios/developerguide/cognito-auth-aws-identity-for-ios.html
     */
    public var identityPoolId: String
    
    /**
     Number of seconds a Polly request can wait before it is canceled and the default speech synthesizer speaks the instruction.
     */
    public var timeoutIntervalForRequest:TimeInterval = 2
    
    var pollyTask: URLSessionDataTask?
    var downloadFutureInstructionsTask: URLSessionDataTask?
    
    let sessionConfiguration = URLSessionConfiguration.default
    var urlSession: URLSession
    
    public init(identityPoolId: String) {
        self.identityPoolId = identityPoolId
        
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: regionType, identityPoolId: identityPoolId)
        let configuration = AWSServiceConfiguration(region: regionType, credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        sessionConfiguration.timeoutIntervalForRequest = timeoutIntervalForRequest;
        urlSession = URLSession(configuration: sessionConfiguration)
        
        super.init()
    }
    
    public override func didPassSpokenInstructionPoint(notification: NSNotification) {
        guard shouldSpeak(for: notification) == true else { return }
        
        let routeProgresss = notification.userInfo![MBRouteControllerDidPassSpokenInstructionPointRouteProgressKey] as! RouteProgress
        guard let instruction = routeProgresss.currentLegProgress.currentStepProgress.currentSpokenInstruction?.ssmlText else { return }
        
        pollyTask?.cancel()
        audioPlayer?.stop()
        startAnnouncementTimer()
        
        let urlForPollyRequst = pollyURL(for: instruction).description
        
        if let data = routeProgresss.spokenInstructionsForRoute[urlForPollyRequst] {
            sayInStruction(data: data)
        } else {
            speak(instruction, error: nil)
        
            if let upcomingStep = routeProgresss.currentLegProgress.upComingStep, let instructions = upcomingStep.instructionsSpokenAlongStep {
                for instruction in instructions {
                    let urlForPollyRequst = pollyURL(for: instruction.ssmlText)
                    
                    guard routeProgresss.spokenInstructionsForRoute[urlForPollyRequst.description] == nil else { continue }
                    
                    let builder = AWSPollySynthesizeSpeechURLBuilder.default().getPreSignedURL(urlForPollyRequst)
                    builder.continueWith { [weak self] (awsTask: AWSTask<NSURL>) -> Any? in
                        guard let strongSelf = self, let url = awsTask.result else {
                            return nil
                        }
                        
                        let group = DispatchGroup()
                        group.enter()
                        
                        DispatchQueue.global(qos: .background).async {
                            strongSelf.downloadFutureInstructionsTask = strongSelf.urlSession.dataTask(with: url as URL) { (data, response, error) in
                                guard error == nil else { return }
                                guard let data = data else { return }
                                routeProgresss.spokenInstructionsForRoute[urlForPollyRequst.description] = data
                                group.leave()
                            }
                        }
                        
                        group.wait()
                        
                        return nil
                    }
                }
            }
        }
    }
    
    func pollyURL(for instruction: String) ->  AWSPollySynthesizeSpeechURLBuilderRequest {
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
        
        if let voiceId = globalVoiceId {
            input.voiceId = voiceId
        }
        
        input.text = instruction
        
        return input
    }
    
    override func speak(_ text: String, error: String?) {
        assert(!text.isEmpty)
        
        let input = pollyURL(for: text)
        
        let builder = AWSPollySynthesizeSpeechURLBuilder.default().getPreSignedURL(input)
        builder.continueWith { [weak self] (awsTask: AWSTask<NSURL>) -> Any? in
            guard let strongSelf = self else {
                return nil
            }
            
            strongSelf.handle(awsTask)
            
            return nil
        }
    }
    
    func callSuperSpeak(_ text: String, error: String) {
        pollyTask?.cancel()
        
        guard let audioPlayer = audioPlayer else {
            super.speak(fallbackText, error: error)
            return
        }
        
        guard !audioPlayer.isPlaying else { return }
        
        super.speak(fallbackText, error: error)
    }
    
    func handle(_ awsTask: AWSTask<NSURL>) {
        guard awsTask.error == nil else {
            callSuperSpeak(fallbackText, error: awsTask.error!.localizedDescription)
            return
        }
        
        guard let url = awsTask.result else {
            callSuperSpeak(fallbackText, error: "No polly response")
            return
        }
        
        pollyTask = urlSession.dataTask(with: url as URL) { [weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            
            // If the task is canceled, don't speak.
            // But if it's some sort of other error, use fallback voice.
            if let error = error as NSError?, error.code == NSURLErrorCancelled {
                return
            } else if let error = error {
                // Cannot call super in a closure
                strongSelf.callSuperSpeak(strongSelf.fallbackText, error: error.localizedDescription)
                return
            }
            
            guard let data = data else {
                strongSelf.callSuperSpeak(strongSelf.fallbackText, error: "No data")
                return
            }
            
            strongSelf.sayInStruction(data: data)
        }
        
        pollyTask?.resume()
    }
    
    func sayInStruction(data: Data) {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            let prepared = audioPlayer?.prepareToPlay() ?? false
            
            guard prepared else {
                callSuperSpeak(fallbackText, error: "Audio player failed to prepare")
                return
            }
            
            DispatchQueue.main.async {
                self.audioPlayer?.delegate = self
                let played = self.audioPlayer?.play() ?? false
                
                guard played else {
                    self.callSuperSpeak(self.fallbackText, error: "Audio player failed to play")
                    return
                }
            }
        } catch  let error as NSError {
            callSuperSpeak(fallbackText, error: error.localizedDescription)
        }
    }
}
