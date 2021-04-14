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
    
    private enum CodingKeys: String, CodingKey {
        case event
        case created
        case sessionIdentifier = "sessionId"
        case counters
        case attributes
    }
    
    struct Counter: Encodable {
        let name: String
        let value: Double
    }
    
    struct Attribute: Encodable {
        let name: String
        let value: String
    }
    
    init(event: String, session: SessionState, createdOn created: Date?) {
        self.event = event
        sessionIdentifier = session.identifier.uuidString
        self.created = created ?? Date()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(event, forKey: .event)
        try container.encode(created.ISO8601, forKey: .created)
        try container.encode(sessionIdentifier, forKey: .sessionIdentifier)
        try container.encode(counters, forKey: .counters)
        try container.encode(attributes, forKey: .attributes)
    }
}

protocol NavigationEventDetails: EventDetails {
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
    var screenshot: String? { get set }
    var feedbackType: FeedbackType? { get set }
    var description: String? { get set }
    var userIdentifier: String? { get set }
    var driverMode: String { get }
    var sessionIdentifier: String { get }
    var startTimestamp: Date? { get }
    var percentTimeInPortrait: Int { get set }
    var percentTimeInForeground: Int { get set }
    var totalTimeInForeground: TimeInterval { get set }
    var totalTimeInBackground: TimeInterval { get set }
}

extension NavigationEventDetails {
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
<<<<<<< HEAD
=======
        
        stepIndex = dataSource.routeProgress.currentLegProgress.stepIndex
        stepCount = dataSource.routeProgress.currentLeg.steps.count
        legIndex = dataSource.routeProgress.legIndex
        legCount = dataSource.routeProgress.route.legs.count
        totalStepCount = dataSource.routeProgress.route.legs.map { $0.steps.count }.reduce(0, +)
    }
    
    private enum CodingKeys: String, CodingKey {
        case originalRequestIdentifier
        case requestIdentifier
        case latitude = "lat"
        case longitude = "lng"
        case originalGeometry
        case originalDistance
        case originalEstimatedDuration
        case originalStepCount
        case geometry
        case distance
        case estimatedDuration
        case created
        case startTimestamp
        case sdkIdentifier
        case sdkVersion
        case profile
        case platform
        case operatingSystem
        case device
        case simulation
        case sessionIdentifier
        case distanceCompleted
        case distanceRemaining
        case durationRemaining
        case rerouteCount
        case volumeLevel
        case audioType
        case screenBrightness
        case batteryPluggedIn
        case batteryLevel
        case applicationState
        case userAbsoluteDistanceToDestination
        case locationEngine
        case percentTimeInPortrait
        case percentTimeInForeground
        case locationManagerDesiredAccuracy
        case stepIndex
        case stepCount
        case legIndex
        case legCount
        case totalStepCount
        case event
        case arrivalTimestamp
        case rating
        case comment
        case userId
        case name
        case version
        case feedbackType
        case description
        case screenshot
        case secondsSinceLastReroute
        case newDistanceRemaining
        case newDurationRemaining
        case newGeometry
        case routeLegProgress = "step"
        case totalTimeInForeground
        case totalTimeInBackground
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(originalRequestIdentifier, forKey: .originalRequestIdentifier)
        try container.encodeIfPresent(requestIdentifier, forKey: .requestIdentifier)
        try container.encodeIfPresent(coordinate?.latitude, forKey: .latitude)
        try container.encodeIfPresent(coordinate?.longitude, forKey: .longitude)
        try container.encodeIfPresent(originalGeometry?.encodedPolyline, forKey: .originalGeometry)
        try container.encodeIfPresent(originalDistance, forKey: .originalDistance)
        try container.encodeIfPresent(originalEstimatedDuration, forKey: .originalEstimatedDuration)
        try container.encodeIfPresent(geometry?.encodedPolyline, forKey: .geometry)
        try container.encodeIfPresent(distance, forKey: .distance)
        try container.encodeIfPresent(estimatedDuration, forKey: .estimatedDuration)
        try container.encode(created.ISO8601, forKey: .created)
        try container.encodeIfPresent(startTimestamp?.ISO8601, forKey: .startTimestamp)
        try container.encode(sdkIdentifier, forKey: .sdkIdentifier)
        try container.encode(sdkVersion, forKey: .sdkVersion)
        try container.encode(profile, forKey: .profile)
        try container.encode(platform, forKey: .platform)
        try container.encode(operatingSystem, forKey: .operatingSystem)
        try container.encode(device, forKey: .device)
        try container.encode(simulation, forKey: .simulation)
        try container.encode(sessionIdentifier, forKey: .sessionIdentifier)
        try container.encode(distanceCompleted, forKey: .distanceCompleted)
        try container.encode(distanceRemaining, forKey: .distanceRemaining)
        try container.encode(durationRemaining, forKey: .durationRemaining)
        try container.encode(rerouteCount, forKey: .rerouteCount)
        try container.encode(volumeLevel, forKey: .volumeLevel)
        try container.encode(audioType, forKey: .audioType)
        try container.encode(screenBrightness, forKey: .screenBrightness)
        try container.encode(batteryPluggedIn, forKey: .batteryPluggedIn)
        try container.encode(batteryLevel, forKey: .batteryLevel)
        try container.encode(applicationState, forKey: .applicationState)
        try container.encodeIfPresent(userAbsoluteDistanceToDestination, forKey: .userAbsoluteDistanceToDestination)
        try container.encodeIfPresent(locationEngine, forKey: .locationEngine)
        try container.encode(percentTimeInPortrait, forKey: .percentTimeInPortrait)
        try container.encode(percentTimeInForeground, forKey: .percentTimeInForeground)
        try container.encodeIfPresent(locationManagerDesiredAccuracy, forKey: .locationManagerDesiredAccuracy)
        try container.encode(stepIndex, forKey: .stepIndex)
        try container.encode(stepCount, forKey: .stepCount)
        try container.encode(legIndex, forKey: .legIndex)
        try container.encode(legCount, forKey: .legCount)
        try container.encode(totalStepCount, forKey: .totalStepCount)
        try container.encodeIfPresent(event, forKey: .event)
        try container.encodeIfPresent(arrivalTimestamp?.ISO8601, forKey: .arrivalTimestamp)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(version, forKey: .version)
        try container.encodeIfPresent(feedbackType, forKey: .feedbackType)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(screenshot, forKey: .screenshot)
        try container.encodeIfPresent(secondsSinceLastReroute, forKey: .secondsSinceLastReroute)
        try container.encodeIfPresent(newDistanceRemaining, forKey: .newDistanceRemaining)
        try container.encodeIfPresent(newDurationRemaining, forKey: .newDurationRemaining)
        try container.encode(totalTimeInForeground, forKey: .totalTimeInForeground)
        try container.encode(totalTimeInBackground, forKey: .totalTimeInBackground)
        try container.encodeIfPresent(rating, forKey: .rating)
>>>>>>> fa680e52a... add metadata properties
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
