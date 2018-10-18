import Foundation
import CoreLocation
import Polyline
import UIKit
import AVFoundation
import MapboxDirections

protocol EventRepresentable {
    // Properties shared between routeless and non-routeless event details.
    var event: String? { get set }
    var arrivalTimestamp: Date? { get set }
    var rating: Int? { get set }
    var comment: String? { get set }
    var userId: String? { get set }
    var feedbackType: String? { get set }
    var description: String? { get set }
    var screenshot: String? { get set }
    
    var audioType: String { get set }
    var applicationState: UIApplicationState { get set }
    var batteryLevel: Int { get set }
    var batteryPluggedIn: Bool { get set }
    var created: Date { get set }
    var device: String { get set }
    
    var operatingSystem: String { get set }
    var originalRequestIdentifier: String? { get set }
    var profile: String { get set }
    var platform: String { get set }
    var percentTimeInPortrait: Int { get set }
    var percentTimeInForeground: Int { get set }
    var requestIdentifier: String? { get set }
    var screenBrightness: Int { get set }
    var sessionIdentifier: String { get set }
    var simulation: Bool { get set }
    var sdkIdentifier: String { get set }
    var sdkVersion: String { get set }
    var volumeLevel: Int { get set }
}

struct EventDetails: Encodable, EventRepresentable, CarPlayEventRepresentable {
    var event: String?
    var arrivalTimestamp: Date?
    var rating: Int?
    var comment: String?
    var userId: String?
    var feedbackType: String?
    var description: String?
    var screenshot: String?
    
    var audioType: String = AVAudioSession.sharedInstance().audioType
    var applicationState: UIApplicationState = UIApplication.shared.applicationState
    var batteryLevel: Int = UIDevice.current.batteryLevel >= 0 ? Int(UIDevice.current.batteryLevel * 100) : -1
    var batteryPluggedIn: Bool = [.charging, .full].contains(UIDevice.current.batteryState)
    var created: Date = Date()
    var device: String = UIDevice.current.machine
    var operatingSystem: String = "\(ProcessInfo.systemName) \(ProcessInfo.systemVersion)"
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
    
    let coordinate: CLLocationCoordinate2D?
    let distance: CLLocationDistance?
    let distanceCompleted: CLLocationDistance
    let distanceRemaining: TimeInterval
    let durationRemaining: TimeInterval
    let estimatedDuration: TimeInterval?
    let geometry: Polyline?
    let locationEngine: String?
    let locationManagerDesiredAccuracy: CLLocationAccuracy?
    let originalDistance: CLLocationDistance?
    let originalEstimatedDuration: TimeInterval?
    let originalGeometry: Polyline?
    let originalStepCount: Int?
    let rerouteCount: Int
    let startTimestamp: Date?
    let userAbsoluteDistanceToDestination: CLLocationDistance?
    
    let stepIndex: Int
    let stepCount: Int
    let legIndex: Int
    let legCount: Int
    let totalStepCount: Int
    
    var secondsSinceLastReroute: TimeInterval?
    var newDistanceRemaining: CLLocationDistance?
    var newDurationRemaining: TimeInterval?
    var newGeometry: String?
    
    var connectedTimeStamp: Date?
    var disconnectedTimeStamp: Date?
    var durationConnectedToCarPlay: TimeInterval? {
        guard let startTime = connectedTimeStamp, let endTime = disconnectedTimeStamp else {
            return nil
        }
        return endTime.timeIntervalSince(startTime)
    }
    
    init(dataSource: EventsRouteDataSource, session: SessionState, defaultInterface: Bool) {
        coordinate = dataSource.location?.coordinate
        startTimestamp = session.departureTimestamp ?? nil
        sdkIdentifier = defaultInterface ? "mapbox-navigation-ui-ios" : "mapbox-navigation-ios"
        profile = dataSource.routeProgress.route.routeOptions.profileIdentifier.rawValue
        simulation = dataSource.locationProvider is SimulatedLocationManager.Type
        
        sessionIdentifier = session.identifier.uuidString
        originalRequestIdentifier = session.originalRoute.routeIdentifier
        requestIdentifier = dataSource.routeProgress.route.routeIdentifier
                
        if let location = dataSource.location,
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
        try container.encodeIfPresent(upComingStep?.instructions, forKey: .upcomingInstruction)
        try container.encodeIfPresent(upComingStep?.maneuverType.description, forKey: .upcomingType)
        try container.encodeIfPresent(upComingStep?.maneuverDirection.description, forKey: .upcomingModifier)
        try container.encodeIfPresent(upComingStep?.names?.joined(separator: ";"), forKey: .upcomingName)
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

extension EventDetails {
    
    enum EventDetailsError: Error {
        case EncodingError(String)
    }
    
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        if let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
            return dictionary
        } else {
            throw EventDetailsError.EncodingError("Failed to encode event details")
        }
    }
}

extension UIApplicationState: Encodable {
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
        if isOutputBluetooth() {
            return "bluetooth"
        }
        if isOutputHeadphones() {
            return "headphones"
        }
        if isOutputSpeaker() {
            return "speaker"
        }
        return "unknown"
    }
    
    func isOutputBluetooth() -> Bool {
        for output in currentRoute.outputs {
            if [AVAudioSessionPortBluetoothA2DP, AVAudioSessionPortBluetoothLE].contains(output.portType) {
                return true
            }
        }
        return false
    }
    
    func isOutputHeadphones() -> Bool {
        for output in currentRoute.outputs {
            if [AVAudioSessionPortHeadphones, AVAudioSessionPortAirPlay, AVAudioSessionPortHDMI, AVAudioSessionPortLineOut].contains(output.portType) {
                return true
            }
        }
        return false
    }
    
    func isOutputSpeaker() -> Bool {
        for output in currentRoute.outputs {
            if [AVAudioSessionPortBuiltInSpeaker, AVAudioSessionPortBuiltInReceiver].contains(output.portType) {
                return true
            }
        }
        return false
    }
}
