import Foundation
import CoreLocation
import AVFoundation
import MapboxSpeech
import MapboxCoreNavigation
import MapboxDirections

/**
 `MapboxVoiceController` extends the default `RouteVoiceController` by providing a more robust speech synthesizer via the Mapbox Speech API. `RouteVoiceController` will be used as a fallback during poor network conditions.
 */
@objc(MBMapboxVoiceController)
open class MapboxVoiceController: RouteVoiceController, AVAudioPlayerDelegate {
    
    /**
     Number of seconds a request can wait before it is canceled and the default speech synthesizer speaks the instruction.
     */
    @objc public var timeoutIntervalForRequest: TimeInterval = 5
    
    /**
     Number of steps ahead of the current step to cache spoken instructions.
     */
    @objc public var stepsAheadToCache: Int = 3
    
    /**
     An `AVAudioPlayer` through which spoken instructions are played.
     */
    @objc public var audioPlayer: AVAudioPlayer?
    
    var audioTask: URLSessionDataTask?
    var cache: BimodalDataCache
    let audioPlayerType: AVAudioPlayer.Type
    
    var speech: SpeechSynthesizer
    var locale: Locale?
    
    let localizedErrorMessage = NSLocalizedString("FAILED_INSTRUCTION", bundle: .mapboxNavigation, value: "Unable to read instruction aloud.", comment: "Error message when the SDK is unable to read a spoken instruction.")

    @objc public init(speechClient: SpeechSynthesizer = SpeechSynthesizer(accessToken: nil), dataCache: BimodalDataCache = DataCache(), audioPlayerType: AVAudioPlayer.Type? = nil) {
        speech = speechClient
        cache = dataCache
        self.audioPlayerType = audioPlayerType ?? AVAudioPlayer.self
        super.init()
        
        audioPlayer?.delegate = self
        
        volumeToken = NavigationSettings.shared.observe(\.voiceVolume) { [weak self] (settings, change) in
            self?.audioPlayer?.volume = settings.voiceVolume
        }
        
        muteToken = NavigationSettings.shared.observe(\.voiceMuted) { [weak self] (settings, change) in
            if settings.voiceMuted {
                self?.audioPlayer?.stop()
            }
        }
    }
    
    deinit {
        audioPlayer?.stop()
        audioPlayer?.delegate = nil
    }
    
    @objc public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        do {
            try unDuckAudio()
        } catch {
            voiceControllerDelegate?.voiceController?(self, spokenInstructionsDidFailWith: error)
        }
    }

    @objc open override func didPassSpokenInstructionPoint(notification: NSNotification) {
        let routeProgresss = notification.userInfo![RouteControllerNotificationUserInfoKey.routeProgressKey] as! RouteProgress
        locale = routeProgresss.route.routeOptions.locale
        let currentLegProgress: RouteLegProgress = routeProgresss.currentLegProgress

        for (stepIndex, step) in currentLegProgress.leg.steps.suffix(from: currentLegProgress.stepIndex).enumerated() {
            let adjustedStepIndex = stepIndex + currentLegProgress.stepIndex

            guard adjustedStepIndex < currentLegProgress.stepIndex + stepsAheadToCache else {
                continue
            }

            guard let instructions = step.instructionsSpokenAlongStep else {
                continue
            }

            for instruction in instructions {
                guard !hasCachedSpokenInstructionForKey(instruction.ssmlText) else {
                    continue
                }

                downloadAndCacheSpokenInstruction(instruction: instruction)
            }
        }
        
        super.didPassSpokenInstructionPoint(notification: notification)
    }

    /**
     Speaks an instruction.
     
     The cache is first checked to see if we have already downloaded the speech file. If not, the instruction is fetched and played. If there is an error anywhere along the way, the instruction will be spoken with the default speech synthesizer.
     */
    @objc open override func speak(_ instruction: SpokenInstruction) {
        if let audioPlayer = audioPlayer, audioPlayer.isPlaying, let lastSpokenInstruction = lastSpokenInstruction {
            voiceControllerDelegate?.voiceController?(self, didInterrupt: lastSpokenInstruction, with: instruction)
        }
        
        audioTask?.cancel()
        audioPlayer?.stop()
        
        assert(routeProgress != nil, "routeProgress should not be nil.")
        
        guard let _ = routeProgress!.route.speechLocale else {
            speakWithDefaultSpeechSynthesizer(instruction, error: nil)
            return
        }
        
        let modifiedInstruction = voiceControllerDelegate?.voiceController?(self, willSpeak: instruction, routeProgress: routeProgress!) ?? instruction
        lastSpokenInstruction = modifiedInstruction

        if let data = cachedDataForKey(modifiedInstruction.ssmlText) {
            play(data)
            return
        }
        
        fetchAndSpeak(instruction: modifiedInstruction)
    }

    /**
     Speaks an instruction with the built in speech synthesizer.
     
     This method should be used in cases where `fetch(instruction:)` or `play(_:)` fails.
     */
    @objc open func speakWithDefaultSpeechSynthesizer(_ instruction: SpokenInstruction, error: Error?) {
        audioTask?.cancel()
        
        if let error = error {
            voiceControllerDelegate?.voiceController?(self, spokenInstructionsDidFailWith: error)
        }
        
        guard let audioPlayer = audioPlayer else {
            super.speak(instruction)
            return
        }
        
        guard !audioPlayer.isPlaying else { return }
        
        super.speak(instruction)
    }
    
    /**
     Fetches and plays an instruction.
     */
    @objc open func fetchAndSpeak(instruction: SpokenInstruction) {
        audioTask?.cancel()
        let ssmlText = instruction.ssmlText
        let options = SpeechOptions(ssml: ssmlText)
        if let locale = locale {
            options.locale = locale
        }
        
        audioTask = speech.audioData(with: options) { [weak self] (data, error) in
            guard let strongSelf = self else { return }
            if let error = error as? URLError, error.code == .cancelled {
                return
            } else if let error = error {
                strongSelf.speakWithDefaultSpeechSynthesizer(instruction, error: error)
                return
            }
            
            guard let data = data else {
                strongSelf.speakWithDefaultSpeechSynthesizer(instruction, error: NSError(code: .spokenInstructionFailed, localizedFailureReason: strongSelf.localizedErrorMessage, spokenInstructionCode: .emptyMapboxSpeechResponse))
                return
            }
            strongSelf.play(data)
            strongSelf.cache(data, forKey: ssmlText)
        }
        
        audioTask?.resume()
    }

    /**
     Caches an instruction in an in-memory cache.
     */
    @objc open func downloadAndCacheSpokenInstruction(instruction: SpokenInstruction) {
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

    /**
     Plays an audio file.
     */
    @objc open func play(_ data: Data) {

        super.speechSynth.stopSpeaking(at: .immediate)
        
        audioQueue.async { [weak self] in
            guard let `self` = self else { return }
            do {
                self.audioPlayer = try self.audioPlayerType.init(data: data)
                self.audioPlayer?.prepareToPlay()
                self.audioPlayer?.delegate = self
                try self.duckAudio()
                let played = self.audioPlayer?.play() ?? false
                
                guard played else {
                    try self.unDuckAudio()
                    self.speakWithDefaultSpeechSynthesizer(self.lastSpokenInstruction!, error: NSError(code: .spokenInstructionFailed, localizedFailureReason: self.localizedErrorMessage, spokenInstructionCode: .audioPlayerFailedToPlay))
                    return
                }
                
            } catch  let error as NSError {
                self.speakWithDefaultSpeechSynthesizer(self.lastSpokenInstruction!, error: error)
            }
        }
    }
}
