
import AVFoundation
import MapboxDirections
import MapboxSpeech

class MapboxSpeechSynthesizer: NSObject, SpeechSynthesizerController {
    
    // MARK: - Properties
    
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
    
    // MARK: - Lifecycle
    
    init(_ accessToken: String? = nil) {
        self.cache = DataCache()
        self.speech = SpeechSynthesizer(accessToken: accessToken)
    }
    
    // MARK: - Methods
    
    func changedIncomingSpokenInstructions(_ instructions: [SpokenInstruction]) {
        instructions
            .prefix(stepsAheadToCache)
            .forEach {
                if !hasCachedSpokenInstructionForKey($0.ssmlText) {
                    downloadAndCacheSpokenInstruction(instruction: $0)
                }
        }
    }
    
    func speak(_ instruction: SpokenInstruction, completion: SpeechSynthesizerCompletion?) {
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
    
    func stopSpeaking() {
        audioPlayer?.stop()
    }
    
    func interruptSpeaking() {
        audioPlayer?.stop()
    }
    
    // MARK: - Private Methods
    
    /**
     Fetches and plays an instruction.
     */
    private func fetchAndSpeak(instruction: SpokenInstruction){
        audioTask?.cancel()
        let ssmlText = instruction.ssmlText
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
                self.completion?(SpeechError.apiError(instruction: instruction,
                                                  options: options,
                                                  underlying: error))
                return
            }
            
            guard let data = data else {
                self.completion?(SpeechError.noData(instruction: instruction,
                                                    options: options))
                return
            }
            
            self.cache(data, forKey: ssmlText)
            self.safeDuckAudio(instruction: instruction)
            self.completion?(self.speakWithMapboxSynthesizer(instruction: instruction,
                                                             instructionData: data))
        }
        
        audioTask?.resume()
    }
    
    private func speakWithMapboxSynthesizer(instruction: SpokenInstruction, instructionData: Data) -> Error? {
        
        if audioPlayer != nil {
            interruptSpeaking()
            deinitAudioPlayer()
        }
        
        switch safeInitializeAudioPlayer(data: instructionData,
                                         instruction: instruction) {
        case .success(let player):
            audioPlayer = player
            print("Mapbox SPEAKS!")
            audioPlayer?.play() // do we need to retain audio player at all?
            return nil
        case .failure(let error):
            self.safeUnduckAudio(instruction: instruction)
            return error
        }
    }
    
    private func downloadAndCacheSpokenInstruction(instruction: SpokenInstruction) {
        let ssmlText = instruction.ssmlText
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
                                                    synthesizer: speech,
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
                                                    synthesizer: speech,
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

    private func safeInitializeAudioPlayer(data: Data, instruction: SpokenInstruction) -> Result<AVAudioPlayer, Error> {
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
