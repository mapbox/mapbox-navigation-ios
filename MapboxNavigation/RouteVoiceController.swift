import Foundation
import AVFoundation
import MapboxDirections
import MapboxCoreNavigation
import MapboxVoice

/**
 The `RouteVoiceController` class provides voice guidance.
 */
@objc(MBRouteVoiceController)
open class RouteVoiceController: NSObject, AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
    
    lazy var speechSynth = AVSpeechSynthesizer()
    var audioPlayer: AVAudioPlayer?
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
    
    public var voice: Voice
    
    /**
     Forces Polly voice to always be of specified type. If not set, a localized voice will be used.
     */
    public var globalVoiceId: VoiceId?
    
    /**
     Default initializer for `RouteVoiceController`.
     */
    override public init() {
        self.voice = Voice.shared
        super.init()
        
        if !Bundle.main.backgroundModes.contains("audio") {
            print("Voice guidance may not work properly. " +
                  "Add audio to the UIBackgroundModes key to your app’s Info.plist file")
        }
        
        speechSynth.delegate = self
        rerouteSoundPlayer.delegate = self
        resumeNotifications()
    }
    
    deinit {
        suspendNotifications()
        speechSynth.stopSpeaking(at: .word)
        resetAnnouncementTimer()
    }
    
    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(didPassSpokenInstructionPoint(notification:)), name: RouteControllerDidPassSpokenInstructionPoint, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(pauseSpeechAndPlayReroutingDing(notification:)), name: RouteControllerWillReroute, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReroute(notification:)), name: RouteControllerDidReroute, object: nil)
    }
    
    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: RouteControllerDidPassSpokenInstructionPoint, object: nil)
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
    
    open func didPassSpokenInstructionPoint(notification: NSNotification) {
        guard shouldSpeak(for: notification) == true else { return }
        
        let routeProgress = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationRouteProgressKey] as! RouteProgress
        let userDistance = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationDistanceToEndOfManeuverKey] as! CLLocationDistance
        let instruction = spokenInstructionFormatter.string(routeProgress: routeProgress, userDistance: userDistance, markUpWithSSML: true)
        fallbackText = spokenInstructionFormatter.string(routeProgress: routeProgress, userDistance: userDistance, markUpWithSSML: false)
        
        speak(instruction, error: nil)
        startAnnouncementTimer()
    }
    
    func shouldSpeak(for notification: NSNotification) -> Bool {
        guard isEnabled, volume > 0, !NavigationSettings.shared.muted else { return false }
        
        let routeProgress = notification.userInfo![RouteControllerDidPassSpokenInstructionPointRouteProgressKey] as! RouteProgress
        
        // We're guarding against two things here:
        //   1. `recentlyAnnouncedRouteStep` being nil.
        //   2. `recentlyAnnouncedRouteStep` being equal to currentStep
        // If it has a value and they're equal, this means we gave an announcement with x seconds ago for this step
        guard recentlyAnnouncedRouteStep != routeProgress.currentLegProgress.currentStep else {
            return false
        }
        
        // Set recentlyAnnouncedRouteStep to the current step
        recentlyAnnouncedRouteStep = routeProgress.currentLegProgress.currentStep
        
        fallbackText = routeProgress.currentLegProgress.currentStepProgress.currentSpokenInstruction?.text
        
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
        
        let voiceOptions = VoiceOptions(text: "<speak><prosody volume='\(instructionVoiceVolume)' rate='\(instructionVoiceSpeedRate)'>\(text)</prosody></speak>")
        voiceOptions.textType = .ssml
        
        let langs = Locale.preferredLocalLanguageCountryCode.components(separatedBy: "-")
        let langCode = langs[0]
        var countryCode = ""
        if langs.count > 1 {
            countryCode = langs[1]
        }
        
        switch (langCode, countryCode) {
        case ("de", _):
            voiceOptions.voiceId = .marlene
        case ("en", "CA"):
            voiceOptions.voiceId = .joanna
        case ("en", "GB"):
            voiceOptions.voiceId = .brian
        case ("en", "AU"):
            voiceOptions.voiceId = .nicole
        case ("en", "IN"):
            voiceOptions.voiceId = .raveena
        case ("en", _):
            voiceOptions.voiceId = .joanna
        case ("es", _):
            voiceOptions.voiceId = .miguel
        case ("fr", _):
            voiceOptions.voiceId = .celine
        case ("it", _):
            voiceOptions.voiceId = .giorgio
        case ("nl", _):
            voiceOptions.voiceId = .lotte
        case ("ru", _):
            voiceOptions.voiceId = .maxim
        case ("sv", _):
            voiceOptions.voiceId = .astrid
        default:
            speakFallback(error: "Voice \(langCode)-\(countryCode) not found")
            return
        }
        
        if let voiceId = globalVoiceId {
            voiceOptions.voiceId = voiceId
        }
        
        _ = voice.speak(voiceOptions) { [weak self] (data, error) in
            guard let strongSelf = self else { return }
            
            if let error = error {
                strongSelf.speakFallback(error: error.localizedDescription)
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
                    strongSelf.speakFallback(error: error.localizedDescription)
                }
            }
        }.resume()
    }
    
    func speakFallback(error: String? = nil) {
        // Note why it failed
        if let error = error {
            print(error)
        }
        
        do {
            try duckAudio()
        } catch {
            print(error)
        }
        
        let utterance = AVSpeechUtterance(string: fallbackText)
        
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
