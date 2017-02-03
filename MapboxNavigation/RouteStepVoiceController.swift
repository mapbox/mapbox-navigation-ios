import Foundation
import AVFoundation
import MapboxDirections
import AWSPolly

public class RouteVoiceController: NSObject, AVSpeechSynthesizerDelegate {
    
    lazy var speechSynth = AVSpeechSynthesizer()
    let maneuverVoiceDistanceFormatter = DistanceFormatter(approximate: true, forVoiceUse: true)
    let routeStepFormatter = RouteStepFormatter()
    var recentlyAnnouncedRouteStep: RouteStep?
    var announcementTimer: Timer!
    var fallbackText: String!
    let audioPlayer = AVPlayer()
    
    let AwsRegion = AWSRegionType.USEast1
    
    public override init() {
        super.init()
        maneuverVoiceDistanceFormatter.unitStyle = .long
        resumeNotifications()
        
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast1, identityPoolId: "")
        let configuration = AWSServiceConfiguration(region:.USEast1, credentialsProvider:credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        audioPlayer.volume = 3
    }
    
    deinit {
        if let currentItem = audioPlayer.currentItem {
            currentItem.removeObserver(self, forKeyPath: "status")
        }
        suspendNotifications()
        speechSynth.stopSpeaking(at: .word)
    }
    
    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.alertLevelDidChange(notification:)), name: RouteControllerAlertLevelDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reRoute(notification:)), name: RouteControllerShouldReroute, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(self.audioPlayerDidFinishPlaying(notification:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: audioPlayer.currentItem)
    }
    
    public func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: RouteControllerAlertLevelDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: RouteControllerShouldReroute, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    func reRoute(notification: NSNotification) {
        speechSynth.stopSpeaking(at: .word)
    }
    
    func startAnnouncementTimer() {
        announcementTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(resetAnnouncementTimer), userInfo: nil, repeats: false)
    }
    
    func resetAnnouncementTimer() {
        recentlyAnnouncedRouteStep = nil
        announcementTimer.invalidate()
    }
    
    func audioPlayerDidFinishPlaying(notification: NSNotification) {
        do {
            try unDuckAudio()
        } catch {
            print(error)
        }
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        do {
            try unDuckAudio()
        } catch {
            print(error)
        }
    }
    
    func validateNavigationVoiceOptions() throws {
        let category = AVAudioSessionCategoryPlayback
        if #available(iOS 9.0, *) {
            let categoryOptions: AVAudioSessionCategoryOptions = [.duckOthers, .interruptSpokenAudioAndMixWithOthers]
            try AVAudioSession.sharedInstance().setMode(AVAudioSessionModeSpokenAudio)
            try AVAudioSession.sharedInstance().setCategory(category, with: categoryOptions)
        }
    }
    
    func duckAudio() throws {
        try validateNavigationVoiceOptions()
        try AVAudioSession.sharedInstance().setActive(true)
    }
    
    func unDuckAudio() throws {
        if !speechSynth.isSpeaking {
            try AVAudioSession.sharedInstance().setActive(false, with: [.notifyOthersOnDeactivation])
        }
    }
    
    
    func alertLevelDidChange(notification: NSNotification) {
        guard let routeProgress = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationRouteProgressKey] as? RouteProgress else {
            assert(false)
            return
        }
        
        // We're guarding against two things here:
        //   1. `recentlyAnnouncedRouteStep` being nil.
        //   2. `recentlyAnnouncedRouteStep` being equal to currentStep
        // If it has a value and they're equal, this means we gave an announcement with x seconds ago for this step
        guard recentlyAnnouncedRouteStep != routeProgress.currentLegProgress.currentStep else {
            return
        }
        
        let text = speechString(notification: notification, markUpWithSSML: true)
        speak(text, notification: notification)
        
        // Set recentlyAnnouncedRouteStep to the current step and start the buffer timer
        recentlyAnnouncedRouteStep = routeProgress.currentLegProgress.currentStep
        startAnnouncementTimer()
    }
    
    func speechString(notification: NSNotification, markUpWithSSML: Bool) -> String {
        let routeProgress = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationRouteProgressKey] as! RouteProgress
        let userDistance = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationDistanceToEndOfManeuverKey] as! CLLocationDistance
        let alertLevel = routeProgress.currentLegProgress.alertUserLevel
        
        let escapeIfNecessary = {(distance: String) -> String in
            return markUpWithSSML ? distance.addingXMLEscapes : distance
        }
        
        // Handle arriving at the final destination
        guard let followOnInstruction = routeStepFormatter.string(for: routeProgress.currentLegProgress.followOnStep, markUpWithSSML: markUpWithSSML) else {
            let upComingStepInstruction = routeStepFormatter.string(for: routeProgress.currentLegProgress.upComingStep, markUpWithSSML: markUpWithSSML)!
            var text: String
            if alertLevel == .arrive {
                text = upComingStepInstruction
            } else {
                text = String.localizedStringWithFormat(NSLocalizedString("WITH_DISTANCE_UTTERANCE_FORMAT", value: "In %@, %@", comment: "Format for speech string; 1 = formatted distance; 2 = instruction"), escapeIfNecessary(maneuverVoiceDistanceFormatter.string(from: userDistance)), upComingStepInstruction)
            }
            
            return text
        }
        
        // If there is no `upComingStep`, there definitely should not be a followOnStep.
        // This should be caught above.
        let upComingInstruction = routeStepFormatter.string(for: routeProgress.currentLegProgress.upComingStep, markUpWithSSML: markUpWithSSML)!
        let stepDistance = routeProgress.currentLegProgress.upComingStep!.distance
        let currentInstruction = routeStepFormatter.string(for: routeProgress.currentLegProgress.currentStep, markUpWithSSML: markUpWithSSML)
        let step = routeProgress.currentLegProgress.currentStep
        var text: String
        
        // We only want to announce this special depature announcement once.
        // Once it has been announced, all subsequnt announcements will not have an alert level of low
        // since the user will be approaching the maneuver location.
        if routeProgress.currentLegProgress.currentStep.maneuverType == .depart && alertLevel == .depart {
            if userDistance < RouteControllerMinimumDistanceForHighAlert {
                text = String.localizedStringWithFormat(NSLocalizedString("LINKED_WITH_DISTANCE_UTTERANCE_FORMAT", value: "%@, then in %@, %@", comment: "Format for speech string; 1 = current instruction; 2 = formatted distance to the following linked instruction; 3 = that linked instruction"), currentInstruction!, escapeIfNecessary(maneuverVoiceDistanceFormatter.string(from: userDistance)), upComingInstruction)
            } else {
                text = String.localizedStringWithFormat(NSLocalizedString("CONTINUE", value: "Continue on %@ for %@", comment: "Format for speech string; 1 = way name; 2 = distance"), escapeIfNecessary(localizeRoadDescription(step)), escapeIfNecessary(maneuverVoiceDistanceFormatter.string(from: userDistance)))
            }
        } else if routeProgress.currentLegProgress.currentStep.distance > 2_000 {
            text = String.localizedStringWithFormat(NSLocalizedString("CONTINUE", value: "Continue on %@ for %@", comment: "Format for speech string; 1 = way name; 2 = distance"), escapeIfNecessary(localizeRoadDescription(step)), escapeIfNecessary(maneuverVoiceDistanceFormatter.string(from: userDistance)))
        } else if alertLevel == .high && stepDistance < RouteControllerMinimumDistanceForHighAlert {
            text = String.localizedStringWithFormat(NSLocalizedString("LINKED_UTTERANCE_FORMAT", value: "%@, then %@", comment: "Format for speech string; 1 = current instruction; 2 = the following linked instruction"), upComingInstruction, followOnInstruction)
        } else if alertLevel != .high {
            text = String.localizedStringWithFormat(NSLocalizedString("WITH_DISTANCE_UTTERANCE_FORMAT", value: "In %@, %@", comment: "Format for speech string; 1 = formatted distance; 2 = instruction"), escapeIfNecessary(maneuverVoiceDistanceFormatter.string(from: userDistance)), upComingInstruction)
        } else {
            text = upComingInstruction
        }
        
        return text
    }
    
    func localizeRoadDescription(_ step: RouteStep) -> String {
        var road = ""
        if let name = step.names?.first {
            if let code = step.codes?.first {
                road = String.localizedStringWithFormat(NSLocalizedString("NAME_AND_REF", value: "%@ (%@)", comment: "Format for speech string; 1 = way name; 2 = way route number"), name, code)
            } else {
                road = name
            }
        } else if let code = step.codes?.first {
            road = code
        }
        return road
    }
    
    func speak(_ text: String, notification: NSNotification) {
        assert(!text.isEmpty)
        
        speechSynth.delegate = self
        let input = AWSPollySynthesizeSpeechURLBuilderRequest()
        input.textType = .ssml
        input.outputFormat = .mp3
        
        let langs = Locale.preferredLanguages.first!.components(separatedBy: "-")
        let langCode = langs[0]
        var countryCode = ""
        if langs.count > 1 {
            countryCode = langs[1]
        }
        
        fallbackText = speechString(notification: notification, markUpWithSSML: false)
        
        switch (langCode, countryCode) {
        case ("de", _):
            input.voiceId = .marlene
        case ("en", "GB"), ("en", "CA"):
            input.voiceId = .joanna
        case ("en", "AU"):
            input.voiceId = .nicole
        case ("en", "IN"):
            input.voiceId = .raveena
        case ("en", _):
            input.voiceId = .joanna
        case ("fr", _):
            input.voiceId = .celine
        case ("nl", _):
            input.voiceId = .lotte
        default:
            speakFallBack(fallbackText, error: "Voice \(langCode)-\(countryCode) not found")
            return
        }
        
        input.text = "<speak><prosody volume='x-loud' rate='1.08'>\(text)</prosody></speak>"
        
        let builder = AWSPollySynthesizeSpeechURLBuilder.default().getPreSignedURL(input)
        
        builder.continueWith { [weak self] (awsTask: AWSTask<NSURL>) -> Any? in
            guard let strongSelf = self else {
                return nil
            }
            
            guard awsTask.error == nil else {
                strongSelf.speakFallBack(strongSelf.fallbackText, error: awsTask.error!.localizedDescription)
                return nil
            }
            
            guard let url = awsTask.result else {
                strongSelf.speakFallBack(strongSelf.fallbackText, error: "No polly response")
                return nil
            }
            
            if let currentItem = strongSelf.audioPlayer.currentItem {
                currentItem.removeObserver(strongSelf, forKeyPath: "status")
            }
            let playerItem = AVPlayerItem(url: url as URL)
            strongSelf.audioPlayer.replaceCurrentItem(with: playerItem)
            
            strongSelf.audioPlayer.currentItem?.addObserver(strongSelf, forKeyPath: "status", options: NSKeyValueObservingOptions(), context: nil)
            
            return nil
        }
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            do {
                try duckAudio()
            } catch {
                print(error)
            }
            if let error = audioPlayer.currentItem?.error {
                self.speakFallBack(fallbackText, error: error.localizedDescription)
            } else {
                audioPlayer.play()
            }
        }
    }
    
    
    func speakFallBack(_ text: String, error: String) {
        let utterance = AVSpeechUtterance(string: text)
        
        // change the rate of speech for iOS 8
        if !ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 9, minorVersion: 0, patchVersion: 0)) {
            utterance.rate = AVSpeechUtteranceMinimumSpeechRate + AVSpeechUtteranceDefaultSpeechRate / 5.0
        }
        
        // Only localized languages will have a proper fallback voice
        utterance.voice = AVSpeechSynthesisVoice(language: Bundle.main.preferredLocalizations.first)
        
        speechSynth.speak(utterance)
    }
}
