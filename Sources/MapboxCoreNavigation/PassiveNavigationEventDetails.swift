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
    var name: String?
    var version: String?
    var feedbackType: FeedbackType?
    var description: String?
    var screenshot: String?
    
    var percentTimeInPortrait: Int = 0
    var percentTimeInForeground: Int = 0
    var totalTimeInForeground: TimeInterval = 0
    var totalTimeInBackground: TimeInterval = 0
    
    init(dataSource: PassiveNavigationEventsManagerDataSource, sessionState: SessionState) {
        coordinate = dataSource.rawLocation?.coordinate
        sessionIdentifier = sessionState.identifier.uuidString
        startTimestamp = sessionState.departureTimestamp
        updateTimeState(session: sessionState)
    }
    
    private enum CodingKeys: String, CodingKey {
        case latitude = "lat"
        case longitude = "lng"
        case userIdentifier = "userId"
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
        case tripSessionIdentifier = "tripSessionId"
        case appSessionIdentifier = "navigatorSessionId"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(coordinate?.latitude, forKey: .latitude)
        try container.encodeIfPresent(coordinate?.longitude, forKey: .longitude)
        try container.encodeIfPresent(userIdentifier, forKey: .userIdentifier)
        try container.encodeIfPresent(feedbackType?.description, forKey: .feedbackType)
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
        try container.encode(sessionIdentifier, forKey: .tripSessionIdentifier)
        try container.encode(NavigationEventsManager.applicationSessionIdentifier, forKey: .appSessionIdentifier)
    }
}
