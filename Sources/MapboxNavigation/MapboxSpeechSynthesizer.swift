import AVFoundation
import MapboxCoreNavigation
import MapboxDirections
import MapboxSpeech

/**
 `SpeechSynthesizing` implementation, using `MapboxSpeech` framework. Uses pre-caching mechanism for upcoming instructions.
 */
open class MapboxSpeechSynthesizer: NSObject, SpeechSynthesizing {
    
    // MARK: Speech Configuration
    
    public weak var delegate: SpeechSynthesizingDelegate?
    
    public var muted: Bool = false {
        didSet {
            updatePlayerVolume(audioPlayer)
        }
    }
    public var volume: Float = 1.0 {
        didSet {
            audioPlayer?.volume = volume
        }
    }
    
    public var locale: Locale? = Locale.autoupdatingCurrent
    
    /// Number of upcoming `Instructions` to be pre-fetched.
    ///
    /// Higher number may exclude cases when required vocalization data is not yet loaded, but also will increase network consumption at the beginning of the route. Keep in mind that pre-fetched instuctions are not guaranteed to be vocalized at all due to re-routing or user actions. "0" will effectively disable pre-fetching.
    public var stepsAheadToCache: UInt = 3
    
    /**
     An `AVAudioPlayer` through which spoken instructions are played.
     */
    public var audioPlayer: AVAudioPlayer?
    
    /// Controls if this speech synthesizer is allowed to manage the shared `AVAudioSession`.
    /// Set this field to `false` if you want to manage the session yourself, for example if your app has background music.
    /// Default value is `true`.
    public var managesAudioSession = true
    
    /**
     Mapbox speech engine instance.
     
     The speech synthesizer uses this object to convert instruction text to audio.
     */
    public private(set) var remoteSpeechSynthesizer: SpeechSynthesizer
    
    private var cache: BimodalDataCache
    private var audioTask: URLSessionDataTask?
    
    private var previousInstruction: SpokenInstruction?
    
    // MARK: Instructions vocalization
    
    public var isSpeaking: Bool {
        return audioPlayer?.isPlaying ?? false
    }
    
    public init(accessToken: String? = nil, host: String? = nil) {
        self.cache = DataCache()
        
        var hostString = host
        if let host = host, let url = URL(string: host) {
            hostString = url.host
        }
        
        self.remoteSpeechSynthesizer = SpeechSynthesizer(accessToken: accessToken, host: hostString)
    }
    
    deinit {
        deinitAudioPlayer()
    }
    
    open func prepareIncomingSpokenInstructions(_ instructions: [SpokenInstruction], locale: Locale? = nil) {
        
        guard let locale = locale ?? self.locale else {
            self.delegate?.speechSynthesizer(self,
                                             encounteredError: SpeechError.undefinedSpeechLocale(instruction: instructions.first!))
            return
        }
        
        instructions
            .prefix(Int(stepsAheadToCache))
            .forEach {
                if !hasCachedSpokenInstructionForKey($0.ssmlText, with: locale) {
                    downloadAndCacheSpokenInstruction(instruction: $0, locale: locale)
                }
        }
    }
    
