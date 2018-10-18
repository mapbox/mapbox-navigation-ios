import UIKit
import AVFoundation

protocol CarPlayEventRepresentable {
    var connectedTimeStamp: Date? { get set }
    var disconnectedTimeStamp: Date? { get set }
    var durationConnectedToCarPlay: TimeInterval? { get }
}

struct RoutelessEventDetails: Encodable, EventRepresentable, CarPlayEventRepresentable {
    
    var audioType: String = AVAudioSession.sharedInstance().audioType
    var applicationState: UIApplicationState = UIApplication.shared.applicationState
    var batteryLevel: Int = UIDevice.current.batteryLevel >= 0 ? Int(UIDevice.current.batteryLevel * 100) : -1
    var batteryPluggedIn: Bool = [.charging, .full].contains(UIDevice.current.batteryState)
    var created: Date = Date()
    var device: String
    var operatingSystem: String
    var originalRequestIdentifier: String?
    var profile: String
    var platform: String = ProcessInfo.systemName
    var percentTimeInPortrait: Int
    var percentTimeInForeground: Int
    var requestIdentifier: String?
    var screenBrightness: Int = Int(UIScreen.main.brightness * 100)
    var sessionIdentifier: String
    var simulation: Bool
    var sdkIdentifier: String
    var sdkVersion: String = String(describing: Bundle.mapboxCoreNavigation.object(forInfoDictionaryKey: "CFBundleShortVersionString")!)
    var volumeLevel: Int = Int(AVAudioSession.sharedInstance().outputVolume * 100)
    
    var event: String?
    var arrivalTimestamp: Date?
    var rating: Int?
    var comment: String?
    var userId: String?
    var feedbackType: String?
    var description: String?
    var screenshot: String?
    
    var connectedTimeStamp: Date?
    var disconnectedTimeStamp: Date?
    var durationConnectedToCarPlay: TimeInterval? {
        guard let startTime = connectedTimeStamp, let endTime = disconnectedTimeStamp else {
            return nil
        }
        return endTime.timeIntervalSince(startTime)
    }
    
    private enum CodingKeys: String, CodingKey {
        case audioType
        case applicationState
        case batteryLevel
        case batteryPluggedIn
        case created
        case device
        case operatingSystem
        case originalRequestIdentifier
        case profile
        case platform
        case percentTimeInPortrait
        case percentTimeInForeground
        case requestIdentifier
        case screenBrightness
        case sessionIdentifier
        case simulation
        case sdkIdentifier
        case sdkVersion
        case volumeLevel
        case event
        case arrivalTimestamp
        case rating
        case comment
        case userId
        case feedbackType
        case description
        case screenshot
        case connectedTimeStamp
        case disconnectedTimeStamp
        case durationConnectedToCarPlay
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(originalRequestIdentifier, forKey: .originalRequestIdentifier)
        try container.encodeIfPresent(requestIdentifier, forKey: .requestIdentifier)
        try container.encode(created.ISO8601, forKey: .created)
        try container.encode(sdkIdentifier, forKey: .sdkIdentifier)
        try container.encode(sdkVersion, forKey: .sdkVersion)
        try container.encode(profile, forKey: .profile)
        try container.encode(platform, forKey: .platform)
        try container.encode(operatingSystem, forKey: .operatingSystem)
        try container.encode(device, forKey: .device)
        try container.encode(simulation, forKey: .simulation)
        try container.encode(sessionIdentifier, forKey: .sessionIdentifier)
        try container.encode(volumeLevel, forKey: .volumeLevel)
        try container.encode(audioType, forKey: .audioType)
        try container.encode(screenBrightness, forKey: .screenBrightness)
        try container.encode(batteryPluggedIn, forKey: .batteryPluggedIn)
        try container.encode(batteryLevel, forKey: .batteryLevel)
        try container.encode(applicationState, forKey: .applicationState)
        try container.encode(percentTimeInPortrait, forKey: .percentTimeInPortrait)
        try container.encode(percentTimeInForeground, forKey: .percentTimeInForeground)
        try container.encodeIfPresent(event, forKey: .event)
        try container.encodeIfPresent(arrivalTimestamp?.ISO8601, forKey: .arrivalTimestamp)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(feedbackType, forKey: .feedbackType)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(screenshot, forKey: .screenshot)
        try container.encodeIfPresent(connectedTimeStamp, forKey: .connectedTimeStamp)
        try container.encodeIfPresent(disconnectedTimeStamp, forKey: .disconnectedTimeStamp)
        try container.encodeIfPresent(durationConnectedToCarPlay, forKey: .durationConnectedToCarPlay)
    }
}
