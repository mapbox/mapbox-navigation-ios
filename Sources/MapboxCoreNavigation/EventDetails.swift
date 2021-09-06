import Foundation
import CoreLocation
import Polyline
import UIKit
import AVFoundation
import MapboxDirections
import MapboxMobileEvents

protocol EventDetails: Encodable {
    var event: String? { get set }
    var created: Date { get }
    var sessionIdentifier: String { get }
}

struct PerformanceEventDetails: EventDetails {
    let created: Date
    let sessionIdentifier: String
    var event: String?
    var counters: [Counter] = []
    var attributes: [Attribute] = []
    var appMetadata: [String: String?]?
    
    private enum CodingKeys: String, CodingKey {
        case event
        case created
        case sessionIdentifier = "sessionId"
        case counters
        case attributes
        case appMetadata
    }
    
    struct Counter: Encodable {
        let name: String
        let value: Double
    }
    
    struct Attribute: Encodable {
        let name: String
        let value: String
    }
    
    init(event: String, session: SessionState, createdOn created: Date?, appMetadata: [String:String?]? = nil) {
        self.event = event
        sessionIdentifier = session.identifier.uuidString
        self.created = created ?? Date()
        self.appMetadata = appMetadata
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(event, forKey: .event)
        try container.encode(created.ISO8601, forKey: .created)
        try container.encode(sessionIdentifier, forKey: .sessionIdentifier)
        try container.encode(counters, forKey: .counters)
        try container.encode(attributes, forKey: .attributes)
        try container.encode(appMetadata, forKey: .appMetadata)
    }
}

protocol GlobalEventDetails: EventDetails {
    var audioType: String { get }
    var applicationState: UIApplication.State { get }
    var batteryLevel: Int { get }
    var batteryPluggedIn: Bool { get }
    var device: String { get }
    var operatingSystem: String { get }
    var platform: String { get }
    var sdkVersion: String { get }
    var screenBrightness: Int { get }
    var volumeLevel: Int { get }
    var percentTimeInPortrait: Int { get set }
    var percentTimeInForeground: Int { get set }
    var totalTimeInForeground: TimeInterval { get set }
    var totalTimeInBackground: TimeInterval { get set }
}

protocol NavigationEventDetails: GlobalEventDetails {
    var screenshot: String? { get set }
    var feedbackType: ActiveNavigationFeedbackType? { get set }
    var description: String? { get set }
    var userIdentifier: String? { get set }
    var appMetadata: [String:String?]? { get set }
    var driverMode: String { get }
    var sessionIdentifier: String { get }
    var startTimestamp: Date? { get }
}

extension GlobalEventDetails {
    var audioType: String { AVAudioSession.sharedInstance().audioType }
    var applicationState: UIApplication.State {
        if Thread.isMainThread {
            return UIApplication.shared.applicationState
        } else {
            return DispatchQueue.main.sync { UIApplication.shared.applicationState }
        }
    }
    var batteryLevel: Int { UIDevice.current.batteryLevel >= 0 ? Int(UIDevice.current.batteryLevel * 100) : -1 }
    var batteryPluggedIn: Bool { [.charging, .full].contains(UIDevice.current.batteryState) }
    var device: String { UIDevice.current.machine }
    var operatingSystem: String { "\(ProcessInfo.systemName) \(ProcessInfo.systemVersion)" }
    var platform: String { ProcessInfo.systemName }
    var sdkVersion: String {
        guard let stringForShortVersion = Bundle.string(forMapboxCoreNavigationInfoDictionaryKey: "CFBundleShortVersionString") else {
            preconditionFailure("CFBundleShortVersionString must be set in the Info.plist.")
        }
        return stringForShortVersion
    }
    var screenBrightness: Int { Int(UIScreen.main.brightness * 100) }
    var volumeLevel: Int { Int(AVAudioSession.sharedInstance().outputVolume * 100) }

    mutating func updateTimeState(session: SessionState) {
        var totalTimeInPortrait = session.timeSpentInPortrait
        var totalTimeInLandscape = session.timeSpentInLandscape
        if UIDevice.current.orientation.isPortrait {
            totalTimeInPortrait += abs(session.lastTimeInPortrait.timeIntervalSinceNow)
        } else if UIDevice.current.orientation.isLandscape {
            totalTimeInLandscape += abs(session.lastTimeInLandscape.timeIntervalSinceNow)
        }
        percentTimeInPortrait = totalTimeInPortrait + totalTimeInLandscape == 0 ? 100 : Int((totalTimeInPortrait / (totalTimeInPortrait + totalTimeInLandscape)) * 100)
        
        totalTimeInForeground = session.timeSpentInForeground
        totalTimeInBackground = session.timeSpentInBackground
        if applicationState == .active {
            totalTimeInForeground += abs(session.lastTimeInForeground.timeIntervalSinceNow)
        } else {
            totalTimeInBackground += abs(session.lastTimeInBackground.timeIntervalSinceNow)
        }
        percentTimeInForeground = totalTimeInPortrait + totalTimeInLandscape == 0 ? 100 : Int((totalTimeInPortrait / (totalTimeInPortrait + totalTimeInLandscape) * 100))
    }
}

enum EventDetailsError: Error {
    case EncodingError(String)
}

extension EventDetails {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        if let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
            return dictionary
        } else {
            throw EventDetailsError.EncodingError("Failed to encode event details")
        }
    }
}

extension UIApplication.State: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let stringRepresentation: String
        switch self {
        case .active:
            stringRepresentation = "Foreground"
        case .inactive:
            stringRepresentation = "Inactive"
        case .background:
            stringRepresentation = "Background"
        @unknown default:
            fatalError("Indescribable application state \(rawValue)")
        }
        try container.encode(stringRepresentation)
    }
}

extension AVAudioSession {
    var audioType: String {
        if currentRoute.outputs.contains(where: { [.bluetoothA2DP, .bluetoothHFP, .bluetoothLE].contains($0.portType) }) {
            return "bluetooth"
        }
        if currentRoute.outputs.contains(where: { [.headphones, .airPlay, .HDMI, .lineOut, .carAudio, .usbAudio].contains($0.portType) }) {
            return "headphones"
        }
        if currentRoute.outputs.contains(where: { [.builtInSpeaker, .builtInReceiver].contains($0.portType) }) {
            return "speaker"
        }
        return "unknown"
    }
}