    open func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress, locale: Locale? = nil) {
        guard let locale = locale ?? self.locale else {
            self.delegate?.speechSynthesizer(self,
                                             encounteredError: SpeechError.undefinedSpeechLocale(instruction: instruction))
            return
        }
        
        guard let data = cachedDataForKey(instruction.ssmlText, with: locale) else {
            fetchAndSpeak(instruction: instruction, locale: locale)
            return
        }
        
        if let modifiedInstruction = delegate?.speechSynthesizer(self, willSpeak: instruction), modifiedInstruction != instruction {
            // Application changed the instruction, we need to refetch and cache it
            fetchAndSpeak(instruction: modifiedInstruction, locale: locale)
        } else {
            safeDuckAudio(instruction: instruction)
            speak(instruction, data: data)
        }
    }
    
    open func stopSpeaking() {
        audioPlayer?.stop()
    }
    
    open func interruptSpeaking() {
        audioPlayer?.stop()
    }
    
    /**
     Vocalize the provided audio data.
     
     This method is a final part of a vocalization pipeline. It passes audio data to the audio player. `instruction` is used mainly for logging and reference purposes. It's text contents do not affect the vocalization while the actual audio is passed via `data`.
     - parameter instruction: corresponding instruction to be vocalized. Used for logging and reference. Modifying it's `text` or `ssmlText` does not affect vocalization.
     - parameter data: audio data, as provided by `remoteSpeechSynthesizer`, to be played.
     */
    open func speak(_ instruction: SpokenInstruction, data: Data) {
        
        if let audioPlayer = audioPlayer {
            if let previousInstruction = previousInstruction, audioPlayer.isPlaying{
                delegate?.speechSynthesizer(self,
                                            didInterrupt: previousInstruction,
                                            with: instruction)
            }
            
            deinitAudioPlayer()
        }
        
        switch safeInitializeAudioPlayer(data: data,
                                         instruction: instruction) {
        case .success(let player):
            audioPlayer = player
            previousInstruction = instruction
            audioPlayer?.play()
        case .failure(let error):
            safeUnduckAudio(instruction: instruction)
            delegate?.speechSynthesizer(self,
                                        didSpeak: instruction,
                                        with: error)
        }
    }
    
    // MARK: Private Methods
    
    /**
     Fetches and plays an instruction.
     */
    private func fetchAndSpeak(instruction: SpokenInstruction, locale: Locale) {
        audioTask?.cancel()
        
        let modifiedInstruction = delegate?.speechSynthesizer(self, willSpeak: instruction) ?? instruction
        let ssmlText = modifiedInstruction.ssmlText
        let options = SpeechOptions(ssml: ssmlText)
        options.locale = locale
        
        audioTask = remoteSpeechSynthesizer.audioData(with: options) { [weak self] (data, error) in
            guard let self = self else { return }
            if let speechError = error,
                case let .unknown(response: _, underlying: underlyingError, code: _, message: _) = speechError,
                let urlError = underlyingError as? URLError, urlError.code == .cancelled {
                // Since several voice instructions might be received almost at the same time cancelled URLSessionDataTask
                // is not considered as error. This means that in this case fallback to another speech synthesizer
                // will not be performed.
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
            
            self.cache(data, forKey: ssmlText, with: locale)
            self.safeDuckAudio(instruction: modifiedInstruction)
            self.speak(modifiedInstruction,
                       data: data)
        }
    }
    
    private func downloadAndCacheSpokenInstruction(instruction: SpokenInstruction, locale: Locale) {
        let ssmlText = instruction.ssmlText
        let options = SpeechOptions(ssml: ssmlText)
        options.locale = locale
        
        remoteSpeechSynthesizer.audioData(with: options) { [weak self] (data, error) in
            guard let data = data, let self = self else {
                return
            }
            self.cache(data, forKey: ssmlText, with: locale)
        }
    }
    
    func safeDuckAudio(instruction: SpokenInstruction?){
        guard managesAudioSession else { return }
        if let error = AVAudioSession.sharedInstance().tryDuckAudio() {
            delegate?.speechSynthesizer(self,
                                        encounteredError: SpeechError.unableToControlAudio(instruction: instruction,
                                                                                           action: .duck,
                                                                                           underlying: error))
        }
    }
    
    func safeUnduckAudio(instruction: SpokenInstruction?) {
        guard managesAudioSession else { return }
        if let error = AVAudioSession.sharedInstance().tryUnduckAudio() {
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
    
    private func updatePlayerVolume(_ player: AVAudioPlayer?) {
        player?.volume = muted ? 0.0 : volume
    }
    
    private func safeInitializeAudioPlayer(data: Data, instruction: SpokenInstruction) -> Result<AVAudioPlayer, SpeechError> {
        do {
            let player = try AVAudioPlayer(data: data)
            player.delegate = self
            updatePlayerVolume(player)
            
            return .success(player)
        } catch {
            return .failure(SpeechError.unableToInitializePlayer(playerType: AVAudioPlayer.self,
                                                                 instruction: instruction,
                                                                 synthesizer: remoteSpeechSynthesizer,
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
        safeUnduckAudio(instruction: previousInstruction)
        
        guard let instruction = previousInstruction else {
            assert(false, "Speech Synthesizer finished speaking 'nil' instruction")
            return
        }
        
        delegate?.speechSynthesizer(self,
                                    didSpeak: instruction,
                                    with: nil)
    }
}
