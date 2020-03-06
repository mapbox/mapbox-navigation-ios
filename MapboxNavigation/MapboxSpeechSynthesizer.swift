
import AVFoundation
import MapboxDirections
import MapboxCoreNavigation
import MapboxSpeech

///
open class MapboxSpeechSynthesizer: NSObject, SpeechSynthesizerController {
    
    // MARK: - Properties
    
    public var muted: Bool = false {
        didSet {
            if muted {
                audioPlayer?.stop()
            }
        }
    }
    public var volume: Float = 1.0 {
        didSet {
            audioPlayer?.volume = volume
        }
    }
    public var isSpeaking: Bool { return audioPlayer?.isPlaying ?? false }
    public var locale: Locale = Locale.autoupdatingCurrent {
        didSet {
            // fuckup all cached instructions?
        }
    }
    
    private lazy var speechSynth = AVSpeechSynthesizer()
    private let audioQueue = DispatchQueue(label: Bundle.mapboxNavigation.bundleIdentifier! + ".audio")
    
    /**
     An `AVAudioPlayer` through which spoken instructions are played.
     */
    public var audioPlayer: AVAudioPlayer?
    private var audioTask: URLSessionDataTask?
    private var cache: BimodalDataCache
    private var speech: SpeechSynthesizer
    
    //arguable
    /**
     Number of steps ahead of the current step to cache spoken instructions.
     */
    public var stepsAheadToCache: Int = 3
    
    // MARK: - Lifecycle
    
    override init() {
        self.cache = DataCache()
        self.speech = SpeechSynthesizer(accessToken: nil)
    }
    
    deinit {
        deinitAudioPlayer()
    }
    
    // MARK: - Public Methods
    
    public func changedIncomingSpokenInstructions(_ instructions: [SpokenInstruction]) { // maybe filter out passed ones in the controller?
        // beware locale change or rerouting
        instructions
//            .filter {
//                !hasCachedSpokenInstructionForKey($0.ssmlText)
//        }
        .prefix(stepsAheadToCache)
        .forEach {
            if !hasCachedSpokenInstructionForKey($0.ssmlText) {
                downloadAndCacheSpokenInstruction(instruction: $0)
            }
        }
    }
    
    ///
    public func speak(_ instruction: SpokenInstruction, with currentLegProgress: RouteLegProgress) {
        print(instruction.text)
        
        if let data = cachedDataForKey(instruction.ssmlText) {
            self.playDucked {
                self.speakWithMapboxSynthesizer(instruction: instruction,
                                                instructionData: data)
            }
        }
        else {
            fetchAndSpeak(instruction: instruction, with: currentLegProgress)
        }
    }
    
    ///
    public func stopSpeaking() {
        speechSynth.stopSpeaking(at: .word)
    }
    
    ///
    public func interrupt() {
        speechSynth.stopSpeaking(at: .immediate)
    }
    
    // MARK: - Methods
    
