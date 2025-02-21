import AVFoundation
import Combine
import MapboxDirections

/// ``SpeechSynthesizing`` implementation, using ``AVSpeechSynthesizer``.
@_spi(MapboxInternal)
public final class SystemSpeechSynthesizer: NSObject, SpeechSynthesizing {
    private let _voiceInstructions: PassthroughSubject<VoiceInstructionEvent, Never> = .init()
    public var voiceInstructions: AnyPublisher<VoiceInstructionEvent, Never> {
        _voiceInstructions.eraseToAnyPublisher()
    }

    // MARK: Speech Configuration

    public var muted: Bool = false {
        didSet {
            if isSpeaking {
                interruptSpeaking()
            }
        }
    }

    public var volume: VolumeMode {
        get {
            .system
        }
        set {
            // Do Nothing
            // AVSpeechSynthesizer uses 'AVAudioSession.sharedInstance().outputVolume' by default
        }
    }

    public var locale: Locale? = Locale.autoupdatingCurrent

    /// Controls if this speech synthesizer is allowed to manage the shared `AVAudioSession`.
    /// Set this field to `false` if you want to manage the session yourself, for example if your app has background
    /// music.
    /// Default value is `true`.
    public var managesAudioSession = true

    // MARK: Speaking Instructions

    public var isSpeaking: Bool { return speechSynthesizer.isSpeaking }

    private var speechSynthesizer: AVSpeechSynthesizer {
        _speechSynthesizer.speechSynthesizer
    }

    /// Holds `AVSpeechSynthesizer` that can be sent between isolation contexts but should be operated on MainActor.
    ///
    /// Motivation:
    /// We must stop synthesizer when the instance is deallocated, but deinit isn't guaranteed to be called on
    /// MainActor. So we can't safely access synthesizer from it.
    private var _speechSynthesizer: SendableSpeechSynthesizer

    private var previousInstruction: SpokenInstruction?

    override public init() {
        self._speechSynthesizer = .init(AVSpeechSynthesizer())
        super.init()
        speechSynthesizer.delegate = self
    }

    deinit {
        Task { @MainActor [_speechSynthesizer, managesAudioSession] in
            if _speechSynthesizer.speechSynthesizer.isSpeaking {
                _speechSynthesizer.speechSynthesizer.stopSpeaking(at: .immediate)
            }
            if !managesAudioSession {
                return
            }
            Task {
                try await AVAudioSessionHelper.shared.unduckAudio() // not deferred
            }
        }
    }

    public func prepareIncomingSpokenInstructions(_ instructions: [SpokenInstruction], locale: Locale?) {
        // Do nothing
    }

