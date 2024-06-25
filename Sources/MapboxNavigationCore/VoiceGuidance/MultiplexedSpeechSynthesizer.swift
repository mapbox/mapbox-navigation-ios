import _MapboxNavigationHelpers
import AVFoundation
import Combine
import MapboxDirections

/// ``SpeechSynthesizing``implementation, aggregating other implementations, to allow 'fallback' mechanism.
/// Can be initialized with array of synthesizers which will be called in order of appearance, until one of them is
/// capable to vocalize current ``SpokenInstruction``
public final class MultiplexedSpeechSynthesizer: SpeechSynthesizing {
    private static let mutedDefaultKey = "com.mapbox.navigation.MultiplexedSpeechSynthesizer.isMuted"
    private var _voiceInstructions: PassthroughSubject<VoiceInstructionEvent, Never> = .init()
    public var voiceInstructions: AnyPublisher<VoiceInstructionEvent, Never> {
        _voiceInstructions.eraseToAnyPublisher()
    }

    // MARK: Speech Configuration

    public var muted: Bool = false {
        didSet {
            applyMute()
        }
    }

    public var volume: VolumeMode = .system {
        didSet {
            applyVolume()
        }
    }

    public var locale: Locale? = Locale.autoupdatingCurrent {
        didSet {
            applyLocale()
        }
    }

    private func applyMute() {
        UserDefaults.standard.setValue(muted, forKey: Self.mutedDefaultKey)
        speechSynthesizers.forEach { $0.muted = muted }
    }

    private func applyVolume() {
        speechSynthesizers.forEach { $0.volume = volume }
    }

    private func applyLocale() {
        speechSynthesizers.forEach { $0.locale = locale }
    }

    /// Controls if this speech synthesizer is allowed to manage the shared `AVAudioSession`.
    /// Set this field to `false` if you want to manage the session yourself, for example if your app has background
    /// music.
    /// Default value is `true`.
    public var managesAudioSession: Bool {
        get {
            speechSynthesizers.allSatisfy { $0.managesAudioSession == true }
        }
        set {
            speechSynthesizers.forEach { $0.managesAudioSession = newValue }
        }
    }

    // MARK: Instructions vocalization

    public var isSpeaking: Bool {
        return speechSynthesizers.first(where: { $0.isSpeaking }) != nil
    }

    private var synthesizersSubscriptions: [AnyCancellable] = []
    public var speechSynthesizers: [any SpeechSynthesizing] {
        willSet {
            upstreamSynthesizersWillUpdate(newValue)
        }
        didSet {
            upstreamSynthesizersUpdated()
        }
    }

    private var currentLegProgress: RouteLegProgress?
    private var currentInstruction: SpokenInstruction?

    public init(speechSynthesizers: [any SpeechSynthesizing]) {
        self.speechSynthesizers = speechSynthesizers
        applyVolume()
        postInit()
    }

    public convenience init(
        mapboxSpeechApiConfiguration: ApiConfiguration,
        skuTokenProvider: @Sendable @escaping () -> String?,
        customSpeechSynthesizers: [SpeechSynthesizing] = []
    ) {
        var speechSynthesizers = customSpeechSynthesizers
        speechSynthesizers.append(MapboxSpeechSynthesizer(
            apiConfiguration: mapboxSpeechApiConfiguration,
            skuTokenProvider: .init(skuToken: skuTokenProvider)
        ))
        speechSynthesizers.append(SystemSpeechSynthesizer())
        self.init(speechSynthesizers: speechSynthesizers)
    }

    private func postInit() {
        muted = UserDefaults.standard.bool(forKey: Self.mutedDefaultKey)
        upstreamSynthesizersWillUpdate(speechSynthesizers)
        upstreamSynthesizersUpdated()
    }

    public func prepareIncomingSpokenInstructions(_ instructions: [SpokenInstruction], locale: Locale? = nil) {
        speechSynthesizers.forEach { $0.prepareIncomingSpokenInstructions(instructions, locale: locale) }
    }

    public func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress, locale: Locale? = nil) {
        currentLegProgress = legProgress
        currentInstruction = instruction
        speechSynthesizers.first?.speak(instruction, during: legProgress, locale: locale)
    }

    public func stopSpeaking() {
        speechSynthesizers.forEach { $0.stopSpeaking() }
    }

    public func interruptSpeaking() {
        speechSynthesizers.forEach { $0.interruptSpeaking() }
    }

    private func upstreamSynthesizersWillUpdate(_ newValue: [any SpeechSynthesizing]) {
        var found: [any SpeechSynthesizing] = []
        let duplicate = newValue.first { newSynth in
            if found.first(where: {
                return $0 === newSynth
            }) == nil {
                found.append(newSynth)
                return false
            }
            return true
        }

        precondition(
            duplicate == nil,
            "Single `SpeechSynthesizing` object passed to `MultiplexedSpeechSynthesizer` multiple times!"
        )

        speechSynthesizers.forEach {
            $0.interruptSpeaking()
        }
        synthesizersSubscriptions = []
    }

    private func upstreamSynthesizersUpdated() {
        synthesizersSubscriptions = speechSynthesizers.enumerated().map { item in

            return item.element.voiceInstructions.sink { [weak self] event in
                switch event {
                case let errorEvent as VoiceInstructionEvents.EncounteredError:
                    switch errorEvent.error {
                    case .unableToControlAudio(instruction: _, action: _, underlying: _):
                        // do nothing special
                        break
                    default:
                        if let legProgress = self?.currentLegProgress,
                           let currentInstruction = self?.currentInstruction,
                           item.offset + 1 < self?.speechSynthesizers.count ?? 0
                        {
                            self?.speechSynthesizers[item.offset + 1].speak(
                                currentInstruction,
                                during: legProgress,
                                locale: self?.locale
                            )
                            return
                        }
                    }
                default:
                    break
                }
                self?._voiceInstructions.send(event)
            }
        }
        applyMute()
        applyVolume()
        applyLocale()
    }
}
