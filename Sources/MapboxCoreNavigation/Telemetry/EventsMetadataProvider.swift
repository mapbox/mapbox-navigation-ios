import UIKit
import AVFoundation
import MapboxNavigationNative

protocol AudioSessionInfoProvider {
    var outputVolume: Float { get }
    var telemetryAudioType: AudioType { get }
}

final class EventsMetadataProvider: EventsMetadataInterface {
    var userInfo: [String: String?]?

    private let screen: UIScreen
    private let audioSessionInfoProvider: AudioSessionInfoProvider
    private let device: UIDevice
    private let connectivityTypeProvider: ConnectivityTypeProvider

    private var appState: EventAppState

    init(appState: EventAppState,
         screen: UIScreen = .main,
         audioSessionInfoProvider: AudioSessionInfoProvider = AVAudioSession.sharedInstance(),
         device: UIDevice = UIDevice.current,
         connectivityTypeProvider: ConnectivityTypeProvider = MonitorConnectivityTypeProvider()) {
        self.appState = appState
        self.screen = screen
        self.audioSessionInfoProvider = audioSessionInfoProvider
        self.device = device
        self.connectivityTypeProvider = connectivityTypeProvider
    }

    private var appMetadata: AppMetadata? {
        guard let userInfo = userInfo,
              let appName = userInfo["name"] as? String,
              let appVersion = userInfo["version"] as? String else { return nil }

        return AppMetadata(name: appName,
                           version: appVersion,
                           userId: userInfo["userId"] as? String,
                           sessionId: userInfo["sessionId"] as? String)
    }

    private var screenBrightness: Int { Int(screen.brightness * 100) }
    private var volumeLevel: Int { Int(audioSessionInfoProvider.outputVolume * 100) }
    private var audioType: AudioType { audioSessionInfoProvider.telemetryAudioType }
    private var batteryPluggedIn: Bool { [.charging, .full].contains(device.batteryState) }
    private var batteryLevel: Int? { device.batteryLevel >= 0 ? Int(device.batteryLevel * 100) : nil }
    private var connectivity: String { connectivityTypeProvider.connectivityType }

    func provideEventsMetadata() -> EventsMetadata {
        return .init(volumeLevel: volumeLevel as NSNumber,
                     audioType: audioType.rawValue as NSNumber,
                     screenBrightness: screenBrightness as NSNumber,
                     percentTimeInForeground: appState.percentTimeInForeground as NSNumber,
                     percentTimeInPortrait: appState.percentTimeInPortrait as NSNumber,
                     batteryPluggedIn: batteryPluggedIn as NSNumber,
                     batteryLevel: batteryLevel as NSNumber?,
                     connectivity: connectivity,
                     appMetadata: appMetadata)
    }

    func screenshot() -> ScreenshotFormat? {
        captureScreen(scaledToFit: 250)
            .flatMap { $0.jpegData(compressionQuality: 0.2) }
            .map { ScreenshotFormat(jpeg: .init(data: $0), base64: nil) }
    }
}

extension AVAudioSession: AudioSessionInfoProvider {
    var telemetryAudioType: AudioType {
        if currentRoute.outputs.contains(where: { [.bluetoothA2DP, .bluetoothHFP, .bluetoothLE].contains($0.portType) }) {
            return .bluetooth
        }
        if currentRoute.outputs.contains(where: { [.headphones, .airPlay, .HDMI, .lineOut, .carAudio, .usbAudio].contains($0.portType) }) {
            return .headphones
        }
        if currentRoute.outputs.contains(where: { [.builtInSpeaker, .builtInReceiver].contains($0.portType) }) {
            return .speaker
        }
        return .unknown
    }
}
