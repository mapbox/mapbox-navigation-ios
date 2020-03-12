
import AVFoundation
import MapboxCoreNavigation
import MapboxDirections
import MapboxSpeech

/**
 `SpeechSynthesizing` implementation, using `MapboxSpeech` framework. Uses pre-caching mechanism for upcoming instructions.
 */
open class MapboxSpeechSynthesizer: NSObject, SpeechSynthesizing {
    
    // MARK: - Properties
    
    public weak var delegate: SpeechSynthesizingDelegate?
    public var muted: Bool = false {
        didSet {
            updatePlayerVolume()
        }
    }
    public var volume: Float = 1.0 {
        didSet {
            audioPlayer?.volume = volume
        }
    }
    public var isSpeaking: Bool {
        return audioPlayer?.isPlaying ?? false
    }
    public var locale: Locale = Locale.autoupdatingCurrent
    
    public let stepsAheadToCache: Int = 3
    
    /**
     An `AVAudioPlayer` through which spoken instructions are played.
     */
    public var audioPlayer: AVAudioPlayer?
    
    private var cache: BimodalDataCache
    private var speech: SpeechSynthesizer
    private var audioTask: URLSessionDataTask?
    
    private var previousInstrcution: SpokenInstruction?
    
    // MARK: - Lifecycle
    
    public init(_ accessToken: String? = nil) {
        self.cache = DataCache()
        self.speech = SpeechSynthesizer(accessToken: accessToken)
    }
    
    deinit {        
        deinitAudioPlayer()
    }
    
    // MARK: - Methods
    
    public func changedIncomingSpokenInstructions(_ instructions: [SpokenInstruction]) {
        instructions
            .prefix(stepsAheadToCache)
            .forEach {
                if !hasCachedSpokenInstructionForKey($0.ssmlText, with: locale) {
                    downloadAndCacheSpokenInstruction(instruction: $0)
                }
        }
    }
    
