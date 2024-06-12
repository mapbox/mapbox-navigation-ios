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
        Task { @MainActor [_speechSynthesizer] in
            _speechSynthesizer.speechSynthesizer.stopSpeaking(at: .immediate)
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
        speechSynthesizer.speak(utteranceToSpeak)
    }

    public func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .word)
    }

    public func interruptSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }

    private func safeDuckAudio() {
        guard managesAudioSession else { return }
        if let error = AVAudioSession.sharedInstance().tryDuckAudio() {
            guard let instruction = previousInstruction else {
                assertionFailure("Speech Synthesizer finished speaking 'nil' instruction")
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

    private func safeUnduckAudio() {
        guard managesAudioSession else { return }
        if let error = AVAudioSession.sharedInstance().tryUnduckAudio() {
            guard let instruction = previousInstruction else {
                assertionFailure("Speech Synthesizer finished speaking 'nil' instruction")
                return
            }

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
}

extension SystemSpeechSynthesizer: AVSpeechSynthesizerDelegate {
    public nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didStart utterance: AVSpeechUtterance
    ) {
        MainActor.assumingIsolated {
            safeDuckAudio()
        }
    }

    public nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didContinue utterance: AVSpeechUtterance
    ) {
        MainActor.assumingIsolated {
            safeDuckAudio()
        }
    }

    public nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        MainActor.assumingIsolated {
            safeUnduckAudio()
            guard let instruction = previousInstruction else {
                assertionFailure("Speech Synthesizer finished speaking 'nil' instruction")
                return
            }
            _voiceInstructions.send(VoiceInstructionEvents.DidSpeak(instruction: instruction))
        }
    }

    public nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didPause utterance: AVSpeechUtterance
    ) {
        MainActor.assumingIsolated {
            safeUnduckAudio()
        }
    }

    public nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        MainActor.assumingIsolated {
            safeUnduckAudio()
            guard let instruction = previousInstruction else {
                assertionFailure("Speech Synthesizer finished speaking 'nil' instruction")
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
