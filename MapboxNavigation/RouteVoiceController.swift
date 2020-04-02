
import Foundation
import AVFoundation
import MapboxDirections
import MapboxCoreNavigation
import MapboxSpeech

extension NSAttributedString {
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
                NSAttributedString.Key(rawValue: AVSpeechSynthesisIPANotationAttribute): phoneticWord
            ]))
        }
        return phoneticString
    }
}

extension SpokenInstruction {
    func attributedText(for legProgress: RouteLegProgress) -> NSAttributedString {
        let attributedText = NSMutableAttributedString(string: text)
        if let step = legProgress.upcomingStep,
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
 A route voice controller plays spoken instructions as audio using the Speech Synthesis framework, also known as VoiceOver.
 
 You initialize a voice controller using a `NavigationService` instance. The voice controller observes when the navigation service hints that the user has passed a _spoken instruction point_ and responds by reading aloud the contents of a `SpokenInstruction` object using an `AVSpeechSynthesizer` object.
 
 The Speech Synthesis framework does not require a network connection, but the speech quality may be limited in some languages including English. By default, a `NavigationViewController` plays spoken instruction susing a subclass, `MapboxVoiceController`, that is powered by the [MapboxSpeech](https://github.com/mapbox/mapbox-speech-swift/) framework instead of the Speech Synthesis framework.
 
 If you need to supply a third-party speech synthesizer, define a subclass of `RouteVoiceController` that overrides the `speak(_:)` method. If the third-party speech synthesizer requires a network connection, you can instead subclass `MapboxVoiceController` to take advantage of its prefetching functionality.
 */
open class RouteVoiceController: NSObject, AVSpeechSynthesizerDelegate {
    lazy var speechSynth = AVSpeechSynthesizer()
    
    let audioQueue = DispatchQueue(label: Bundle.mapboxNavigation.bundleIdentifier! + ".audio")
    
    /**
     If true, a noise indicating the user is going to be rerouted will play prior to rerouting.
     */
    public var playRerouteSound = true
    
    /**
     Sound to play prior to reroute. Inherits volume level from `volume`.
     */
    public var rerouteSoundPlayer: AVAudioPlayer = try! AVAudioPlayer(data: NSDataAsset(name: "reroute-sound", bundle: .mapboxNavigation)!.data, fileTypeHint: AVFileType.mp3.rawValue)
    
    /**
     Delegate used for getting metadata information about a particular spoken instruction.
     */
    public weak var voiceControllerDelegate: VoiceControllerDelegate?
    
    var lastSpokenInstruction: SpokenInstruction?
    var routeProgress: RouteProgress?
    
    /**
     Default initializer for `RouteVoiceController`.
     */
        public init(navigationService: NavigationService) {
        super.init()

        verifyBackgroundAudio()

        speechSynth.delegate = self
        
        observeNotifications(by: navigationService)
    }
    
    @available(*, unavailable, message: "Use init(navigationService:) instead.")
    public override init() {
        fatalError()
    }

    private func verifyBackgroundAudio() {
        guard UIApplication.shared.isKind(of: UIApplication.self) else {
            return
        }

        if !Bundle.main.backgroundModes.contains("audio") {
            assert(false, "This application’s Info.plist file must include “audio” in UIBackgroundModes. This background mode is used for spoken instructions while the application is in the background.")
        }
    }

    deinit {
        suspendNotifications()
        speechSynth.stopSpeaking(at: .immediate)
    }
    
    func observeNotifications(by service: NavigationService) {
        NotificationCenter.default.addObserver(self, selector: #selector(didPassSpokenInstructionPoint(notification:)), name: .routeControllerDidPassSpokenInstructionPoint, object: service.router)
        NotificationCenter.default.addObserver(self, selector: #selector(pauseSpeechAndPlayReroutingDing(notification:)), name: .routeControllerWillReroute, object: service.router)
        NotificationCenter.default.addObserver(self, selector: #selector(didReroute(notification:)), name: .routeControllerDidReroute, object: service.router)
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateSettings(notification:)), name: .navigationSettingsDidChange, object: NavigationSettings.shared)
    }
    
    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: .routeControllerDidPassSpokenInstructionPoint, object: nil)
        NotificationCenter.default.removeObserver(self, name: .routeControllerWillReroute, object: nil)
        NotificationCenter.default.removeObserver(self, name: .routeControllerDidReroute, object: nil)
        NotificationCenter.default.removeObserver(self, name: .navigationSettingsDidChange, object: nil)
    }
    
    @objc func didUpdateSettings(notification: NSNotification) {
        if let isMuted = notification.userInfo?[NavigationSettings.StoredProperty.voiceMuted.key] as? Bool, isMuted {
            speechSynth.stopSpeaking(at: .immediate)
        }
    }
    
    @objc func didReroute(notification: NSNotification) {
        // Play reroute sound when a faster route is found
        if notification.userInfo?[RouteController.NotificationUserInfoKey.isProactiveKey] as! Bool {
            pauseSpeechAndPlayReroutingDing(notification: notification)
        }
    }
    
    @objc func pauseSpeechAndPlayReroutingDing(notification: NSNotification) {
        guard playRerouteSound && !NavigationSettings.shared.voiceMuted else {
            return
        }
        
        speechSynth.stopSpeaking(at: .word)
        
        safeMixAudio(instruction: nil, engine: speechSynth) {
            voiceControllerDelegate?.voiceController(self, spokenInstructionsDidFailWith: $0)
        }
        
        rerouteSoundPlayer.play()
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        safeUnduckAudio(instruction: nil, engine: synthesizer) {
            voiceControllerDelegate?.voiceController(self, spokenInstructionsDidFailWith: $0)
        }
    }
    
    typealias AudioControlFailureHandler = (SpeechError) -> Void
    func safeDuckAudio(instruction: SpokenInstruction?, engine: Any?, failure: AudioControlFailureHandler) {
        do {
            try tryDuckAudio()
        } catch {
            let wrapped = SpeechError.unableToControlAudio(instruction: instruction, action: .duck, synthesizer: engine, underlying: error)
            failure(wrapped)
            return
        }
    }
    
    func safeUnduckAudio(instruction: SpokenInstruction?, engine: Any?, failure: AudioControlFailureHandler) {
        do {
            try tryUnduckAudio()
        } catch {
            let wrapped = SpeechError.unableToControlAudio(instruction: instruction, action: .duck, synthesizer: engine, underlying: error)
            failure(wrapped)
            return
        }
    }
    
    func safeMixAudio(instruction: SpokenInstruction?, engine: Any?, failure: AudioControlFailureHandler) {
        do {
            try tryMixAudio()
        } catch {
            let wrapped = SpeechError.unableToControlAudio(instruction: instruction, action: .mix, synthesizer: engine, underlying: error)
            failure(wrapped)
            return
        }
    }
    
    func tryDuckAudio() throws {
        let audioSession = AVAudioSession.sharedInstance()
        if #available(iOS 12.0, *) {
            try audioSession.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers, .mixWithOthers])
        } else {
            try audioSession.setCategory(.ambient, mode: .spokenAudio, options: [.duckOthers, .mixWithOthers])
        }
        try audioSession.setActive(true)
    }
    
    func tryMixAudio() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.ambient, mode: audioSession.mode)
        try audioSession.setActive(true)
    }
    
    func tryUnduckAudio() throws {
        try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
    
    @objc open func didPassSpokenInstructionPoint(notification: NSNotification) {
        guard !NavigationSettings.shared.voiceMuted else { return }
        
        routeProgress = notification.userInfo![RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress
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
            voiceControllerDelegate?.voiceController(self, didInterrupt: lastSpokenInstruction, with: instruction)
        }
        
        safeDuckAudio(instruction: instruction, engine: speechSynth) {
            voiceControllerDelegate?.voiceController(self, spokenInstructionsDidFailWith: $0)
        }
        
        var utterance: AVSpeechUtterance?
        if Locale.preferredLocalLanguageCountryCode == "en-US" {
            // Alex can’t handle attributed text.
            utterance = AVSpeechUtterance(string: instruction.text)
            utterance!.voice = AVSpeechSynthesisVoice(identifier: AVSpeechSynthesisVoiceIdentifierAlex)
        }
        
        let modifiedInstruction = voiceControllerDelegate?.voiceController(self, willSpeak: instruction, routeProgress: routeProgress!) ?? instruction
        
        if utterance?.voice == nil {
            utterance = AVSpeechUtterance(attributedString: modifiedInstruction.attributedText(for: routeProgress!.currentLegProgress))
        }
        
        // Only localized languages will have a proper fallback voice
        if utterance?.voice == nil {
            utterance?.voice = AVSpeechSynthesisVoice(language: Locale.preferredLocalLanguageCountryCode)
        }
        
        if let utterance = utterance {
            speechSynth.speak(utterance)
        }
    }
}

