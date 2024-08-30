import _MapboxNavigationHelpers
import AVFoundation
import Combine
import MapboxDirections

@MainActor
/// ``SpeechSynthesizing`` implementation, using Mapbox Voice API. Uses pre-caching mechanism for upcoming instructions.
public final class MapboxSpeechSynthesizer: SpeechSynthesizing {
    private var _voiceInstructions: PassthroughSubject<VoiceInstructionEvent, Never> = .init()
    public var voiceInstructions: AnyPublisher<VoiceInstructionEvent, Never> {
        _voiceInstructions.eraseToAnyPublisher()
    }

    // MARK: Speech Configuration

    public var muted: Bool = false {
        didSet {
            updatePlayerVolume(audioPlayer)
        }
    }

    private var volumeSubscribtion: AnyCancellable?
    public var volume: VolumeMode = .system {
        didSet {
            guard volume != oldValue else { return }

            switch volume {
            case .system:
                subscribeToSystemVolume()
            case .override(let volume):
                volumeSubscribtion = nil
                audioPlayer?.volume = volume
            }
        }
    }

    private var currentVolume: Float {
        switch volume {
        case .system:
            return 1.0
        case .override(let volume):
            return volume
        }
    }

    private func subscribeToSystemVolume() {
        audioPlayer?.volume = AVAudioSession.sharedInstance().outputVolume
        volumeSubscribtion = AVAudioSession.sharedInstance().publisher(for: \.outputVolume).sink { [weak self] volume in
            self?.audioPlayer?.volume = volume
        }
    }

    public var locale: Locale? = Locale.autoupdatingCurrent

    /// Number of upcoming `Instructions` to be pre-fetched.
    ///
    /// Higher number may exclude cases when required vocalization data is not yet loaded, but also will increase
    /// network consumption at the beginning of the route. Keep in mind that pre-fetched instuctions are not guaranteed
    /// to be vocalized at all due to re-routing or user actions. "0" will effectively disable pre-fetching.
    public var stepsAheadToCache: UInt = 3

    /// An `AVAudioPlayer` through which spoken instructions are played.
    private var audioPlayer: AVAudioPlayer? {
        _audioPlayer?.audioPlayer
    }

    private var _audioPlayer: SendableAudioPlayer?
    private let audioPlayerDelegate: AudioPlayerDelegate = .init()

    /// Controls if this speech synthesizer is allowed to manage the shared `AVAudioSession`.
    /// Set this field to `false` if you want to manage the session yourself, for example if your app has background
    /// music.
    /// Default value is `true`.
    public var managesAudioSession: Bool = true

    /// Mapbox speech engine instance.
    ///
    /// The speech synthesizer uses this object to convert instruction text to audio.
    private(set) var remoteSpeechSynthesizer: SpeechSynthesizer

    private var cache: SyncBimodalCache
    private var audioTask: Task<Void, Error>?

    private var previousInstruction: SpokenInstruction?

    // MARK: Instructions vocalization

    /// Checks if speech synthesizer is now pronouncing an instruction.
    public var isSpeaking: Bool {
        return audioPlayer?.isPlaying ?? false
    }

    /// Creates new `MapboxSpeechSynthesizer` with standard `SpeechSynthesizer` for converting text to audio.
    ///
    /// - parameter accessToken: A Mapbox [access token](https://www.mapbox.com/help/define-access-token/) used to
    /// authorize Mapbox Voice API requests. If an access token is not specified when initializing the speech
    /// synthesizer object, it should be specified in the `MBXAccessToken` key in the main application bundle’s
    /// Info.plist.
    /// - parameter host: An optional hostname to the server API. The Mapbox Voice API endpoint is used by default.
    init(
        apiConfiguration: ApiConfiguration,
        skuTokenProvider: SkuTokenProvider
    ) {
        self.cache = MapboxSyncBimodalCache()

        self.remoteSpeechSynthesizer = SpeechSynthesizer(
            apiConfiguration: apiConfiguration,
            skuTokenProvider: skuTokenProvider
        )

        subscribeToSystemVolume()
    }

