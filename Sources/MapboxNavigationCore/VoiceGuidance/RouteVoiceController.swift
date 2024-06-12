import AVFoundation
import Combine
import Foundation
import UIKit

@MainActor
public final class RouteVoiceController {
    public internal(set) var speechSynthesizer: SpeechSynthesizing
    var subscriptions: Set<AnyCancellable> = []

    /// If true, a noise indicating the user is going to be rerouted will play prior to rerouting.
    public var playsRerouteSound: Bool = true

    public init(
        routeProgressing: AnyPublisher<RouteProgressState?, Never>,
        rerouteStarted: AnyPublisher<Void, Never>,
        fasterRouteSet: AnyPublisher<Void, Never>,
        speechSynthesizer: SpeechSynthesizing
    ) {
        self.speechSynthesizer = speechSynthesizer
        loadSounds()

        routeProgressing
            .sink { [weak self] state in
                self?.handle(routeProgressState: state)
            }
            .store(in: &subscriptions)

        rerouteStarted
            .sink { [weak self] in
                Task { [weak self] in
                    await self?.playReroutingSound()
                }
            }
            .store(in: &subscriptions)

        fasterRouteSet
            .sink { [weak self] in
                Task { [weak self] in
                    await self?.playReroutingSound()
                }
            }
            .store(in: &subscriptions)

        verifyBackgroundAudio()
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

        speechSynthesizer.locale = locale
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

        if let error = AVAudioSession.sharedInstance().tryDuckAudio() {
            Log.error("Failed to duck sound for reroute with error: \(error)", category: .navigation)
        }

        defer {
            if let error = AVAudioSession.sharedInstance().tryUnduckAudio() {
                Log.error("Failed to unduck sound for reroute with error: \(error)", category: .navigation)
            }
        }

        do {
            let successful = try await Current.audioPlayerClient.play(rerouteSoundUrl)
            if !successful {
                Log.error("Failed to play sound for reroute", category: .navigation)
            }
        } catch {
            Log.error("Failed to play sound for reroute with error: \(error)", category: .navigation)
        }
    }

    private func loadSounds() {
        Task {
            do {
                guard let rerouteSoundUrl = Bundle.mapboxNavigationUXCore.rerouteSoundUrl else { return }
                try await Current.audioPlayerClient.load([rerouteSoundUrl])
            } catch {
                Log.error("Failed to load sound for reroute", category: .navigation)
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