/**
 The `VoiceControllerDelegate` protocol defines methods that allow an object to respond to significant events related to spoken instructions.
 */
public protocol VoiceControllerDelegate: class, UnimplementedLogging {
    /**
     Called when the voice controller falls back to a backup speech syntehsizer, but is still able to speak the instruction.
     
     - parameter voiceController: The voice controller that experienced the failure.
     - parameter synthesizer: the Speech engine that was used as the fallback.
     - parameter error: An error explaining the failure and its cause.
     */
    func voiceController(_ voiceController: RouteVoiceController, didFallBackTo synthesizer: AVSpeechSynthesizer, error: SpeechError)
   
    /**
     Called when the voice controller failed to speak an instruction.
     
     - parameter voiceController: The voice controller that experienced the failure.
     - parameter error: An error explaining the failure and its cause.
     */
    func voiceController(_ voiceController: RouteVoiceController, spokenInstructionsDidFailWith error: SpeechError)
    
    /**
     Called when one spoken instruction interrupts another instruction currently being spoken.
     
     - parameter voiceController: The voice controller that experienced the interruption.
     - parameter interruptedInstruction: The spoken instruction currently in progress that has been interrupted.
     - parameter interruptingInstruction: The spoken instruction that is interrupting the current instruction.
     */
    func voiceController(_ voiceController: RouteVoiceController, didInterrupt interruptedInstruction: SpokenInstruction, with interruptingInstruction: SpokenInstruction)
    
