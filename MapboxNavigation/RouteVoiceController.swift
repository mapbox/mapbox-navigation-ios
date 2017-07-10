import Foundation
import AVFoundation
import MapboxDirections
import MapboxCoreNavigation

/**
 The `RouteVoiceController` class provides voice guidance.
 */
@objc(MBRouteVoiceController)
open class RouteVoiceController: NSObject, AVSpeechSynthesizerDelegate {
    
    lazy var speechSynth = AVSpeechSynthesizer()
    var audioPlayer: AVAudioPlayer?
    let maneuverVoiceDistanceFormatter = DistanceFormatter(approximate: true, forVoiceUse: true)
    let routeStepFormatter = RouteStepFormatter()
    var recentlyAnnouncedRouteStep: RouteStep?
    var fallbackText: String!
    var announcementTimer: Timer!
    
    /**
     A boolean value indicating whether instructions should be announced by voice or not.
     */
    public var isEnabled: Bool = true
    
    
    /**
     Volume of announcements.
     */
    public var volume: Float = 1.0
    
    
    /**
     SSML option which controls at which speed Polly instructions are read.
     */
    public var instructionVoiceSpeedRate = 1.08
    
    
    /**
     SSML option that specifies the voice loudness.
     */
    public var instructionVoiceVolume = "x-loud"
    
    
    /**
     If true, a noise indicating the user is going to be rerouted will play prior to rerouting.
     */
    public var playRerouteSound = true

    
    /**
     Sound to play prior to reroute. Inherits volume level from `volume`.
     */
    public var rerouteSoundPlayer: AVAudioPlayer = try! AVAudioPlayer(data: NSDataAsset(name: "reroute-sound", bundle: Bundle.navigationUI)!.data, fileTypeHint: AVFileTypeMPEGLayer3)
    
    
    /**
     Buffer time between announcements. After an announcement is given any announcement given within this `TimeInterval` will be suppressed.
    */
    public var bufferBetweenAnnouncements: TimeInterval = 3
    
    override public init() {
        super.init()
        speechSynth.delegate = self
        maneuverVoiceDistanceFormatter.unitStyle = .long
        maneuverVoiceDistanceFormatter.numberFormatter.locale = .nationalizedCurrent
        resumeNotifications()
    }
    
