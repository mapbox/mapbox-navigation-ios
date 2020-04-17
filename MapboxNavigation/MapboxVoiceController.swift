import Foundation
import CoreLocation
import AVFoundation
import MapboxSpeech
import MapboxCoreNavigation
import MapboxDirections

/**
 The Mapbox voice controller plays spoken instructions using the [MapboxSpeech](https://github.com/mapbox/mapbox-speech-swift/) framework.
 
 You initialize a voice controller using a `NavigationService` instance. The voice controller observes when the navigation service hints that the user has passed a _spoken instruction point_ and responds by converting the contents of a `SpokenInstruction` object into audio and playing the audio.
 
 The MapboxSpeech framework requires a network connection to connect to the Mapbox Voice API, but it produces superior speech output in several languages including English. If the voice controller is unable to connect to the Voice API, it falls back to the Speech Synthesis framework as implemented by the superclass, `RouteVoiceController`. To mitigate network latency over a cell connection, `MapboxVoiceController` prefetches and caches synthesized audio.
 
 If you need to supply a third-party speech synthesizer that requires a network connection, define a subclass of `MapboxVoiceController` that overrides the `speak(_:)` method. If the third-party speech synthesizer does not require a network connection, you can instead subclass `RouteVoiceController`.
 
 The Mapbox Voice API is optimized for spoken instructions provided by the Mapbox Directions API via the MapboxDirections.swift framework. If you need text-to-speech functionality outside the context of a navigation service, use the Speech Synthesis framework’s `AVSpeechSynthesizer` class directly.
 */
open class MapboxVoiceController: RouteVoiceController, AVAudioPlayerDelegate {
    /**
     Number of seconds a request can wait before it is canceled and the default speech synthesizer speaks the instruction.
     */
    public var timeoutIntervalForRequest: TimeInterval = 5
    
    /**
     Number of steps ahead of the current step to cache spoken instructions.
     */
    public var stepsAheadToCache: Int = 3
    
    /**
     An `AVAudioPlayer` through which spoken instructions are played.
     */
    public var audioPlayer: AVAudioPlayer?
    
    var audioTask: URLSessionDataTask?
    var cache: BimodalDataCache
    let audioPlayerType: AVAudioPlayer.Type
    
    var speech: SpeechSynthesizer
    var locale: Locale?
    
    let localizedErrorMessage = NSLocalizedString("FAILED_INSTRUCTION", bundle: .mapboxNavigation, value: "Unable to read instruction aloud.", comment: "Error message when the SDK is unable to read a spoken instruction.")
    
    public init(navigationService: NavigationService, speechClient: SpeechSynthesizer = SpeechSynthesizer(accessToken: nil), dataCache: BimodalDataCache = DataCache(), audioPlayerType: AVAudioPlayer.Type? = nil) {
        speech = speechClient
        cache = dataCache
        self.audioPlayerType = audioPlayerType ?? AVAudioPlayer.self
        super.init(navigationService: navigationService)
        
        audioPlayer?.delegate = self
    }
    
    deinit {
        audioPlayer?.stop()
        
        safeUnduckAudio(instruction: nil, engine: speech) {
            voiceControllerDelegate?.voiceController(self, spokenInstructionsDidFailWith: $0)
        }
        
        audioPlayer?.delegate = nil
    }
    
