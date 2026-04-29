import AVFoundation
import Combine
import Foundation
import UIKit

/// Manages voice guidance during navigation by coordinating spoken instructions and audio feedback.
///
/// `RouteVoiceController` listens to route progress updates and triggers appropriate voice announcements
/// through a speech synthesizer. The controller can also play rerouting sounds to notify users when the
/// route is being recalculated, if ``playsRerouteSound`` is set to `true`.
///
/// ## Background Audio Configuration
///
/// For voice guidance to function while the app is in the background, add the audio background mode
/// to your `Info.plist`:
///
/// ```xml
/// <key>UIBackgroundModes</key>
/// <array>
///     <string>audio</string>
/// </array>
/// ```
///
/// The controller will assert if this configuration is missing in debug builds.
@MainActor
public final class RouteVoiceController {
    /// The speech synthesizer instance used for voice guidance.
    ///
    /// This property provides access to the underlying speech synthesizer for monitoring or configuration.
    /// See ``SpeechSynthesizing`` protocol for available properties and methods.
    public internal(set) var speechSynthesizer: SpeechSynthesizing
    var subscriptions: Set<AnyCancellable> = []

    /// Controls whether a sound plays when the user is rerouted.
    ///
    /// The reroute sound respects the synthesizer's mute setting and will not play if
    /// ``SpeechSynthesizing/muted`` is `true`.
    ///
    /// Default value is `true`.
    public var playsRerouteSound: Bool = true

    /// Creates a new `RouteVoiceController` instance.
    ///
    /// The initializer sets up subscriptions to route progress and reroute events, configures
    /// the speech synthesizer, and verifies that background audio is properly configured.
    ///
    /// - Parameters:
    ///   - routeProgressing: A publisher that emits route progress updates. The controller uses
    ///     these updates to determine when to speak navigation instructions.
    ///   - rerouteSoundTrigger: A publisher that emits events when the reroute sound should be played.
    ///     Typically triggered when rerouting begins or a faster route is set.
    ///   - speechSynthesizer: The speech synthesizer to use for voice guidance. Must conform to
    ///     ``SpeechSynthesizing`` protocol.
    ///
    /// - Important: The application's `Info.plist` must include `"audio"` in `UIBackgroundModes`
    ///   for spoken instructions to work while the app is in the background. An assertion will
    ///   fail in debug builds if this configuration is missing.
    public init(
        routeProgressing: AnyPublisher<RouteProgressState?, Never>,
        rerouteSoundTrigger: AnyPublisher<Void, Never>,
        speechSynthesizer: SpeechSynthesizing
    ) {
        self.speechSynthesizer = speechSynthesizer
        loadSounds()

        routeProgressing
            .sink { [weak self] state in
                self?.handle(routeProgressState: state)
            }
            .store(in: &subscriptions)

        rerouteSoundTrigger
            .sink { [weak self] in
                Task { [weak self] in
                    await self?.playReroutingSound()
                }
            }
            .store(in: &subscriptions)

        verifyBackgroundAudio()
    }

    /// Creates a new `RouteVoiceController` instance with separate reroute event publishers.
    ///
    /// - Parameters:
    ///   - routeProgressing: A publisher that emits route progress updates.
    ///   - rerouteStarted: A publisher that emits when rerouting starts.
    ///   - fasterRouteSet: A publisher that emits when a faster route is set.
    ///   - speechSynthesizer: The speech synthesizer to use for voice guidance.
    ///
    /// This convenience initializer merges the `rerouteStarted` and `fasterRouteSet` publishers
    /// into a single reroute sound trigger.
    @available(*, deprecated, message: "Use init(routeProgressing:rerouteSoundTrigger:speechSynthesizer:) instead.")
    public convenience init(
        routeProgressing: AnyPublisher<RouteProgressState?, Never>,
        rerouteStarted: AnyPublisher<Void, Never>,
        fasterRouteSet: AnyPublisher<Void, Never>,
        speechSynthesizer: SpeechSynthesizing
    ) {
        self.init(
            routeProgressing: routeProgressing,
            rerouteSoundTrigger: Publishers.Merge(rerouteStarted, fasterRouteSet).eraseToAnyPublisher(),
            speechSynthesizer: speechSynthesizer
        )
    }

