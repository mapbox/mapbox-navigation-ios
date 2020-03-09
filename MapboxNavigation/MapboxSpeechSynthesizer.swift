
import AVFoundation
import MapboxDirections
import MapboxSpeech

open class MapboxSpeechSynthesizer: NSObject, SpeechSynthesizerController {
    
    // MARK: - Properties
    
    public var delegate: SpeechSynthesizerDelegate?
    public var muted: Bool = false {
        didSet {
            if muted {
                audioPlayer?.stop()
            }
        }
    }
    public var volume: Float {
        get {
            return audioPlayer?.volume ?? 1.0
        }
        set {
            audioPlayer?.volume = newValue
        }
    }
    public var isSpeaking: Bool {
        return audioPlayer?.isPlaying ?? false
    }
    public var locale: Locale = Locale.autoupdatingCurrent // deware locale update. or make it immutable?
    
    public let stepsAheadToCache: Int = 3
    
    /**
     An `AVAudioPlayer` through which spoken instructions are played.
     */
    public var audioPlayer: AVAudioPlayer?
    
    private var cache: BimodalDataCache
    private var speech: SpeechSynthesizer
    private var audioTask: URLSessionDataTask?
    
    private var completion: SpeechSynthesizerCompletion?
    private var previousInstrcution: SpokenInstruction?
    
    // MARK: - Lifecycle
    
    init(_ accessToken: String? = nil) {
        self.cache = DataCache()
        self.speech = SpeechSynthesizer(accessToken: accessToken)
    }
    
    deinit {
        // stop talking and unduck
    }
    
    // MARK: - Methods
    
    public func changedIncomingSpokenInstructions(_ instructions: [SpokenInstruction]) {
        instructions
            .prefix(stepsAheadToCache)
            .forEach {
                if !hasCachedSpokenInstructionForKey($0.ssmlText) {
                    downloadAndCacheSpokenInstruction(instruction: $0)
                }
        }
    }
    
    public func speak(_ instruction: SpokenInstruction, completion: SpeechSynthesizerCompletion?) {
        if let data = cachedDataForKey(instruction.ssmlText) {
            safeDuckAudio(instruction: instruction)
            completion?(speakWithMapboxSynthesizer(instruction: instruction,
                                              instructionData: data))
        }
        else {
            self.completion = completion
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
        
        let modifiedInstruction = delegate?.voiceController(self, willSpeak: instruction) ?? instruction
        let ssmlText = modifiedInstruction.ssmlText
        let options = SpeechOptions(ssml: ssmlText)
        options.locale = locale
                        
        audioTask = speech.audioData(with: options) { [weak self] (data, error) in
            defer { self?.completion = nil }
            
            guard let self = self else { return }
            if let error = error,
                case let .unknown(response: _, underlying: underlyingError, code: _, message: _) = error,
                let urlError = underlyingError as? URLError, urlError.code == .cancelled {
                self.completion?(error)
                return
            } else if let error = error {
                self.delegate?.voiceController(self, spokenInstructionsDidFailWith: SpeechError.apiError(instruction: modifiedInstruction,
                                                                                                    options: options,
                                                                                                    underlying: error))
                self.completion?(SpeechError.apiError(instruction: modifiedInstruction,
                                                      options: options,
                                                      underlying: error))
                return
            }
            
            guard let data = data else {
                self.delegate?.voiceController(self, spokenInstructionsDidFailWith: SpeechError.noData(instruction: modifiedInstruction,
                                                                                                  options: options))
                self.completion?(SpeechError.noData(instruction: modifiedInstruction,
                                                    options: options))
                return
            }
            
            self.cache(data, forKey: ssmlText)
            self.safeDuckAudio(instruction: modifiedInstruction)
            if let error = self.speakWithMapboxSynthesizer(instruction: modifiedInstruction,
                                                           instructionData: data) {
                self.delegate?.voiceController(self, spokenInstructionsDidFailWith: error)
                self.completion?(error)
            }
            else {
                self.completion?(nil)
            }
        }
        
        audioTask?.resume()
    }
    
    private func speakWithMapboxSynthesizer(instruction: SpokenInstruction, instructionData: Data) -> SpeechError? {
        
        if let audioPlayer = audioPlayer {
            if let previousInstrcution = previousInstrcution, audioPlayer.isPlaying{
                delegate?.voiceController(self,
                                          didInterrupt: previousInstrcution,
                                          with: instruction)
            }
            
            deinitAudioPlayer()
        }
        
        switch safeInitializeAudioPlayer(data: instructionData,
                                         instruction: instruction) {
        case .success(let player):
            audioPlayer = player
            print("Mapbox SPEAKS!")
            audioPlayer?.play()
            previousInstrcution = instruction
            return nil
        case .failure(let error):
            safeUnduckAudio(instruction: instruction)
            delegate?.voiceController(self, spokenInstructionsDidFailWith: error)
            return error
        }
    }
    
    private func downloadAndCacheSpokenInstruction(instruction: SpokenInstruction) {
        let modifiedInstruction = delegate?.voiceController(self, willSpeak: instruction) ?? instruction
        let ssmlText = modifiedInstruction.ssmlText
        let options = SpeechOptions(ssml: ssmlText)
        options.locale = locale
        
        speech.audioData(with: options) { [weak self] (data, error) in
            guard let data = data else {
                return
            }
            self?.cache(data, forKey: ssmlText)
        }.resume()
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
                                                    underlying: error)
        }
        return nil
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

    private func safeInitializeAudioPlayer(data: Data, instruction: SpokenInstruction) -> Result<AVAudioPlayer, SpeechError> {
        do {
            let player = try AVAudioPlayer(data: data)
            player.delegate = self
            player.volume = volume
            
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
    // AVAudioSessionInterruptionNotification ?
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        safeUnduckAudio(instruction: nil)
    }
}
