import Foundation
import AVFoundation
import MapboxDirections
import MapboxCoreNavigation

/**
 The `RouteVoiceController` class provides voice guidance.
 */
@objc(MBRouteVoiceController)
open class RouteVoiceController: NSObject, AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
    
    lazy var speechSynth = AVSpeechSynthesizer()
    var audioPlayer: AVAudioPlayer?
    let maneuverVoiceDistanceFormatter = SpokenDistanceFormatter(approximate: true)
    let spokenInstructionFormatter = SpokenInstructionFormatter()
    let routeStepFormatter = RouteStepFormatter()
    var recentlyAnnouncedRouteStep: RouteStep?
    var fallbackText: String!
    var announcementTimer: Timer?
    
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
    public var instructionVoiceVolume = "default"
    
    
    /**
     If true, a noise indicating the user is going to be rerouted will play prior to rerouting.
     */
    public var playRerouteSound = true

    
    /**
     Sound to play prior to reroute. Inherits volume level from `volume`.
     */
    public var rerouteSoundPlayer: AVAudioPlayer = try! AVAudioPlayer(data: NSDataAsset(name: "reroute-sound", bundle: .mapboxNavigation)!.data, fileTypeHint: AVFileTypeMPEGLayer3)
    
    
    /**
     Buffer time between announcements. After an announcement is given any announcement given within this `TimeInterval` will be suppressed.
    */
    public var bufferBetweenAnnouncements: TimeInterval = 3
    
    /**
     Default initializer for `RouteVoiceController`.
     */
    override public init() {
        super.init()
        
        if !Bundle.main.backgroundModes.contains("audio") {
            print("Voice guidance may not work properly. " +
                  "Add audio to the UIBackgroundModes key to your app’s Info.plist file")
        }
        
        speechSynth.delegate = self
        rerouteSoundPlayer.delegate = self
        maneuverVoiceDistanceFormatter.unitStyle = .long
        maneuverVoiceDistanceFormatter.numberFormatter.locale = .nationalizedCurrent
        resumeNotifications()
    }
    
    deinit {
        suspendNotifications()
        speechSynth.stopSpeaking(at: .word)
        resetAnnouncementTimer()
    }
    
    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(alertLevelDidChange(notification:)), name: RouteControllerAlertLevelDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(pauseSpeechAndPlayReroutingDing(notification:)), name: RouteControllerWillReroute, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReroute(notification:)), name: RouteControllerDidReroute, object: nil)
    }
    
    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: RouteControllerAlertLevelDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: RouteControllerWillReroute, object: nil)
        NotificationCenter.default.removeObserver(self, name: RouteControllerDidReroute, object: nil)
    }
    
    func didReroute(notification: NSNotification) {
        
        // Play reroute sound when a faster route is found
        if notification.userInfo?[RouteControllerDidFindFasterRouteKey] as! Bool {
            pauseSpeechAndPlayReroutingDing(notification: notification)
        }
    }
    
    func pauseSpeechAndPlayReroutingDing(notification: NSNotification) {
        speechSynth.stopSpeaking(at: .word)
        
        guard playRerouteSound && !NavigationSettings.shared.muted else {
            return
        }
        
        rerouteSoundPlayer.volume = volume
        rerouteSoundPlayer.play()
    }
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
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
        announcementTimer?.invalidate()
        announcementTimer = Timer.scheduledTimer(timeInterval: bufferBetweenAnnouncements, target: self, selector: #selector(resetAnnouncementTimer), userInfo: nil, repeats: false)
    }
    
    func resetAnnouncementTimer() {
        announcementTimer?.invalidate()
        recentlyAnnouncedRouteStep = nil
    }
    
    open func alertLevelDidChange(notification: NSNotification) {
        guard shouldSpeak(for: notification) == true else { return }
        
        speak(fallbackText, error: nil)
        startAnnouncementTimer()
    }
    
    func shouldSpeak(for notification: NSNotification) -> Bool {
        guard isEnabled, volume > 0, !NavigationSettings.shared.muted else { return false }
        
        let routeProgress = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationRouteProgressKey] as! RouteProgress
        let userDistance = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationDistanceToEndOfManeuverKey] as! CLLocationDistance
        
        // We're guarding against two things here:
        //   1. `recentlyAnnouncedRouteStep` being nil.
        //   2. `recentlyAnnouncedRouteStep` being equal to currentStep
        // If it has a value and they're equal, this means we gave an announcement with x seconds ago for this step
        guard recentlyAnnouncedRouteStep != routeProgress.currentLegProgress.currentStep else {
            return false
        }
        
        // Set recentlyAnnouncedRouteStep to the current step
        recentlyAnnouncedRouteStep = routeProgress.currentLegProgress.currentStep
        
        fallbackText = spokenInstructionFormatter.string(routeProgress: routeProgress, userDistance: userDistance, markUpWithSSML: false)
        
        // If the user is merging onto a highway, an announcement to merge is a bit excessive
        if let upComingStep = routeProgress.currentLegProgress.upComingStep, routeProgress.currentLegProgress.currentStep.maneuverType == .takeOnRamp && upComingStep.maneuverType == .merge && routeProgress.currentLegProgress.alertUserLevel == .high {
            return false
        }
        
        return true
    }
    
    func speak(_ text: String, error: String? = nil) {
        // Note why it failed
        if let error = error {
            print(error)
        }
        
        do {
            try duckAudio()
        } catch {
            print(error)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Only localized languages will have a proper fallback voice
        if Locale.preferredLocalLanguageCountryCode == "en-US" {
            utterance.voice = AVSpeechSynthesisVoice(identifier: AVSpeechSynthesisVoiceIdentifierAlex)
        }
        if utterance.voice == nil {
            utterance.voice = AVSpeechSynthesisVoice(language: Locale.preferredLocalLanguageCountryCode)
        }
        utterance.volume = volume
        
        speechSynth.speak(utterance)
    }
}