    public func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress) {
        if let data = cachedDataForKey(instruction.ssmlText, with: locale) {
            safeDuckAudio(instruction: instruction)
            speakWithMapboxSynthesizer(instruction: instruction,
                                       instructionData: data)
        }
        else {
            fetchAndSpeak(instruction: instruction)
        }
    }
    
    public func stopSpeaking() {
        audioPlayer?.stop()
    }
    
    public func interruptSpeaking() {
        audioPlayer?.stop()
    }
    
    // MARK: - Private Methods
    
    /**
     Fetches and plays an instruction.
     */
    private func fetchAndSpeak(instruction: SpokenInstruction){
        audioTask?.cancel()
        
        let modifiedInstruction = delegate?.speechSynthesizer(self, willSpeak: instruction) ?? instruction
        let ssmlText = modifiedInstruction.ssmlText
        let options = SpeechOptions(ssml: ssmlText)
        options.locale = locale
        
        audioTask = speech.audioData(with: options) { [weak self] (data, error) in
            guard let self = self else { return }
            if let speechError = error,
                case let .unknown(response: _, underlying: underlyingError, code: _, message: _) = speechError,
                let urlError = underlyingError as? URLError, urlError.code == .cancelled {
                self.delegate?.speechSynthesizer(self,
                                                 didSpeak: modifiedInstruction,
                                                 with: SpeechError.apiError(instruction: modifiedInstruction,
                                                                            options: options,
                                                                            underlying: urlError))
                return
            } else if let error = error {
                self.delegate?.speechSynthesizer(self,
                                                 didSpeak: modifiedInstruction,
                                                 with: SpeechError.apiError(instruction: modifiedInstruction,
                                                                            options: options,
                                                                            underlying: error))
                return
            }
            
            guard let data = data else {
                self.delegate?.speechSynthesizer(self,
                                                 didSpeak: modifiedInstruction,
                                                 with: SpeechError.noData(instruction: modifiedInstruction,
                                                                          options: options))
                return
            }
            
            self.cache(data, forKey: ssmlText, with: self.locale)
            self.safeDuckAudio(instruction: modifiedInstruction)
            self.speakWithMapboxSynthesizer(instruction: modifiedInstruction,
                                            instructionData: data)
        }
        
        audioTask?.resume()
    }
    
    private func speakWithMapboxSynthesizer(instruction: SpokenInstruction, instructionData: Data) {
        
        if let audioPlayer = audioPlayer {
            if let previousInstrcution = previousInstrcution, audioPlayer.isPlaying{
                delegate?.speechSynthesizer(self,
                                            didInterrupt: previousInstrcution,
                                            with: instruction)
            }
            
            deinitAudioPlayer()
        }
        
        switch safeInitializeAudioPlayer(data: instructionData,
                                         instruction: instruction) {
        case .success(let player):
            audioPlayer = player
            previousInstrcution = instruction
            audioPlayer?.play()
        case .failure(let error):
            safeUnduckAudio(instruction: instruction)
            delegate?.speechSynthesizer(self,
                                        didSpeak: instruction,
                                        with: error)
        }
    }
    
    private func downloadAndCacheSpokenInstruction(instruction: SpokenInstruction) {
        let modifiedInstruction = delegate?.speechSynthesizer(self, willSpeak: instruction) ?? instruction
        let ssmlText = modifiedInstruction.ssmlText
        let options = SpeechOptions(ssml: ssmlText)
        options.locale = locale
        
        speech.audioData(with: options) { [weak self] (data, error) in
            guard let data = data, let self = self else {
                return
            }
            self.cache(data, forKey: ssmlText, with: self.locale)
        }.resume()
    }
    
    func safeDuckAudio(instruction: SpokenInstruction?){
        do {
            let audioSession = AVAudioSession.sharedInstance()
            if #available(iOS 12.0, *) {
                try audioSession.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers, .mixWithOthers])
            } else {
                try audioSession.setCategory(.ambient, mode: .spokenAudio, options: [.duckOthers, .mixWithOthers])
            }
            try audioSession.setActive(true)
        } catch {
            delegate?.speechSynthesizer(self,
                                        encounteredError: SpeechError.unableToControlAudio(instruction: instruction,
                                                                                           action: .duck,
                                                                                           underlying: error))
        }
    }
    
    func safeUnduckAudio(instruction: SpokenInstruction?) {
        do {
            try AVAudioSession.sharedInstance().setActive(false,
                                                          options: [.notifyOthersOnDeactivation])
        } catch {
            delegate?.speechSynthesizer(self,
                                        encounteredError: SpeechError.unableToControlAudio(instruction: instruction,
                                                                                           action: .unduck,
                                                                                           underlying: error))
        }
    }
    
    private func cache(_ data: Data, forKey key: String, with locale: Locale) {
        cache.store(data, forKey: locale.identifier + key, toDisk: true, completion: nil)
    }
    private func cachedDataForKey(_ key: String, with locale: Locale) -> Data? {
        return cache.data(forKey: locale.identifier + key)
    }
    
    private func hasCachedSpokenInstructionForKey(_ key: String, with locale: Locale) -> Bool {
        return cachedDataForKey(key, with: locale) != nil
    }
    
    private func updatePlayerVolume() {
        audioPlayer?.volume = muted ? 0.0 : volume
    }
    
    private func safeInitializeAudioPlayer(data: Data, instruction: SpokenInstruction) -> Result<AVAudioPlayer, SpeechError> {
        do {
            let player = try AVAudioPlayer(data: data)
            player.delegate = self
            updatePlayerVolume()
            
            return .success(player)
        } catch {
            return .failure(SpeechError.unableToInitializePlayer(playerType: AVAudioPlayer.self,
                                                                 instruction: instruction,
                                                                 synthesizer: speech,
                                                                 underlying: error))
        }
    }
    
    private func deinitAudioPlayer() {
        audioPlayer?.stop()
        audioPlayer?.delegate = nil
    }
}

extension MapboxSpeechSynthesizer: AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        safeUnduckAudio(instruction: previousInstrcution)
        
        guard let instruction = previousInstrcution else {
            assert(false, "Speech Synthesizer finished speaking 'nil' instruction")
            return
        }
        
        delegate?.speechSynthesizer(self,
                                    didSpeak: instruction,
                                    with: nil)
    }
}
