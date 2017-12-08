import Foundation
import AVFoundation
import MapboxDirections
import MapboxCoreNavigation
import MapboxVoice

extension NSAttributedString {
    @available(iOS 10.0, *)
    public func pronounced(_ pronunciation: String) -> NSAttributedString {
        let phoneticWords = pronunciation.components(separatedBy: " ")
        let phoneticString = NSMutableAttributedString()
        for (word, phoneticWord) in zip(string.components(separatedBy: " "), phoneticWords) {
            // AVSpeechSynthesizer doesn’t recognize some common IPA symbols.
            let phoneticWord = phoneticWord.byReplacing([("ɡ", "g"), ("ɹ", "r")])
            if phoneticString.length > 0 {
                phoneticString.append(NSAttributedString(string: " "))
            }
            phoneticString.append(NSAttributedString(string: word, attributes: [
                NSAttributedStringKey(rawValue: AVSpeechSynthesisIPANotationAttribute): phoneticWord,
            ]))
        }
        return phoneticString
    }
}

extension SpokenInstruction {
    @available(iOS 10.0, *)
    func attributedText(for legProgress: RouteLegProgress) -> NSAttributedString {
        let attributedText = NSMutableAttributedString(string: text)
        if let step = legProgress.upComingStep,
            let name = step.names?.first,
            let phoneticName = step.phoneticNames?.first {
            let nameRange = attributedText.mutableString.range(of: name)
            if (nameRange.location != NSNotFound) {
                attributedText.replaceCharacters(in: nameRange, with: NSAttributedString(string: name).pronounced(phoneticName))
            }
        }
        if let step = legProgress.followOnStep,
            let name = step.names?.first,
            let phoneticName = step.phoneticNames?.first {
            let nameRange = attributedText.mutableString.range(of: name)
            if (nameRange.location != NSNotFound) {
                attributedText.replaceCharacters(in: nameRange, with: NSAttributedString(string: name).pronounced(phoneticName))
            }
        }
        return attributedText
    }
}

/**
 The `RouteVoiceController` class provides voice guidance.
 */
@objc(MBRouteVoiceController)
open class RouteVoiceController: NSObject, AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
    
    lazy var speechSynth = AVSpeechSynthesizer()
    var audioPlayer: AVAudioPlayer?
    
    /**
     A boolean value indicating whether instructions should be announced by voice or not.
     */
    @objc public var isEnabled: Bool = true
    
    
    /**
     Volume of announcements.
     */
    @objc public var volume: Float = 1.0
    
    
    /**
     SSML option which controls at which speed Polly instructions are read.
     */
    @objc public var instructionVoiceSpeedRate = 1.08
    
    
    /**
     SSML option that specifies the voice loudness.
     */
    @objc public var instructionVoiceVolume = "default"
    
    
    /**
     If true, a noise indicating the user is going to be rerouted will play prior to rerouting.
     */
    @objc public var playRerouteSound = true

    
    /**
     Sound to play prior to reroute. Inherits volume level from `volume`.
     */
    @objc public var rerouteSoundPlayer: AVAudioPlayer = try! AVAudioPlayer(data: NSDataAsset(name: "reroute-sound", bundle: .mapboxNavigation)!.data, fileTypeHint: AVFileType.mp3.rawValue)
    
    
    /**
     Buffer time between announcements. After an announcement is given any announcement given within this `TimeInterval` will be suppressed.
    */
    @objc public var bufferBetweenAnnouncements: TimeInterval = 3
    
    /**
     Delegate used for getting metadata information about a particular spoken instruction.
     */
    public weak var voiceControllerDelegate: VoiceControllerDelegate?
    
    var lastSpokenInstruction: SpokenInstruction?
    var legProgress: RouteLegProgress?
    
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
            assert(false, "This application’s Info.plist file must include “audio” in UIBackgroundModes. This background mode is used for spoken instructions while the application is in the background.")
        }
        
        speechSynth.delegate = self
        rerouteSoundPlayer.delegate = self
        resumeNotifications()
    }
    
    deinit {
        suspendNotifications()
        speechSynth.stopSpeaking(at: .word)
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
    
    @objc func didReroute(notification: NSNotification) {
        // Play reroute sound when a faster route is found
        if notification.userInfo?[RouteControllerDidFindFasterRouteKey] as! Bool {
            pauseSpeechAndPlayReroutingDing(notification: notification)
        }
    }
    
    @objc func pauseSpeechAndPlayReroutingDing(notification: NSNotification) {
        speechSynth.stopSpeaking(at: .word)
        
        guard playRerouteSound && !NavigationSettings.shared.muted else {
            return
        }
        
        rerouteSoundPlayer.volume = volume
        rerouteSoundPlayer.play()
    }
    
    @objc public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        do {
            try unDuckAudio()
        } catch {
            voiceControllerDelegate?.voiceController?(self, spokenInstructionsDidFailWith: error)
        }
    }
    
    @objc public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        do {
            try unDuckAudio()
        } catch {
            voiceControllerDelegate?.voiceController?(self, spokenInstructionsDidFailWith: error)
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
        try AVAudioSession.sharedInstance().setActive(false, with: [.notifyOthersOnDeactivation])
    }
    
