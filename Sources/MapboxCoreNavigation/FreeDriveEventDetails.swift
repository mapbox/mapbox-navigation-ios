import Foundation
import CoreLocation

struct FreeDriveEventDetails: GlobalEventDetails {
    enum EventType: String {
        case start
        case stop
    }

    let location: CLLocation?
    let created = Date()
    let eventType: EventType
    let sessionIdentifier: String
    let startTimestamp: Date?
    let simulation: Bool
    let locationEngine: String

    var event: String?
    var appMetadata: [String: String?]? = nil

    var percentTimeInPortrait: Int = 0
    var percentTimeInForeground: Int = 0
    var totalTimeInForeground: TimeInterval = 0
    var totalTimeInBackground: TimeInterval = 0

    init(type: EventType, dataSource: PassiveNavigationEventsManagerDataSource, sessionState: SessionState, appMetadata: [String: String?]? = nil) {
        self.eventType = type
        self.location = dataSource.rawLocation
        self.simulation = dataSource.locationManagerType is SimulatedLocationManager.Type
        self.locationEngine = String(describing: dataSource.locationManagerType)
        self.sessionIdentifier = sessionState.identifier.uuidString
        self.startTimestamp = sessionState.departureTimestamp
        self.appMetadata = appMetadata

        updateTimeState(session: sessionState)
    }

    private enum CodingKeys: String, CodingKey {
        case applicationState
        case appMetadata
        case audioType
        case batteryLevel
        case batteryPluggedIn
        case created
        case event
        case eventType
        case location
        case locationEngine
        case navigatorSessionIdentifier
        case percentTimeInForeground
        case percentTimeInPortrait
        case screenBrightness
        case sessionIdentifier
        case simulation
        case startTimestamp
        case volumeLevel
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(applicationState, forKey: .applicationState)
        try container.encode(audioType, forKey: .audioType)
        try container.encode(batteryLevel, forKey: .batteryLevel)
        try container.encode(batteryPluggedIn, forKey: .batteryPluggedIn)
        try container.encode(created.ISO8601, forKey: .created)
        try container.encode(eventType.rawValue, forKey: .eventType)
        try container.encode(locationEngine, forKey: .locationEngine)
        try container.encode(percentTimeInForeground, forKey: .percentTimeInForeground)
        try container.encode(percentTimeInPortrait, forKey: .percentTimeInPortrait)
        try container.encode(screenBrightness, forKey: .screenBrightness)
        try container.encode(sessionIdentifier, forKey: .sessionIdentifier)
        try container.encode(simulation, forKey: .simulation)
        try container.encode(volumeLevel, forKey: .volumeLevel)
        try container.encode(NavigationEventsManager.applicationSessionIdentifier, forKey: .navigatorSessionIdentifier)
        try container.encodeIfPresent(appMetadata, forKey: .appMetadata)
        try container.encodeIfPresent(event, forKey: .event)
        if let location = location.flatMap(EventLocation.init(_:)) {
            try container.encode(location, forKey: .location)
        }
        try container.encodeIfPresent(startTimestamp?.ISO8601, forKey: .startTimestamp)
    }
}
