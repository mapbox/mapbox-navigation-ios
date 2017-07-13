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
    
    public init(identityPoolId: String) {
        self.identityPoolId = identityPoolId
        
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: regionType, identityPoolId: identityPoolId)
        let configuration = AWSServiceConfiguration(region: regionType, credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        super.init()
    }
    
    public override func alertLevelDidChange(notification: NSNotification) {
        guard shouldSpeak(for: notification) == true else { return }
        
        let routeProgress = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationRouteProgressKey] as! RouteProgress
        let userDistance = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationDistanceToEndOfManeuverKey] as! CLLocationDistance
        
        speak(speechString(describing: routeProgress, at: userDistance, markUpWithSSML: true), error: nil)
        startAnnouncementTimer()
    }
    
    override public func speak(_ instruction: String, error: String?) {
        assert(!instruction.isEmpty)
        
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
        
        input.text = "<speak><prosody volume='\(instructionVoiceVolume)' rate='\(instructionVoiceSpeedRate)'>\(instruction)</prosody></speak>"
        
        let builder = AWSPollySynthesizeSpeechURLBuilder.default().getPreSignedURL(input)
        builder.continueWith { [weak self] (awsTask: AWSTask<NSURL>) -> Any? in
            guard let strongSelf = self else {
                return nil
            }
            
            strongSelf.handle(awsTask)
            
            return nil
        }
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
        
        do {
            let soundData = try Data(contentsOf: url as URL)
            audioPlayer = try AVAudioPlayer(data: soundData)
            audioPlayer?.delegate = self
            
            if let audioPlayer = audioPlayer {
                try duckAudio()
                audioPlayer.volume = volume
                audioPlayer.play()
            }
        } catch {
            super.speak(fallbackText, error: error.localizedDescription)
        }
    }
}

extension PollyVoiceController: AVAudioPlayerDelegate {
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard audioPlayer?.isPlaying == false else { return }
        do {
            try unDuckAudio()
        } catch {
            print(error.localizedDescription)
        }
    }
}
