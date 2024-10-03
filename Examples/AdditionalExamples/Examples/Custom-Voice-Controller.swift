/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios
 To learn more about the SDK, see our docs: https://docs.mapbox.com/ios/navigation
 */

import AVFoundation
import Combine
import CoreLocation
import Foundation
import MapboxDirections
import MapboxNavigationCore
import MapboxNavigationUIKit
import UIKit

final class CustomVoiceControllerUI: UIViewController {
    private let mapboxNavigationProvider: MapboxNavigationProvider = {
        var coreConfig = CoreConfig(
            locationSource: simulationIsEnabled ? .simulation(
                initialLocation: .init(
                    latitude: 37.77440680146262,
                    longitude: -122.43539772352648
                )
            ) : .live
        )
        let provider = MapboxNavigationProvider(coreConfig: coreConfig)
        coreConfig.ttsConfig = .custom(
            speechSynthesizer:
            // `MultiplexedSpeechSynthesizer` will provide "a backup" functionality to cover cases, which
            // our custom implementation cannot handle.
            MultiplexedSpeechSynthesizer(
                mapboxSpeechApiConfiguration: coreConfig.credentials.speech,
                skuTokenProvider: provider.skuTokenProvider.skuToken,
                customSpeechSynthesizers: [CustomVoiceController()]
            )
        )
        provider.apply(coreConfig: coreConfig)
        return provider
    }()

    private var mapboxNavigation: MapboxNavigation {
        mapboxNavigationProvider.mapboxNavigation
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let origin = CLLocationCoordinate2DMake(37.77440680146262, -122.43539772352648)
        let destination = CLLocationCoordinate2DMake(37.76556957793795, -122.42409811526268)
        let routeOptions = NavigationRouteOptions(coordinates: [origin, destination])

        Task {
            switch await mapboxNavigation.routingProvider().calculateRoutes(options: routeOptions).result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let navigationRoutes):
                self.presentNavigationWithCustomVoiceController(navigationRoutes: navigationRoutes)
            }
        }
    }

    private func presentNavigationWithCustomVoiceController(navigationRoutes: NavigationRoutes) {
        let navigationOptions = NavigationOptions(
            mapboxNavigation: mapboxNavigation,
            voiceController: mapboxNavigationProvider.routeVoiceController,
            eventsManager: mapboxNavigationProvider.eventsManager()
        )
        let navigationViewController = NavigationViewController(
            navigationRoutes: navigationRoutes,
            navigationOptions: navigationOptions
        )
        navigationViewController.modalPresentationStyle = .fullScreen

        present(navigationViewController, animated: true, completion: nil)
    }
}

final class CustomVoiceController: NSObject, SpeechSynthesizing, AVAudioPlayerDelegate {
    private let _voiceInstructions: PassthroughSubject<VoiceInstructionEvent, Never> = .init()
    var voiceInstructions: AnyPublisher<VoiceInstructionEvent, Never> {
        _voiceInstructions.eraseToAnyPublisher()
    }

    // MARK: Speech Configuration

    var muted: Bool = false {
        didSet {
            if isSpeaking {
                interruptSpeaking()
            }
        }
    }

    var volume: VolumeMode = .system {
        didSet {
            switch volume {
            case .system:
                players.forEach {
                    $0?.volume = 1.0
                }
            case .override(let value):
                players.forEach {
                    $0?.volume = value
                }
            }
        }
    }

    var locale: Locale? = Locale.autoupdatingCurrent
    var isSpeaking: Bool {
        players.contains {
            $0?.isPlaying ?? false
        }
    }

    var managesAudioSession: Bool = true

    func prepareIncomingSpokenInstructions(_ instructions: [MapboxNavigationCore.SpokenInstruction], locale: Locale?) {
        // do nothing, we don't need to pre-load anything.
    }

    func stopSpeaking() {
        players.forEach {
            $0?.stop()
        }
    }

    func interruptSpeaking() {
        players.forEach {
            $0?.stop()
        }
    }

    // You will need audio files for as many or few cases as you'd like to handle
    // This example just covers left and right. All other cases will fail the Custom Voice Controller and
    // force a backup Speech to kick in.
    let turnLeftPlayer = try? AVAudioPlayer(data: NSDataAsset(name: "turnleft")!.data)
    let turnRightPlayer = try? AVAudioPlayer(data: NSDataAsset(name: "turnright")!.data)
    var players: [AVAudioPlayer?] {
        [turnLeftPlayer, turnRightPlayer]
    }

    var currentInstruction: SpokenInstruction? = nil

    override init() {
        super.init()

        players.forEach {
            $0?.delegate = self
        }
    }

    func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress, locale: Locale? = nil) {
        guard let nextStep = legProgress.upcomingStep,
              let player = audio(for: nextStep)
        else {
            // When `MultiplexedSpeechSynthesizer` receives an error from one of it's Speech Synthesizers,
            // it requests the next on the list
            _voiceInstructions.send(
                VoiceInstructionEvents.EncounteredError(
                    error: SpeechError.noData(
                        instruction: instruction,
                        options: .init(
                            text: instruction.text,
                            locale: locale ?? self.locale ?? .current
                        )
                    )
                )
            )
            return
        }
        _voiceInstructions.send(
            VoiceInstructionEvents.WillSpeak(
                instruction: instruction
            )
        )
        if let currentInstruction {
            interruptSpeaking()
            _voiceInstructions.send(
                VoiceInstructionEvents.DidInterrupt(
                    interruptedInstruction: currentInstruction,
                    interruptingInstruction: instruction
                )
            )
        }
        currentInstruction = instruction
        player.play()
    }

    func audio(for step: RouteStep) -> AVAudioPlayer? {
        switch step.maneuverDirection {
        case .left:
            return turnLeftPlayer
        case .right:
            return turnRightPlayer
        default:
            return nil // this will force report that Custom Voice Controller is unable to handle this case
        }
    }

    // MARK: AVAudioPlayerDelegate implementation

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if let currentInstruction {
            _voiceInstructions.send(
                VoiceInstructionEvents.DidSpeak(instruction: currentInstruction)
            )
        }
        currentInstruction = nil
    }
}
