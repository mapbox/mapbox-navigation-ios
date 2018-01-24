import Foundation
import AVFoundation
import MapboxDirections
import MapboxCoreNavigation

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
                NSAttributedStringKey(rawValue: AVSpeechSynthesisIPANotationAttribute): phoneticWord
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
    var routeProgress: RouteProgress?
    
    var volumeToken: NSKeyValueObservation?
    var muteToken: NSKeyValueObservation?
    
    /**
     Default initializer for `RouteVoiceController`.
     */
    override public init() {
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
        speechSynth.stopSpeaking(at: .immediate)
    }
    
    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(didPassSpokenInstructionPoint(notification:)), name: .routeControllerDidPassSpokenInstructionPoint, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(pauseSpeechAndPlayReroutingDing(notification:)), name: .routeControllerWillReroute, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReroute(notification:)), name: .routeControllerDidReroute, object: nil)
        
        volumeToken = NavigationSettings.shared.observe(\.voiceVolume) { [weak self] (settings, change) in
            self?.audioPlayer?.volume = settings.voiceVolume
        }
        
        muteToken = NavigationSettings.shared.observe(\.voiceMuted) { [weak self] (settings, change) in
            if settings.voiceMuted {
                self?.audioPlayer?.stop()
                self?.speechSynth.stopSpeaking(at: .immediate)
            }
        }
    }
    
    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: .routeControllerDidPassSpokenInstructionPoint, object: nil)
        NotificationCenter.default.removeObserver(self, name: .routeControllerWillReroute, object: nil)
        NotificationCenter.default.removeObserver(self, name: .routeControllerDidReroute, object: nil)
    }
    
    @objc func didReroute(notification: NSNotification) {
        // Play reroute sound when a faster route is found
        if notification.userInfo?[RouteControllerDidFindFasterRouteKey] as! Bool {
            pauseSpeechAndPlayReroutingDing(notification: notification)
        }
    }
    
    @objc func pauseSpeechAndPlayReroutingDing(notification: NSNotification) {
        speechSynth.stopSpeaking(at: .word)
        
        guard playRerouteSound && !NavigationSettings.shared.voiceMuted else {
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
    
    @objc open func didPassSpokenInstructionPoint(notification: NSNotification) {
        guard !NavigationSettings.shared.voiceMuted else { return }
        
        routeProgress = notification.userInfo![RouteControllerDidPassSpokenInstructionPointRouteProgressKey] as? RouteProgress
        assert(routeProgress != nil, "routeProgress should not be nil.")
        
        guard let instruction = routeProgress!.currentLegProgress.currentStepProgress.currentSpokenInstruction else { return }
        lastSpokenInstruction = instruction
        speak(instruction)
    }
    
    /**
     Reads aloud the given instruction.
     
     - parameter instruction: The instruction to read aloud.
     */
    open func speak(_ instruction: SpokenInstruction) {
        assert(routeProgress != nil, "routeProgress should not be nil.")
        
        if speechSynth.isSpeaking, let lastSpokenInstruction = lastSpokenInstruction {
            voiceControllerDelegate?.voiceController?(self, didInterrupt: lastSpokenInstruction, with: instruction)
        }
        
        do {
            try duckAudio()
        } catch {
            voiceControllerDelegate?.voiceController?(self, spokenInstructionsDidFailWith: error)
        }
        
        var utterance: AVSpeechUtterance?
        if Locale.preferredLocalLanguageCountryCode == "en-US" {
            // Alex can’t handle attributed text.
            utterance = AVSpeechUtterance(string: instruction.text)
            utterance!.voice = AVSpeechSynthesisVoice(identifier: AVSpeechSynthesisVoiceIdentifierAlex)
        }
        
        let modifiedInstruction = voiceControllerDelegate?.voiceController?(self, willSpeak: instruction, routeProgress: routeProgress!) ?? instruction
        
        if #available(iOS 10.0, *), utterance?.voice == nil, let legProgress = routeProgress!.currentLegProgress {
            utterance = AVSpeechUtterance(attributedString: modifiedInstruction.attributedText(for: legProgress))
        } else {
            utterance = AVSpeechUtterance(string: modifiedInstruction.text)
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
    
    /** Called when a spoken is about to speak. Useful if it is necessary to give a custom instruction instead. Noting, changing the `distanceAlongStep` property on `SpokenInstruction` will have no impact on when the instruction will be said.
     
     - parameter voiceController: The voice controller that will speak an instruction.
     - parameter instruction: The spoken instruction that will be said.
     - parameter routeProgress: The `RouteProgress` just before when the instruction is scheduled to be spoken.
     **/
    @objc(voiceController:willSpeakSpokenInstruction:routeProgress:)
    optional func voiceController(_ voiceController: RouteVoiceController, willSpeak instruction: SpokenInstruction, routeProgress: RouteProgress) -> SpokenInstruction?
}