<<<<<<< HEAD
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
=======
    @objc open func didPassSpokenInstructionPoint(notification: NSNotification) {
        guard isEnabled, volume > 0, !NavigationSettings.shared.muted else { return }
>>>>>>> master
        
        let routeProgress = notification.userInfo![RouteControllerDidPassSpokenInstructionPointRouteProgressKey] as! RouteProgress
        legProgress = routeProgress.currentLegProgress
        guard let instruction = routeProgress.currentLegProgress.currentStepProgress.currentSpokenInstruction else { return }
        lastSpokenInstruction = instruction
        speak(instruction)
    }
    
    /**
     Reads aloud the given instruction.
     
     - parameter instruction: The instruction to read aloud.
     */
    open func speak(_ instruction: SpokenInstruction) {
        if speechSynth.isSpeaking, let lastSpokenInstruction = lastSpokenInstruction {
            voiceControllerDelegate?.voiceController?(self, didInterrupt: lastSpokenInstruction, with: instruction)
        }
        
        do {
            try duckAudio()
        } catch {
            voiceControllerDelegate?.voiceController?(self, spokenInstructionsDidFailWith: error)
        }
        
<<<<<<< HEAD
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
=======
        var utterance: AVSpeechUtterance?
>>>>>>> master
        if Locale.preferredLocalLanguageCountryCode == "en-US" {
            // Alex can’t handle attributed text.
            utterance = AVSpeechUtterance(string: instruction.text)
            utterance!.voice = AVSpeechSynthesisVoice(identifier: AVSpeechSynthesisVoiceIdentifierAlex)
        }
        
        if #available(iOS 10.0, *), utterance?.voice == nil, let legProgress = legProgress {
            utterance = AVSpeechUtterance(attributedString: instruction.attributedText(for: legProgress))
        } else {
            utterance = AVSpeechUtterance(string: instruction.text)
        }
        
        // Only localized languages will have a proper fallback voice
        if utterance?.voice == nil {
            utterance?.voice = AVSpeechSynthesisVoice(language: Locale.preferredLocalLanguageCountryCode)
        }
        utterance?.volume = volume
        
        if let utterance = utterance {
            speechSynth.speak(utterance)
        }
    }
}

/**
 The `VoiceControllerDelegate` protocol defines methods that allow an object to respond to significant events related to spoken instructions.
 */
@objc(MBVoiceControllerDelegate)
public protocol VoiceControllerDelegate {
    
    /**
     Called when the voice controller failed to speak an instruction.
     
     - parameter voiceController: The voice controller that experienced the failure.
     - parameter error: An error explaining the failure and its cause. The `MBSpokenInstructionErrorCodeKey` key of the error’s user info dictionary is a `SpokenInstructionErrorCode` indicating the cause of the failure.
     */
    @objc(voiceController:spokenInstrucionsDidFailWithError:)
    optional func voiceController(_ voiceController: RouteVoiceController, spokenInstructionsDidFailWith error: Error)
    
    /**
     Called when one spoken instruction interrupts another instruction currently being spoken.
     
     - parameter voiceController: The voice controller that experienced the interruption.
     - parameter interruptedInstruction: The spoken instruction currently in progress that has been interrupted.
     - parameter interruptingInstruction: The spoken instruction that is interrupting the current instruction.
     */
    @objc(voiceController:didInterruptSpokenInstruction:withInstruction:)
    optional func voiceController(_ voiceController: RouteVoiceController, didInterrupt interruptedInstruction: SpokenInstruction, with interruptingInstruction: SpokenInstruction)
}
