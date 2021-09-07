import Foundation
import CoreLocation

struct PassiveNavigationEventDetails: NavigationEventDetails {
    let coordinate: CLLocationCoordinate2D?
    let created = Date()
    let sessionIdentifier: String
    let startTimestamp: Date?
    let driverMode = "freeDrive"
    
    var event: String?
    var userIdentifier: String?
    var appMetadata: [String: String?]? = nil
    var feedbackType: ActiveNavigationFeedbackType?
    var description: String?
    var screenshot: String?
    
    var percentTimeInPortrait: Int = 0
    var percentTimeInForeground: Int = 0
    var totalTimeInForeground: TimeInterval = 0
    var totalTimeInBackground: TimeInterval = 0
    
    init(dataSource: PassiveNavigationEventsManagerDataSource, sessionState: SessionState, appMetadata: [String: String?]? = nil) {
        coordinate = dataSource.rawLocation?.coordinate
        sessionIdentifier = sessionState.identifier.uuidString
        startTimestamp = sessionState.departureTimestamp
        updateTimeState(session: sessionState)
        self.appMetadata = appMetadata
    }
    
    private enum CodingKeys: String, CodingKey {
        case latitude = "lat"
        case longitude = "lng"
        case userIdentifier = "userId"
        case appMetadata
        case event
        case feedbackType
        case description
        case screenshot
        case audioType
        case applicationState
        case batteryLevel
        case batteryPluggedIn
        case device
        case operatingSystem
        case platform
        case sdkVersion
        case screenBrightness
        case volumeLevel
        case driverMode
        case sessionIdentifier
        case navigatorSessionIdentifier
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(coordinate?.latitude, forKey: .latitude)
        try container.encodeIfPresent(coordinate?.longitude, forKey: .longitude)
        try container.encodeIfPresent(userIdentifier, forKey: .userIdentifier)
        try container.encodeIfPresent(appMetadata, forKey: .appMetadata)
        try container.encodeIfPresent(feedbackType?.typeKey, forKey: .feedbackType)
        try container.encodeIfPresent(event, forKey: .event)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(screenshot, forKey: .screenshot)
        try container.encode(audioType, forKey: .audioType)
        try container.encode(applicationState, forKey: .applicationState)
        try container.encode(batteryLevel, forKey: .batteryLevel)
        try container.encode(batteryPluggedIn, forKey: .batteryPluggedIn)
        try container.encode(device, forKey: .device)
        try container.encode(operatingSystem, forKey: .operatingSystem)
        try container.encode(platform, forKey: .platform)
        try container.encode(sdkVersion, forKey: .sdkVersion)
        try container.encode(screenBrightness, forKey: .screenBrightness)
        try container.encode(volumeLevel, forKey: .volumeLevel)
        try container.encode(driverMode, forKey: .driverMode)
        try container.encode(sessionIdentifier, forKey: .sessionIdentifier)
        try container.encode(NavigationEventsManager.applicationSessionIdentifier, forKey: .navigatorSessionIdentifier)
    }
}