    @objc override func didUpdateSettings(notification: NSNotification) {
        if let isMuted = notification.userInfo?[NavigationSettings.StoredProperty.voiceMuted.key] as? Bool, isMuted {
            audioPlayer?.stop()
            
            safeUnduckAudio(instruction: nil, engine: speech) {
                voiceControllerDelegate?.voiceController(self, spokenInstructionsDidFailWith: $0)
            }
        }
        if let voiceVolume = notification.userInfo?[NavigationSettings.StoredProperty.voiceVolume.key] as? Float {
            audioPlayer?.volume = voiceVolume
        }
    }
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        safeUnduckAudio(instruction: nil, engine: speech) {
            voiceControllerDelegate?.voiceController(self, spokenInstructionsDidFailWith: $0)
        }
    }
    
    open override func didPassSpokenInstructionPoint(notification: NSNotification) {
        let routeProgresss = notification.userInfo![RouteController.NotificationUserInfoKey.routeProgressKey] as! RouteProgress
        locale = routeProgresss.routeOptions.locale
        let currentLegProgress: RouteLegProgress = routeProgresss.currentLegProgress
        
        let instructionSets = currentLegProgress.remainingSteps.prefix(stepsAheadToCache).compactMap { $0.instructionsSpokenAlongStep }
        let instructions = instructionSets.flatMap { $0 }
        let unfetchedInstructions = instructions.filter { !hasCachedSpokenInstructionForKey($0.ssmlText) }
        
        unfetchedInstructions.forEach( downloadAndCacheSpokenInstruction(instruction:) )
        
        super.didPassSpokenInstructionPoint(notification: notification)
    }
    
    /**
     Speaks an instruction.
     
     The cache is first checked to see if we have already downloaded the speech file. If not, the instruction is fetched and played. If there is an error anywhere along the way, the instruction will be spoken with the default speech synthesizer.
     */
    open override func speak(_ instruction: SpokenInstruction) {
        if let audioPlayer = audioPlayer, audioPlayer.isPlaying, let lastSpokenInstruction = lastSpokenInstruction {
            voiceControllerDelegate?.voiceController(self, didInterrupt: lastSpokenInstruction, with: instruction)
        }
        
        audioTask?.cancel()
        audioPlayer?.stop()
        
        guard let progress = routeProgress else {
            assertionFailure("routeProgress should not be nil.")
            return
        }
        
        guard progress.route.speechLocale != nil else {
            let wrapped = SpeechError.undefinedSpeechLocale(instruction: instruction, progress: progress)
            speakWithDefaultSpeechSynthesizer(instruction, error: wrapped)
            return
        }
        
        let modifiedInstruction = voiceControllerDelegate?.voiceController(self, willSpeak: instruction, routeProgress: routeProgress!) ?? instruction
        lastSpokenInstruction = modifiedInstruction
        
        if let data = cachedDataForKey(modifiedInstruction.ssmlText) {
            play(instruction: instruction, data: data)
            return
        }
        
        fetchAndSpeak(instruction: modifiedInstruction)
    }
    
    /**
     Speaks an instruction with the built in speech synthesizer.
     
     This method should be used in cases where `fetch(instruction:)` or `play(_:)` fails.
     */
    open func speakWithDefaultSpeechSynthesizer(_ instruction: SpokenInstruction, error: SpeechError?) {
        audioTask?.cancel()
        
        if let error = error {
            voiceControllerDelegate?.voiceController(self, didFallBackTo: speechSynth, error: error)
        }
        
        guard !(audioPlayer?.isPlaying ?? false) else {
            return
        }
        
        super.speak(instruction)
    }
    
    /**
     Fetches and plays an instruction.
     */
    open func fetchAndSpeak(instruction: SpokenInstruction) {
        audioTask?.cancel()
        let ssmlText = instruction.ssmlText
        let options = SpeechOptions(ssml: ssmlText)
        if let locale = locale {
            options.locale = locale
        }
        
        audioTask = speech.audioData(with: options) { [weak self] (data, error) in
            guard let strongSelf = self else { return }
            if let error = error,
                case let .unknown(response: _, underlying: underlyingError, code: _, message: _) = error,
                let urlError = underlyingError as? URLError, urlError.code == .cancelled {
                return
            } else if let error = error {
                let wrapped = SpeechError.apiError(instruction: instruction, options: options, underlying: error)
                strongSelf.speakWithDefaultSpeechSynthesizer(instruction, error: wrapped)
                return
            }
            
            guard let data = data else {
                let wrapped = SpeechError.noData(instruction: instruction, options: options)
                strongSelf.speakWithDefaultSpeechSynthesizer(instruction, error: wrapped)
                return
            }
            strongSelf.play(instruction: instruction, data: data)
            strongSelf.cache(data, forKey: ssmlText)
        }
        
        audioTask?.resume()
    }
    
    /**
     Caches an instruction in an in-memory cache.
     */
    open func downloadAndCacheSpokenInstruction(instruction: SpokenInstruction) {
        let ssmlText = instruction.ssmlText
        let options = SpeechOptions(ssml: ssmlText)
        if let locale = locale {
            options.locale = locale
        }
        
        if let locale = routeProgress?.route.speechLocale {
            options.locale = locale
        }
        
        speech.audioData(with: options) { [weak self] (data, error) in
            guard let data = data else {
                return
            }
            self?.cache(data, forKey: ssmlText)
        }
    }
    
    private func cache(_ data: Data, forKey key: String) {
        cache.store(data, forKey: key, toDisk: true, completion: nil)
    }
    
    internal func cachedDataForKey(_ key: String) -> Data? {
        return cache.data(forKey: key)
    }
    
    internal func hasCachedSpokenInstructionForKey(_ key: String) -> Bool {
        return cachedDataForKey(key) != nil
    }
    
    func safeInitalizeAudioPlayer(playerType: AVAudioPlayer.Type, data: Data, instruction: SpokenInstruction, engine: Any?, failure: AudioControlFailureHandler) -> AVAudioPlayer? {
        do {
            let player = try playerType.init(data: data)
            return player
        } catch {
            let wrapped = SpeechError.unableToInitializePlayer(playerType: playerType, instruction: instruction, synthesizer: engine, underlying: error)
            failure(wrapped)
            return nil
        }
    }
    
    /**
     Plays an audio file.
     */
    open func play(instruction: SpokenInstruction, data: Data) {
        let fallback: (SpeechError) -> Void = { [weak self] (error) in
            self?.speakWithDefaultSpeechSynthesizer(instruction, error: error)
        }
        
        super.speechSynth.stopSpeaking(at: .immediate)
        
        audioQueue.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.audioPlayer = strongSelf.safeInitalizeAudioPlayer(playerType: strongSelf.audioPlayerType, data: data, instruction: instruction, engine: strongSelf.speech, failure: fallback)
            strongSelf.audioPlayer?.prepareToPlay()
            strongSelf.audioPlayer?.delegate = strongSelf
            
            strongSelf.safeDuckAudio(instruction: instruction, engine: strongSelf.speech, failure: fallback)
            
            let played = strongSelf.audioPlayer?.play() ?? false
            
            guard played else {
                strongSelf.safeUnduckAudio(instruction: instruction, engine: strongSelf.speech, failure: fallback)
                return
            }
        }
    }
}

//MARK: - Obsolete
extension MapboxVoiceController {
    @available(swift, obsoleted: 0.1, message: "It is now required that the maneuver's `SpokenInstruction` is passed into `play` when calling. Please use MapboxVoiceController.play(instruction:data:).")
    open func play(_ data: Data) {
        fatalError()
    }
}
