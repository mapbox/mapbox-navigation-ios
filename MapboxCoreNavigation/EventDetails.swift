import Foundation
import CoreLocation
import Polyline
import UIKit
import AVFoundation
import MapboxDirections

protocol EventDetails: Encodable {
    var event: String? { get }
    var created: Date { get }
    var sessionIdentifier: String { get }
}

struct PerformanceEventDetails: EventDetails {
    let event: String?
    let created: Date
    let sessionIdentifier: String
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
    
    init(event: String?, session: SessionState, createdOn created: Date?) {
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

struct NavigationEventDetails: EventDetails {
    
    let audioType: String = AVAudioSession.sharedInstance().audioType
    let applicationState = UIApplication.shared.applicationState
    let batteryLevel: Int = UIDevice.current.batteryLevel >= 0 ? Int(UIDevice.current.batteryLevel * 100) : -1
    let batteryPluggedIn: Bool = [.charging, .full].contains(UIDevice.current.batteryState)
    let coordinate: CLLocationCoordinate2D?
    let device: String = UIDevice.current.machine
    let distance: CLLocationDistance?
    let distanceCompleted: CLLocationDistance
    let distanceRemaining: TimeInterval
    let durationRemaining: TimeInterval
    let estimatedDuration: TimeInterval?
    let geometry: Polyline?
    let locationEngine: String?
    let locationManagerDesiredAccuracy: CLLocationAccuracy?
    let operatingSystem: String = "\(ProcessInfo.systemName) \(ProcessInfo.systemVersion)"
    let originalDistance: CLLocationDistance?
    let originalEstimatedDuration: TimeInterval?
    let originalGeometry: Polyline?
    let originalRequestIdentifier: String?
    let originalStepCount: Int?
    let profile: String
    let platform: String = ProcessInfo.systemName
    let percentTimeInPortrait: Int
    let percentTimeInForeground: Int
    let requestIdentifier: String?
    let rerouteCount: Int
    let screenBrightness: Int = Int(UIScreen.main.brightness * 100)
    let sessionIdentifier: String
    let simulation: Bool
    let startTimestamp: Date?
    let sdkIdentifier: String
    let sdkVersion: String = String(describing: Bundle.mapboxCoreNavigation.object(forInfoDictionaryKey: "CFBundleShortVersionString")!)
    let userAbsoluteDistanceToDestination: CLLocationDistance?
    let volumeLevel: Int = Int(AVAudioSession.sharedInstance().outputVolume * 100)
    
    let stepIndex: Int
    let stepCount: Int
    let legIndex: Int
    let legCount: Int
    let totalStepCount: Int
    
    var created: Date = Date()
    var event: String?
    var arrivalTimestamp: Date?
    var rating: Int?
    var comment: String?
    var userId: String?
    var feedbackType: String?
    var description: String?
    var screenshot: String?
    var secondsSinceLastReroute: TimeInterval?
    var newDistanceRemaining: CLLocationDistance?
    var newDurationRemaining: TimeInterval?
    var newGeometry: String?
    
    init(dataSource: EventsManagerDataSource, session: SessionState, defaultInterface: Bool) {
        coordinate = dataSource.router.rawLocation?.coordinate
        startTimestamp = session.departureTimestamp ?? nil
        sdkIdentifier = defaultInterface ? "mapbox-navigation-ui-ios" : "mapbox-navigation-ios"
        profile = dataSource.routeProgress.route.routeOptions.profileIdentifier.rawValue
        simulation = dataSource.locationProvider is SimulatedLocationManager.Type
        
        sessionIdentifier = session.identifier.uuidString
        originalRequestIdentifier = session.originalRoute.routeIdentifier
        requestIdentifier = dataSource.routeProgress.route.routeIdentifier
                
        if let location = dataSource.router.rawLocation,
           let coordinates = dataSource.routeProgress.route.coordinates,
           let lastCoord = coordinates.last {
            userAbsoluteDistanceToDestination = location.distance(from: CLLocation(latitude: lastCoord.latitude, longitude: lastCoord.longitude))
        } else {
            userAbsoluteDistanceToDestination = nil
        }
        
        if let geometry = session.originalRoute.coordinates {
            originalGeometry = Polyline(coordinates: geometry)
            originalDistance = round(session.originalRoute.distance)
            originalEstimatedDuration = round(session.originalRoute.expectedTravelTime)
            originalStepCount = session.originalRoute.legs.map({$0.steps.count}).reduce(0, +)
        } else {
            originalGeometry = nil
            originalDistance = nil
            originalEstimatedDuration = nil
            originalStepCount = nil
        }
        
        if let geometry = session.currentRoute.coordinates {
            self.geometry = Polyline(coordinates: geometry)
            distance = round(session.currentRoute.distance)
            estimatedDuration = round(session.currentRoute.expectedTravelTime)
        } else {
            self.geometry = nil
            distance = nil
            estimatedDuration = nil
        }
        
        distanceCompleted = round(session.totalDistanceCompleted + dataSource.routeProgress.distanceTraveled)
        distanceRemaining = round(dataSource.routeProgress.distanceRemaining)
        durationRemaining = round(dataSource.routeProgress.durationRemaining)
        
        rerouteCount = session.numberOfReroutes
        
        locationEngine = String(describing: dataSource.locationProvider)
        locationManagerDesiredAccuracy = dataSource.desiredAccuracy
        
        
        var totalTimeInPortrait = session.timeSpentInPortrait
        var totalTimeInLandscape = session.timeSpentInLandscape
        if UIDevice.current.orientation.isPortrait {
            totalTimeInPortrait += abs(session.lastTimeInPortrait.timeIntervalSinceNow)
        } else if UIDevice.current.orientation.isLandscape {
            totalTimeInLandscape += abs(session.lastTimeInLandscape.timeIntervalSinceNow)
        }
        percentTimeInPortrait = totalTimeInPortrait + totalTimeInLandscape == 0 ? 100 : Int((totalTimeInPortrait / (totalTimeInPortrait + totalTimeInLandscape)) * 100)
        
        var totalTimeInForeground = session.timeSpentInForeground
        var totalTimeInBackground = session.timeSpentInBackground
        if UIApplication.shared.applicationState == .active {
            totalTimeInForeground += abs(session.lastTimeInForeground.timeIntervalSinceNow)
        } else {
            totalTimeInBackground += abs(session.lastTimeInBackground.timeIntervalSinceNow)
        }
        percentTimeInForeground = totalTimeInPortrait + totalTimeInLandscape == 0 ? 100 : Int((totalTimeInPortrait / (totalTimeInPortrait + totalTimeInLandscape) * 100))
        
        
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
        case feedbackType
        case description
        case screenshot
        case secondsSinceLastReroute
        case newDistanceRemaining
        case newDurationRemaining
        case newGeometry
        case routeLegProgress = "step"
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
        try container.encodeIfPresent(feedbackType, forKey: .feedbackType)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(screenshot, forKey: .screenshot)
        try container.encodeIfPresent(secondsSinceLastReroute, forKey: .secondsSinceLastReroute)
        try container.encodeIfPresent(newDistanceRemaining, forKey: .newDistanceRemaining)
        try container.encodeIfPresent(newDurationRemaining, forKey: .newDurationRemaining)
    }
}

extension RouteLegProgress: Encodable {
    
    private enum CodingKeys: String, CodingKey {
        case upcomingInstruction
        case upcomingType
        case upcomingModifier
        case upcomingName
        case previousInstruction
        case previousType
        case previousModifier
        case previousName
        case distance
        case duration
        case distanceRemaining
        case durationRemaining
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(upcomingStep?.instructions, forKey: .upcomingInstruction)
        try container.encodeIfPresent(upcomingStep?.maneuverType.description, forKey: .upcomingType)
        try container.encodeIfPresent(upcomingStep?.maneuverDirection.description, forKey: .upcomingModifier)
        try container.encodeIfPresent(upcomingStep?.names?.joined(separator: ";"), forKey: .upcomingName)
        try container.encodeIfPresent(currentStep.instructions, forKey: .previousInstruction)
        try container.encode(currentStep.maneuverType.description, forKey: .previousType)
        try container.encode(currentStep.maneuverDirection.description, forKey: .previousModifier)
        try container.encode(currentStep.names?.joined(separator: ";"), forKey: .previousName)
        try container.encode(Int(currentStep.distance), forKey: .distance)
        try container.encode(Int(currentStep.expectedTravelTime), forKey: .duration)
        try container.encode(Int(currentStepProgress.distanceRemaining), forKey: .distanceRemaining)
        try container.encode(Int(currentStepProgress.durationRemaining), forKey: .durationRemaining)
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
