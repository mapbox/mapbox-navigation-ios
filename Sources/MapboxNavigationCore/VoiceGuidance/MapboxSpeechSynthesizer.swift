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
        Task { @MainActor [_audioPlayer, managesAudioSession] in
            _audioPlayer?.stop()

            if !managesAudioSession {
                return
            }
            Task {
                try await AVAudioSessionHelper.shared.unduckAudio() // not deferred
            }
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

        for instruction in instructions.prefix(Int(stepsAheadToCache)) {
            if !hasCachedSpokenInstructionForKey(instruction.ssmlText, with: locale) {
                downloadAndCacheSpokenInstruction(instruction: instruction, locale: locale)
            }
        }
    }

    public func speak(_ instruction: SpokenInstruction, during _: RouteLegProgress, locale: Locale? = nil) {
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
        Task { [weak self] in
            guard let self else { return }
            Log.debug("MapboxSpeechSynthesizer: Will speak text: [\(instruction.text)]", category: .audio)
            await safeDuckAudio(instruction: instruction)
            speak(instruction, data: data)
        }
    }

    public func stopSpeaking() {
        Log.debug("MapboxSpeechSynthesizer: Stop speaking", category: .audio)
        audioPlayer?.stop()
    }

    public func interruptSpeaking() {
        Log.debug("MapboxSpeechSynthesizer: Interrupt speaking", category: .audio)
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
            Log.debug("MapboxSpeechSynthesizer: audio player Will play text: [\(instruction.text)]", category: .audio)
            audioPlayer?.play()
        case .failure(let error):
            Log.error("MapboxSpeechSynthesizer: audio player Failed to initialize: \(error)", category: .audio)
            Task {
                await safeDeferredUnduckAudio()
                _voiceInstructions.send(
                    VoiceInstructionEvents.EncounteredError(
                        error: error
                    )
                )
            }
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
                Log.debug("MapboxSpeechSynthesizer: Will speak text: [\(instruction.text)]", category: .audio)
                await self.safeDuckAudio(instruction: instruction)
                try Task.checkCancellation()
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

    func safeDuckAudio(instruction: SpokenInstruction?) async {
        guard managesAudioSession else { return }

        do {
            try await AVAudioSessionHelper.shared.duckAudio()
        } catch {
            Log.error("SystemSpeechSynthesizer: Failed to Activate AVAudioSession, error: \(error)", category: .audio)
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

    func safeDeferredUnduckAudio() async {
        guard managesAudioSession else { return }

        let deactivationScheduled = await AVAudioSessionHelper.shared.deferredUnduckAudio()
        if !deactivationScheduled {
            Log.debug(
                "SystemSpeechSynthesizer: Deactivation of AVAudioSession not scheduled - another one in progress",
                category: .audio
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
            audioPlayerDelegate.onAudioPlayerDidFinishPlaying = { [weak self] _, successfully in
                guard let self else { return }

                if successfully {
                    Log.debug("MapboxSpeechSynthesizer: audio player Did Finish playing Successfully", category: .audio)
                } else {
                    Log.warning(
                        "MapboxSpeechSynthesizer: audio player Did Finish playing with Failure",
                        category: .audio
                    )
                }

                Task { [weak self] in
                    guard let self else { return }
                    await safeDeferredUnduckAudio()
                }

                guard let instruction = previousInstruction else {
                    Log.warning("MapboxSpeechSynthesizer: Finished speaking 'nil' instruction", category: .audio)
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