    deinit {
        suspendNotifications()
        speechSynth.stopSpeaking(at: .word)
    }
    
    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(alertLevelDidChange(notification:)), name: RouteControllerAlertLevelDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willReroute(notification:)), name: RouteControllerWillReroute, object: nil)
    }
    
    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: RouteControllerAlertLevelDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: RouteControllerWillReroute, object: nil)
    }
    
    func willReroute(notification: NSNotification) {
        speechSynth.stopSpeaking(at: .word)
        
        guard playRerouteSound else {
            return
        }
        
        rerouteSoundPlayer.volume = volume
        rerouteSoundPlayer.play()
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
    
    func validateDuckingOptions() throws {
        let category = AVAudioSessionCategoryPlayback
        let categoryOptions: AVAudioSessionCategoryOptions = [.duckOthers, .interruptSpokenAudioAndMixWithOthers]
        try AVAudioSession.sharedInstance().setMode(AVAudioSessionModeSpokenAudio)
        try AVAudioSession.sharedInstance().setCategory(category, with: categoryOptions)
    }

    func duckAudio() throws {
        try validateDuckingOptions()
        try AVAudioSession.sharedInstance().setActive(true)
    }
    
    func unDuckAudio() throws {
        if !speechSynth.isSpeaking {
            try AVAudioSession.sharedInstance().setActive(false, with: [.notifyOthersOnDeactivation])
        }
    }
    
    func startAnnouncementTimer() {
        announcementTimer = Timer.scheduledTimer(timeInterval: bufferBetweenAnnouncements, target: self, selector: #selector(resetAnnouncementTimer), userInfo: nil, repeats: false)
    }
    
    func resetAnnouncementTimer() {
        recentlyAnnouncedRouteStep = nil
        announcementTimer.invalidate()
    }
    
    open func alertLevelDidChange(notification: NSNotification) {
        guard shouldSpeak(for: notification) == true else { return }
        
        speak(fallbackText, error: nil)
        startAnnouncementTimer()
    }
    
    func shouldSpeak(for notification: NSNotification) -> Bool {
        guard isEnabled, volume > 0 else { return false }
        
        guard let routeProgress = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationRouteProgressKey] as? RouteProgress else {
            assert(false)
            return false
        }
        
        // We're guarding against two things here:
        //   1. `recentlyAnnouncedRouteStep` being nil.
        //   2. `recentlyAnnouncedRouteStep` being equal to currentStep
        // If it has a value and they're equal, this means we gave an announcement with x seconds ago for this step
        guard recentlyAnnouncedRouteStep != routeProgress.currentLegProgress.currentStep else {
            return false
        }
        
        // Set recentlyAnnouncedRouteStep to the current step
        recentlyAnnouncedRouteStep = routeProgress.currentLegProgress.currentStep
        
        fallbackText = speechString(notification: notification, markUpWithSSML: false)
        
        // If the user is merging onto a highway, an announcement to merge is a bit excessive
        if let upComingStep = routeProgress.currentLegProgress.upComingStep, routeProgress.currentLegProgress.currentStep.maneuverType == .takeOnRamp && upComingStep.maneuverType == .merge && routeProgress.currentLegProgress.alertUserLevel == .high {
            return false
        }
        
        return true
    }
    
    func speechString(notification: NSNotification, markUpWithSSML: Bool) -> String {
        let routeProgress = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationRouteProgressKey] as! RouteProgress
        let userDistance = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationDistanceToEndOfManeuverKey] as! CLLocationDistance
        let alertLevel = routeProgress.currentLegProgress.alertUserLevel
        let profileIdentifier = routeProgress.route.routeOptions.profileIdentifier
        let minimumDistanceForHighAlert = RouteControllerMinimumDistanceForMediumAlert(identifier: profileIdentifier)
        
        let escapeIfNecessary = {(distance: String) -> String in
            return markUpWithSSML ? distance.addingXMLEscapes : distance
        }
        
        // If the current step arrives at a waypoint, the upcoming step is part of the next leg.
        let upcomingLegIndex = routeProgress.currentLegProgress.currentStep.maneuverType == .arrive ? routeProgress.legIndex + 1 :routeProgress.legIndex
        // Even if the next waypoint and the waypoint after that have the same coordinates, there will still be a step in between the two arrival steps. So the upcoming and follow-on steps are guaranteed to be part of the same leg.
        let followOnLegIndex = upcomingLegIndex
        
        // Handle arriving at the final destination
        //
        let numberOfLegs = routeProgress.route.legs.count
        guard let followOnInstruction = routeStepFormatter.string(for: routeProgress.currentLegProgress.followOnStep, legIndex: followOnLegIndex, numberOfLegs: numberOfLegs, markUpWithSSML: markUpWithSSML) else {
            let upComingStepInstruction = routeStepFormatter.string(for: routeProgress.currentLegProgress.upComingStep, legIndex: upcomingLegIndex, numberOfLegs: numberOfLegs, markUpWithSSML: markUpWithSSML)!
            var text: String
            if alertLevel == .arrive {
                text = upComingStepInstruction
            } else {
                text = String.localizedStringWithFormat(NSLocalizedString("WITH_DISTANCE_UTTERANCE_FORMAT", bundle: .navigationUI, value: "In %@, %@", comment: "Format for speech string; 1 = formatted distance; 2 = instruction"), escapeIfNecessary(maneuverVoiceDistanceFormatter.string(from: userDistance)), upComingStepInstruction)
            }
            
            return text
        }
        
        // If there is no `upComingStep`, there definitely should not be a followOnStep.
        // This should be caught above.
        let upComingInstruction = routeStepFormatter.string(for: routeProgress.currentLegProgress.upComingStep, legIndex: upcomingLegIndex, numberOfLegs: numberOfLegs, markUpWithSSML: markUpWithSSML)!
        let stepDistance = routeProgress.currentLegProgress.upComingStep!.distance
        let currentInstruction = routeStepFormatter.string(for: routeProgress.currentLegProgress.currentStep, legIndex: routeProgress.legIndex, numberOfLegs: numberOfLegs, markUpWithSSML: markUpWithSSML)
        let step = routeProgress.currentLegProgress.currentStep
        var text: String
        
        // We only want to announce this special depature announcement once.
        // Once it has been announced, all subsequnt announcements will not have an alert level of low
        // since the user will be approaching the maneuver location.
        if routeProgress.currentLegProgress.currentStep.maneuverType == .depart && alertLevel == .depart {
            if userDistance < minimumDistanceForHighAlert {
                text = String.localizedStringWithFormat(NSLocalizedString("LINKED_WITH_DISTANCE_UTTERANCE_FORMAT", bundle: .navigationUI, value: "%@, then in %@, %@", comment: "Format for speech string; 1 = current instruction; 2 = formatted distance to the following linked instruction; 3 = that linked instruction"), currentInstruction!, escapeIfNecessary(maneuverVoiceDistanceFormatter.string(from: userDistance)), upComingInstruction)
            } else {
                text = String.localizedStringWithFormat(NSLocalizedString("CONTINUE", bundle: .navigationUI, value: "Continue on %@ for %@", comment: "Format for speech string; 1 = way name; 2 = distance"), localizeRoadDescription(step, markUpWithSSML: markUpWithSSML), escapeIfNecessary(maneuverVoiceDistanceFormatter.string(from: userDistance)))
            }
        } else if routeProgress.currentLegProgress.currentStep.distance > 2_000 && routeProgress.currentLegProgress.alertUserLevel == .low {
            text = String.localizedStringWithFormat(NSLocalizedString("CONTINUE", bundle: .navigationUI, value: "Continue on %@ for %@", comment: "Format for speech string; 1 = way name; 2 = distance"), localizeRoadDescription(step, markUpWithSSML: markUpWithSSML), escapeIfNecessary(maneuverVoiceDistanceFormatter.string(from: userDistance)))
        } else if alertLevel == .high && stepDistance < minimumDistanceForHighAlert {
            text = String.localizedStringWithFormat(NSLocalizedString("LINKED_UTTERANCE_FORMAT", bundle: .navigationUI, value: "%@, then %@", comment: "Format for speech string; 1 = current instruction; 2 = the following linked instruction"), upComingInstruction, followOnInstruction)
        } else if alertLevel != .high {
            text = String.localizedStringWithFormat(NSLocalizedString("WITH_DISTANCE_UTTERANCE_FORMAT", bundle: .navigationUI, value: "In %@, %@", comment: "Format for speech string; 1 = formatted distance; 2 = instruction"), escapeIfNecessary(maneuverVoiceDistanceFormatter.string(from: userDistance)), upComingInstruction)
        } else {
            text = upComingInstruction
        }
        
        return text
    }
    
    func localizeRoadDescription(_ step: RouteStep, markUpWithSSML: Bool) -> String {
        var road = ""
        let escapeIfNecessary = {(distance: String) -> String in
            return markUpWithSSML ? distance.addingXMLEscapes : distance
        }
        if let name = step.names?.first {
            if let code = step.codes?.first {
                let markedUpName = markUpWithSSML ? "<say-as interpret-as=\"address\">\(name.addingXMLEscapes)</say-as>" : name
                let markedUpCode = markUpWithSSML ? "<say-as interpret-as=\"address\">\(code.addingXMLEscapes)</say-as>" : code
                road = String.localizedStringWithFormat(NSLocalizedString("NAME_AND_REF", bundle: .navigationUI, value: "%@ (%@)", comment: "Format for speech string; 1 = way name; 2 = way route number"), markedUpName, markedUpCode)
            } else {
                road = escapeIfNecessary(name)
            }
        } else if let code = step.codes?.first {
            road = escapeIfNecessary(code)
        }
        return road
    }
    
    func speak(_ text: String, error: String? = nil) {
        // Note why it failed
        if let error = error {
            print(error)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Only localized languages will have a proper fallback voice
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.preferredLocalLanguageCountryCode)
        utterance.volume = volume
        
        speechSynth.speak(utterance)
    }
}
