import _MapboxNavigationHelpers
import AVFoundation
import MapboxNavigationNative
import UIKit

protocol AudioSessionInfoProvider {
    var outputVolume: Float { get }
    var telemetryAudioType: AudioType { get }
}

final class EventsMetadataProvider: EventsMetadataInterface, Sendable {
    let _userInfo: UnfairLocked<[String: String?]?>
    var userInfo: [String: String?]? {
        get {
            _userInfo.read()
        }
        set {
            _userInfo.update(newValue)
        }
    }

    private let screen: UIScreen
    private let audioSessionInfoProvider: UnfairLocked<AudioSessionInfoProvider>
    private let device: UIDevice
    private let connectivityTypeProvider: UnfairLocked<ConnectivityTypeProvider>
    private let appState: EventAppState

    @MainActor
    init(
        appState: EventAppState,
        screen: UIScreen,
        audioSessionInfoProvider: AudioSessionInfoProvider = AVAudioSession.sharedInstance(),
        device: UIDevice,
        connectivityTypeProvider: ConnectivityTypeProvider = MonitorConnectivityTypeProvider()
    ) {
        self.appState = appState
        self.screen = screen
        self.audioSessionInfoProvider = .init(audioSessionInfoProvider)
        self.device = device
        self.connectivityTypeProvider = .init(connectivityTypeProvider)
        self._userInfo = .init(nil)

        device.isBatteryMonitoringEnabled = true

        self.batteryLevel = .init(Self.currentBatteryLevel(with: device))
        self.batteryPluggedIn = .init(Self.currentBatteryPluggedIn(with: device))
        self.screenBrightness = .init(Int(screen.brightness * 100))

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
            self,
            selector: #selector(batteryLevelDidChange),
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(batteryStateDidChange),
            name: UIDevice.batteryStateDidChangeNotification,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(brightnessDidChange),
            name: UIScreen.brightnessDidChangeNotification,
            object: nil
        )
    }

    private var appMetadata: AppMetadata? {
        guard let userInfo,
              let appName = userInfo["name"] as? String,
              let appVersion = userInfo["version"] as? String else { return nil }

        return AppMetadata(
            name: appName,
            version: appVersion,
            userId: userInfo["userId"] as? String,
            sessionId: userInfo["sessionId"] as? String
        )
    }

    private let screenBrightness: UnfairLocked<Int>
    private var volumeLevel: Int { Int(audioSessionInfoProvider.read().outputVolume * 100) }
    private var audioType: AudioType { audioSessionInfoProvider.read().telemetryAudioType }

    private let batteryPluggedIn: UnfairLocked<Bool>
    private let batteryLevel: UnfairLocked<Int?>
    private var connectivity: String { connectivityTypeProvider.read().connectivityType }

    func provideEventsMetadata() -> EventsMetadata {
        return EventsMetadata(
            volumeLevel: volumeLevel as NSNumber,
            audioType: audioType.rawValue as NSNumber,
            screenBrightness: screenBrightness.read() as NSNumber,
            percentTimeInForeground: appState.percentTimeInForeground as NSNumber,
            percentTimeInPortrait: appState.percentTimeInPortrait as NSNumber,
            batteryPluggedIn: batteryPluggedIn.read() as NSNumber,
            batteryLevel: batteryLevel.read() as NSNumber?,
            connectivity: connectivity,
            appMetadata: appMetadata
        )
    }

    @objc
    private func batteryLevelDidChange() {
        let newValue = Self.currentBatteryLevel(with: device)
        batteryLevel.update(newValue)
    }

    private static func currentBatteryLevel(with device: UIDevice) -> Int? {
        device.batteryLevel >= 0 ? Int(device.batteryLevel * 100) : nil
    }

    @objc
    private func batteryStateDidChange() {
        let newValue = Self.currentBatteryPluggedIn(with: device)
        batteryPluggedIn.update(newValue)
    }

    private static let chargingStates: [UIDevice.BatteryState] = [.charging, .full]

    private static func currentBatteryPluggedIn(with device: UIDevice) -> Bool {
        chargingStates.contains(device.batteryState)
    }

    @objc
    private func brightnessDidChange() {
        screenBrightness.update(Int(screen.brightness * 100))
    }
}

extension AVAudioSession: AudioSessionInfoProvider {
    var telemetryAudioType: AudioType {
        if currentRoute.outputs
            .contains(where: { [.bluetoothA2DP, .bluetoothHFP, .bluetoothLE].contains($0.portType) })
        {
            return .bluetooth
        }
        if currentRoute.outputs
            .contains(where: { [.headphones, .airPlay, .HDMI, .lineOut, .carAudio, .usbAudio].contains($0.portType) })
        {
            return .headphones
        }
        if currentRoute.outputs.contains(where: { [.builtInSpeaker, .builtInReceiver].contains($0.portType) }) {
            return .speaker
        }
        return .unknown
    }
}

private final class BlockingOperation<T: Sendable>: @unchecked Sendable {
    private var result: Result<T, Never>?

    func run(_ operation: @Sendable @escaping () async -> T) -> T? {
        Task {
            let task = Task(operation: operation)
            self.result = await task.result
        }
        DispatchQueue.global().sync {
            while result == nil {
                RunLoop.current.run(mode: .default, before: .distantFuture)
            }
        }
        switch result {
        case .success(let value):
            return value
        case .none:
            assertionFailure("Running blocking operation did not receive a value.")
            return nil
        }
    }
}

extension EventsMetadata: @unchecked Sendable {}
extension ScreenshotFormat: @unchecked Sendable {}