    public func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress, locale: Locale? = nil) {
        guard !muted else {
            _voiceInstructions.send(
                VoiceInstructionEvents.DidSpeak(
                    instruction: instruction
                )
            )
            return
        }

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

        var utterance: AVSpeechUtterance?
        let localeCode = [locale.languageCode, locale.regionCode].compactMap { $0 }.joined(separator: "-")

        if localeCode == "en-US" {
            // Alex can’t handle attributed text.
            utterance = AVSpeechUtterance(string: instruction.text)
            utterance!.voice = AVSpeechSynthesisVoice(identifier: AVSpeechSynthesisVoiceIdentifierAlex)
        }

        _voiceInstructions.send(VoiceInstructionEvents.WillSpeak(instruction: instruction))

        if utterance?.voice == nil {
            utterance = AVSpeechUtterance(attributedString: instruction.attributedText(for: legProgress))
        }

        // Only localized languages will have a proper fallback voice
        if utterance?.voice == nil {
            utterance?.voice = AVSpeechSynthesisVoice(language: localeCode)
        }

        guard let utteranceToSpeak = utterance else {
            _voiceInstructions.send(
                VoiceInstructionEvents.EncounteredError(
                    error: SpeechError.unsupportedLocale(
                        locale: Locale.nationalizedCurrent
                    )
                )
            )
            return
        }
        if let previousInstruction, speechSynthesizer.isSpeaking {
            _voiceInstructions.send(
                VoiceInstructionEvents.DidInterrupt(
                    interruptedInstruction: previousInstruction,
                    interruptingInstruction: instruction
                )
            )
        }
        previousInstruction = instruction

        Log.debug("SystemSpeechSynthesizer: Requesting to speak: [\(utteranceToSpeak.speechString)]", category: .audio)
        Task { [weak self] in
            guard let self else { return }

            if speechSynthesizer.isSpeaking {
                Log.debug("SystemSpeechSynthesizer: Interrupting current instruction speech", category: .audio)
                speechSynthesizer.stopSpeaking(at: .immediate)
            }

            await safeDuckAudioAsync()
            speechSynthesizer.speak(utteranceToSpeak)
        }
    }

    public func stopSpeaking() {
        Log.debug("SystemSpeechSynthesizer: Stop speaking", category: .audio)
        speechSynthesizer.stopSpeaking(at: .word)
    }

    public func interruptSpeaking() {
        Log.debug("SystemSpeechSynthesizer: Interrupt speaking", category: .audio)
        speechSynthesizer.stopSpeaking(at: .immediate)
    }

    private func safeDuckAudioAsync() async {
        guard managesAudioSession else { return }

        do {
            try await AVAudioSessionHelper.shared.duckAudio()
        } catch {
            Log.error("SystemSpeechSynthesizer: Failed to Activate AVAudioSession, error: \(error)", category: .audio)

            guard let instruction = previousInstruction else {
                Log.warning("Speech Synthesizer finished speaking 'nil' instruction", category: .audio)
                return
            }
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

    private func safeDeferredUnduckAudio() async {
        guard managesAudioSession else { return }
        let deactivationScheduled = await AVAudioSessionHelper.shared.deferredUnduckAudio()
        if !deactivationScheduled {
            Log.debug(
                "SystemSpeechSynthesizer: Deactivation of AVAudioSession not scheduled - another one in progress",
                category: .audio
            )
        }

        if previousInstruction == nil {
            Log.warning("Speech Synthesizer finished speaking 'nil' instruction", category: .audio)
        }
    }
}

extension SystemSpeechSynthesizer: AVSpeechSynthesizerDelegate {
    public nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didStart utterance: AVSpeechUtterance
    ) {
        Log.debug("SystemSpeechSynthesizer: didStart utterance: [\(utterance.speechString)]", category: .audio)
    }

    public func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        if characterRange.location == 0 { // logging just first occurrence for utterance string
            Log.debug(
                "SystemSpeeechSynthesizer: willSpeakString utterance: [\(utterance.speechString)]",
                category: .audio
            )
        }
    }

    public nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didContinue utterance: AVSpeechUtterance
    ) {
        // Should never be called because AVSpeechSynthesizer's pauseSpeaking(at:) and continueSpeaking() are not used
        Log.warning(
            "SystemSpeechSynthesizer: Unexpectedly called didContinue utterance: [\(utterance.speechString)]",
            category: .audio
        )
    }

    public nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Log.debug(
            "SystemSpeechSynthesizer: didFinish utterance: [\(utterance.speechString)], isSpeaking == \(synthesizer.isSpeaking)",
            category: .audio
        )

        Task {
            await safeDeferredUnduckAudio()
        }

        MainActor.assumingIsolated {
            guard let instruction = previousInstruction else {
                Log.warning("SystemSpeechSynthesizer finished speaking 'nil' instruction", category: .audio)
                return
            }
            _voiceInstructions.send(VoiceInstructionEvents.DidSpeak(instruction: instruction))
        }
    }

    public nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didPause utterance: AVSpeechUtterance
    ) {
        // Should never be called because AVSpeechSynthesizer's pauseSpeaking(at:) and continueSpeaking() are not used
        Log.warning(
            "SystemSpeechSynthesizer: Unexpectly called didPause utterance: [\(utterance.speechString)]",
            category: .audio
        )
    }

    public nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        Log.debug(
            "SystemSpeechSynthesizer: didCancel utterance: [\(utterance.speechString), isSpeaking == \(synthesizer.isSpeaking)]",
            category: .audio
        )

        Task {
            await safeDeferredUnduckAudio()
        }

        MainActor.assumingIsolated {
            guard let instruction = previousInstruction else {
                Log.warning("SystemSpeechSynthesizer: Finished speaking 'nil' instruction", category: .audio)
                return
            }
            _voiceInstructions.send(VoiceInstructionEvents.DidSpeak(instruction: instruction))
        }
    }
}

@MainActor
private final class SendableSpeechSynthesizer: Sendable {
    let speechSynthesizer: AVSpeechSynthesizer

    init(_ speechSynthesizer: AVSpeechSynthesizer) {
        self.speechSynthesizer = speechSynthesizer
    }
}