    /**
     Called when a spoken is about to speak. Useful if it is necessary to give a custom instruction instead. Noting, changing the `distanceAlongStep` property on `SpokenInstruction` will have no impact on when the instruction will be said.
     
     - parameter voiceController: The voice controller that will speak an instruction.
     - parameter instruction: The spoken instruction that will be said.
     - parameter routeProgress: The `RouteProgress` just before when the instruction is scheduled to be spoken.
     */
    func voiceController(_ voiceController: RouteVoiceController, willSpeak instruction: SpokenInstruction, routeProgress: RouteProgress) -> SpokenInstruction?
}

public extension VoiceControllerDelegate {
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func voiceController(_ voiceController: RouteVoiceController, didFallBackTo synthesizer: AVSpeechSynthesizer, error: SpeechError) {
        logUnimplemented(protocolType: VoiceControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func voiceController(_ voiceController: RouteVoiceController, spokenInstructionsDidFailWith error: Error) {
        logUnimplemented(protocolType: VoiceControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func voiceController(_ voiceController: RouteVoiceController, didInterrupt interruptedInstruction: SpokenInstruction, with interruptingInstruction: SpokenInstruction) {
        logUnimplemented(protocolType: VoiceControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func voiceController(_ voiceController: RouteVoiceController, willSpeak instruction: SpokenInstruction, routeProgress: RouteProgress) -> SpokenInstruction? {
        logUnimplemented(protocolType: VoiceControllerDelegate.self, level: .debug)
        return nil
    }
}
