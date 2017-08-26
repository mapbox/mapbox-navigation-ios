import Foundation
import AWSPolly
import AVFoundation
import MapboxCoreNavigation

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
    
    var pollyTask: URLSessionDataTask?
    
    public init(identityPoolId: String) {
        self.identityPoolId = identityPoolId
        
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: regionType, identityPoolId: identityPoolId)
        let configuration = AWSServiceConfiguration(region: regionType, credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        super.init()
    }
    
    public override func alertLevelDidChange(notification: NSNotification) {
        guard shouldSpeak(for: notification) == true else { return }
        
        let routeProgresss = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationRouteProgressKey] as! RouteProgress
        let userDistances = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationDistanceToEndOfManeuverKey] as! CLLocationDistance
        let instruction = spokenInstructionFormatter.string(routeProgress: routeProgresss, userDistance: userDistances, markUpWithSSML: true)
        
        speak(instruction, error: nil)
        startAnnouncementTimer()
    }
    
    override func speak(_ text: String, error: String?) {
        assert(!text.isEmpty)
        
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
        case ("es", _):
            input.voiceId = .miguel
        case ("fr", _):
            input.voiceId = .celine
        case ("it", _):
            input.voiceId = .giorgio
        case ("nl", _):
            input.voiceId = .lotte
        case ("ru", _):
            input.voiceId = .maxim
        case ("sv", _):
            input.voiceId = .astrid
        default:
            super.speak(fallbackText, error: "Voice \(langCode)-\(countryCode) not found")
            return
        }
        
        if let voiceId = globalVoiceId {
            input.voiceId = voiceId
        }
        
        input.text = "<speak><prosody volume='\(instructionVoiceVolume)' rate='\(instructionVoiceSpeedRate)'>\(text)</prosody></speak>"
        
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
        super.speak(fallbackText, error: error)
    }
    
    func handle(_ awsTask: AWSTask<NSURL>) {
        guard awsTask.error == nil else {
            super.speak(fallbackText, error: awsTask.error!.localizedDescription)
            return
        }
        
        guard let url = awsTask.result else {
            super.speak(fallbackText, error: "No polly response")
            return
        }
        
        pollyTask = URLSession.shared.dataTask(with: url as URL) { [weak self] (data, response, error) in
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
            
            guard let data = data else { return }
            
            DispatchQueue.main.async {
                do {
                    strongSelf.audioPlayer = try AVAudioPlayer(data: data)
                    strongSelf.audioPlayer?.delegate = self
                    
                    if let audioPlayer = strongSelf.audioPlayer {
                        try strongSelf.duckAudio()
                        audioPlayer.volume = strongSelf.volume
                        audioPlayer.play()
                    }
                } catch  let error as NSError {
                    strongSelf.callSuperSpeak(strongSelf.fallbackText, error: error.localizedDescription)
                }
            }

        }
        
        pollyTask?.resume()
    }
}