    deinit {
        Task { @MainActor [_audioPlayer] in
            _audioPlayer?.stop()
        }
    }

    public func prepareIncomingSpokenInstructions(_ instructions: [SpokenInstruction], locale: Locale? = nil) {
        guard let locale = locale ?? self.locale else {
            _voiceInstructions.send(
                VoiceInstructionEvents.EncounteredError(
                    error: SpeechError.undefinedSpeechLocale(
                        instruction: instructions.first!
                    )
                )
            )
            return
        }

        for insturction in instructions.prefix(Int(stepsAheadToCache)) {
            if !hasCachedSpokenInstructionForKey(insturction.ssmlText, with: locale) {
                downloadAndCacheSpokenInstruction(instruction: insturction, locale: locale)
            }
        }
    }

    public func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress, locale: Locale? = nil) {
        guard !muted else { return }
        guard let locale = locale ?? self.locale else {
            _voiceInstructions.send(
                VoiceInstructionEvents.EncounteredError(
                    error: SpeechError.undefinedSpeechLocale(
                        instruction: instruction
                    )
                )
            )
            return
        }

        guard let data = cachedDataForKey(instruction.ssmlText, with: locale) else {
            fetchAndSpeak(instruction: instruction, locale: locale)
            return
        }

        _voiceInstructions.send(
            VoiceInstructionEvents.WillSpeak(
                instruction: instruction
            )
        )
        safeDuckAudio(instruction: instruction)
        speak(instruction, data: data)
    }

    public func stopSpeaking() {
        audioPlayer?.stop()
    }

    public func interruptSpeaking() {
        audioPlayer?.stop()
    }

    /// Vocalize the provided audio data.
    ///
    /// This method is a final part of a vocalization pipeline. It passes audio data to the audio player. `instruction`
    /// is used mainly for logging and reference purposes. It's text contents do not affect the vocalization while the
    /// actual audio is passed via `data`.
    /// - parameter instruction: corresponding instruction to be vocalized. Used for logging and reference. Modifying
    /// it's `text` or `ssmlText` does not affect vocalization.
    /// - parameter data: audio data, as provided by `remoteSpeechSynthesizer`, to be played.
    public func speak(_ instruction: SpokenInstruction, data: Data) {
        if let audioPlayer {
            if let previousInstruction, audioPlayer.isPlaying {
                _voiceInstructions.send(
                    VoiceInstructionEvents.DidInterrupt(
                        interruptedInstruction: previousInstruction,
                        interruptingInstruction: instruction
                    )
                )
            }

            deinitAudioPlayer()
        }

        switch safeInitializeAudioPlayer(
            data: data,
            instruction: instruction
        ) {
        case .success(let player):
            _audioPlayer = .init(player)
            previousInstruction = instruction
            audioPlayer?.play()
        case .failure(let error):
            safeUnduckAudio(instruction: instruction)
            _voiceInstructions.send(
                VoiceInstructionEvents.EncounteredError(
                    error: error
                )
            )
        }
    }

    // MARK: Private Methods

    /// Fetches and plays an instruction.
    private func fetchAndSpeak(instruction: SpokenInstruction, locale: Locale) {
        audioTask?.cancel()

        _voiceInstructions.send(
            VoiceInstructionEvents.WillSpeak(
                instruction: instruction
            )
        )
        let ssmlText = instruction.ssmlText
        let options = SpeechOptions(ssml: ssmlText, locale: locale)

        audioTask = Task {
            do {
                let audio = try await self.remoteSpeechSynthesizer.audioData(with: options)
                try Task.checkCancellation()
                self.cache(audio, forKey: ssmlText, with: locale)
                self.safeDuckAudio(instruction: instruction)
                self.speak(
                    instruction,
                    data: audio
                )
            } catch let speechError as SpeechErrorApiError {
                switch speechError {
                case .transportError(underlying: let urlError) where urlError.code == .cancelled:
                    // Since several voice instructions might be received almost at the same time cancelled
                    // URLSessionDataTask is not considered as error.
                    // This means that in this case fallback to another speech synthesizer will not be performed.
                    break
                default:
                    self._voiceInstructions.send(
                        VoiceInstructionEvents.EncounteredError(
                            error: SpeechError.apiError(
                                instruction: instruction,
                                options: options,
                                underlying: speechError
                            )
                        )
                    )
                }
            }
        }
    }

    private func downloadAndCacheSpokenInstruction(instruction: SpokenInstruction, locale: Locale) {
        let ssmlText = instruction.ssmlText
        let options = SpeechOptions(ssml: ssmlText, locale: locale)

        Task {
            do {
                let audio = try await remoteSpeechSynthesizer.audioData(with: options)
                cache(audio, forKey: ssmlText, with: locale)
            } catch {
                Log.error(
                    "Couldn't cache spoken instruction '\(instruction)' due to error \(error) ",
                    category: .navigation
                )
            }
        }
    }

    func safeDuckAudio(instruction: SpokenInstruction?) {
        guard managesAudioSession else { return }
        if let error = AVAudioSession.sharedInstance().tryDuckAudio() {
            _voiceInstructions.send(
                VoiceInstructionEvents.EncounteredError(
                    error: SpeechError.unableToControlAudio(
                        instruction: instruction,
                        action: .duck,
                        underlying: error
                    )
                )
            )
        }
    }

    func safeUnduckAudio(instruction: SpokenInstruction?) {
        guard managesAudioSession else { return }
        if let error = AVAudioSession.sharedInstance().tryUnduckAudio() {
            _voiceInstructions.send(
                VoiceInstructionEvents.EncounteredError(
                    error: SpeechError.unableToControlAudio(
                        instruction: instruction,
                        action: .unduck,
                        underlying: error
                    )
                )
            )
        }
    }

    private func cache(_ data: Data, forKey key: String, with locale: Locale) {
        cache.store(
            data: data,
            key: locale.identifier + key,
            mode: [.InMemory, .OnDisk]
        )
    }

    private func cachedDataForKey(_ key: String, with locale: Locale) -> Data? {
        return cache[locale.identifier + key]
    }

    private func hasCachedSpokenInstructionForKey(_ key: String, with locale: Locale) -> Bool {
        return cachedDataForKey(key, with: locale) != nil
    }

    private func updatePlayerVolume(_ player: AVAudioPlayer?) {
        player?.volume = muted ? 0.0 : currentVolume
    }

    private func safeInitializeAudioPlayer(
        data: Data,
        instruction: SpokenInstruction
    ) -> Result<AVAudioPlayer, SpeechError> {
        do {
            let player = try AVAudioPlayer(data: data)
            player.delegate = audioPlayerDelegate
            audioPlayerDelegate.onAudioPlayerDidFinishPlaying = { [weak self] _, _ in
                guard let self else { return }
                safeUnduckAudio(instruction: previousInstruction)

                guard let instruction = previousInstruction else {
                    assertionFailure("Speech Synthesizer finished speaking 'nil' instruction")
                    return
                }

                _voiceInstructions.send(
                    VoiceInstructionEvents.DidSpeak(
                        instruction: instruction
                    )
                )
            }
            updatePlayerVolume(player)

            return .success(player)
        } catch {
            return .failure(SpeechError.unableToInitializePlayer(
                playerType: AVAudioPlayer.self,
                instruction: instruction,
                synthesizer: remoteSpeechSynthesizer,
                underlying: error
            ))
        }
    }

    private func deinitAudioPlayer() {
        audioPlayer?.stop()
        audioPlayer?.delegate = nil
    }
}

@MainActor
private final class SendableAudioPlayer: Sendable {
    let audioPlayer: AVAudioPlayer

    init(_ audioPlayer: AVAudioPlayer) {
        self.audioPlayer = audioPlayer
    }

    nonisolated func stop() {
        DispatchQueue.main.async {
            self.audioPlayer.stop()
        }
    }
}