    func downloadAndCacheSpokenInstruction(instruction: SpokenInstruction) {
        let ssmlText = instruction.ssmlText
        let options = SpeechOptions(ssml: ssmlText)
        options.locale = locale
        
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
    private func cachedDataForKey(_ key: String) -> Data? {
        return cache.data(forKey: key)
    }
    
    private func hasCachedSpokenInstructionForKey(_ key: String) -> Bool {
        return cachedDataForKey(key) != nil
    }
    /**
     Fetches and plays an instruction.
     */
    func fetchAndSpeak(instruction: SpokenInstruction, with currentLegProgress: RouteLegProgress) {
        audioTask?.cancel()
        let ssmlText = instruction.ssmlText
        let options = SpeechOptions(ssml: ssmlText)
        options.locale = locale
        
        audioTask = speech.audioData(with: options) { [weak self] (data, error) in
            guard let self = self else { return }
            if let error = error,
                case let .unknown(response: _, underlying: underlyingError, code: _, message: _) = error,
                let urlError = underlyingError as? URLError, urlError.code == .cancelled {
                return
            } else if let error = error {
//                let wrapped = SpeechError.apiError(instruction: instruction, options: options, underlying: error)
                self.playDucked {
                    self.speakWithSystemSynthesizer(instruction: instruction, legProgress: currentLegProgress)   // beware retain cycle
                }
                return
            }
            
            guard let data = data else {
//                let wrapped = SpeechError.noData(instruction: instruction, options: options)
                self.playDucked {
                    self.speakWithSystemSynthesizer(instruction: instruction, legProgress: currentLegProgress)
                }
                return
            }
//            strongSelf.play(instruction: instruction, data: data)
            self.cache(data, forKey: ssmlText)
            self.playDucked {
                self.speakWithMapboxSynthesizer(instruction: instruction,
                                                instructionData: data)
            }
        }
        
        audioTask?.resume()
    }
    
    func speakWithSystemSynthesizer(instruction: SpokenInstruction, legProgress: RouteLegProgress) {
        audioTask?.cancel()
        
        guard !(audioPlayer?.isPlaying ?? false) else {
            return
        }
        
//        if speechSynth.isSpeaking, let lastSpokenInstruction = lastSpokenInstruction {
//            voiceControllerDelegate?.voiceController(self, didInterrupt: lastSpokenInstruction, with: instruction)
//        }
        
//        safeDuckAudio(instruction: instruction, engine: speechSynth) {
//            voiceControllerDelegate?.voiceController(self, spokenInstructionsDidFailWith: $0)
//        }
        
        var utterance: AVSpeechUtterance?
        if Locale.preferredLocalLanguageCountryCode == "en-US" {
            // Alex can’t handle attributed text.
            utterance = AVSpeechUtterance(string: instruction.text)
            utterance!.voice = AVSpeechSynthesisVoice(identifier: AVSpeechSynthesisVoiceIdentifierAlex)
        }
        
        let modifiedInstruction = /*voiceControllerDelegate?.voiceController(self, willSpeak: instruction, routeProgress: routeProgress!) ?? */instruction
        
        if utterance?.voice == nil {
            utterance = AVSpeechUtterance(attributedString: modifiedInstruction.attributedText(for: legProgress))
        }
        
        // Only localized languages will have a proper fallback voice
        if utterance?.voice == nil {
            utterance?.voice = AVSpeechSynthesisVoice(language: Locale.preferredLocalLanguageCountryCode)
        }
        
        if let utterance = utterance {
            speechSynth.speak(utterance)
        }
    }
    
    func speakWithMapboxSynthesizer(instruction: SpokenInstruction, instructionData: Data) {
        
        if audioPlayer != nil {
            deinitAudioPlayer()
        }
        
        switch safeInitializeAudioPlayer(data: instructionData,
                                         instruction: instruction) {
        case .success(let player):
            audioPlayer = player
            audioPlayer?.play() // do we need to retain audio player at all?
        case .failure(let error):
            // TODO: report error
            break
        }
    }
    
    private func playDucked(instructions: () -> Void) {
        safeDuckAudio(instruction: nil)

        instructions()
    }
    
    @discardableResult
    func safeDuckAudio(instruction: SpokenInstruction?) -> Error? {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            if #available(iOS 12.0, *) {
                try audioSession.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers, .mixWithOthers])
            } else {
                try audioSession.setCategory(.ambient, mode: .spokenAudio, options: [.duckOthers, .mixWithOthers])
            }
            try audioSession.setActive(true)
        } catch {
            return SpeechError.unableToControlAudio(instruction: instruction,
                                                    action: .duck,
                                                    synthesizer: nil,
                                                    underlying: error)
        }
        return nil
    }
    
    @discardableResult
    func safeUnduckAudio(instruction: SpokenInstruction?) -> Error? {
        do {
            try AVAudioSession.sharedInstance().setActive(false,
                                                          options: [.notifyOthersOnDeactivation])
        } catch {
            return SpeechError.unableToControlAudio(instruction: instruction,
                                                    action: .duck,
                                                    synthesizer: nil,
                                                    underlying: error)
        }
        return nil
    }
    
    func safeInitializeAudioPlayer(data: Data, instruction: SpokenInstruction) -> Result<AVAudioPlayer, Error> {
        do {
            let player = try AVAudioPlayer(data: data)
            player.delegate = self
            player.volume = volume
            
            return .success(player)
        } catch {
            // TODO: report an error
            return .failure(SpeechError.unableToInitializePlayer(playerType: AVAudioPlayer.self,
                                                                 instruction: instruction,
                                                                 synthesizer: nil,
                                                                 underlying: error))
        }
    }
    
    func deinitAudioPlayer() {
        audioPlayer?.stop()
        audioPlayer?.delegate = nil
        audioPlayer = nil
    }
}

extension MapboxSpeechSynthesizer: AVAudioPlayerDelegate {
    // AVAudioSessionInterruptionNotification ?
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        safeUnduckAudio(instruction: nil)
    }
}