    private func verifyBackgroundAudio() {
        Task {
            guard UIApplication.shared.isKind(of: UIApplication.self) else {
                return
            }

            if !Bundle.main.backgroundModes.contains("audio") {
                assertionFailure(
                    "This application’s Info.plist file must include “audio” in UIBackgroundModes. This background mode is used for spoken instructions while the application is in the background."
                )
            }
        }
    }

    private func handle(routeProgressState: RouteProgressState?) {
        guard let routeProgress = routeProgressState?.routeProgress,
              let spokenInstruction = routeProgressState?.routeProgress.currentLegProgress.currentStepProgress
                  .currentSpokenInstruction
        else {
            return
        }

        // AVAudioPlayer is flacky on simulator as of iOS 17.1, this is a workaround for UI tests
        guard ProcessInfo.processInfo.environment["isUITest"] == nil else { return }

        let locale = routeProgress.route.speechLocale

        let fallbackRequestedLocale = routeProgress.navigationRoutes.mainRoute.directionOptions.locale
        speechSynthesizer.locale = fallbackRequestedLocale

        var remainingSpokenInstructions = routeProgressState?.routeProgress.currentLegProgress.currentStepProgress
            .remainingSpokenInstructions ?? []
        let nextStepInstructions = routeProgressState?.routeProgress.upcomingLeg?.steps.first?
            .instructionsSpokenAlongStep
        remainingSpokenInstructions.append(contentsOf: nextStepInstructions ?? [])
        if !remainingSpokenInstructions.isEmpty {
            speechSynthesizer.prepareIncomingSpokenInstructions(
                remainingSpokenInstructions,
                locale: locale
            )
        }

        speechSynthesizer.speak(
            spokenInstruction,
            during: routeProgress.currentLegProgress,
            locale: locale
        )
    }

    private func playReroutingSound() async {
        guard playsRerouteSound, !speechSynthesizer.muted else {
            return
        }

        speechSynthesizer.stopSpeaking()

        guard let rerouteSoundUrl = Bundle.mapboxNavigationUXCore.rerouteSoundUrl else {
            return
        }

        Log.debug("RouteVoiceController: Will play reroute sound", category: .audio)
        do {
            try await AVAudioSessionHelper.shared.duckAudio()
        } catch {
            Log.error("RouteVoiceController: Failed to Activate AVAudioSession, error: \(error)", category: .audio)
        }

        do {
            let successful = try await Environment.shared.audioPlayerClient.play(rerouteSoundUrl)
            if !successful {
                Log.error("RouteVoiceController: Failed to play sound for reroute", category: .audio)
            }
        } catch {
            Log.error("RouteVoiceController: Failed to play sound for reroute with error: \(error)", category: .audio)
        }

        await AVAudioSessionHelper.shared.deferredUnduckAudio()
    }

    private func loadSounds() {
        Task {
            do {
                guard let rerouteSoundUrl = Bundle.mapboxNavigationUXCore.rerouteSoundUrl else { return }
                try await Environment.shared.audioPlayerClient.load([rerouteSoundUrl])
            } catch {
                Log.error("RouteVoiceController: Failed to load sound for reroute", category: .navigation)
            }
        }
    }
}

extension Bundle {
    fileprivate var rerouteSoundUrl: URL? {
        guard let rerouteSoundUrl = url(
            forResource: "reroute-sound",
            withExtension: "pcm"
        ) else {
            Log.error("Failed to find audio file for reroute", category: .navigation)
            return nil
        }

        return rerouteSoundUrl
    }
}
