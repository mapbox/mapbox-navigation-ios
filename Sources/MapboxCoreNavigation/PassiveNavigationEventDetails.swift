import Foundation
import CoreLocation

struct PassiveNavigationEventDetails: NavigationEventDetails {
    let coordinate: CLLocationCoordinate2D?
    let created: Date = Date()
    let sessionIdentifier: String = "session-id" // TODO: create global session
    
    var event: String?
    var userId: String?
    var feedbackType: String?
    var description: String?
    var screenshot: String?
    // TODO: add time in foreground and background
    
    init(dataSource: PassiveNavigationEventsManagerDataSource) {
        coordinate = dataSource.rawLocation?.coordinate
    }
    
    private enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case userId
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
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(coordinate?.latitude, forKey: .latitude)
        try container.encodeIfPresent(coordinate?.longitude, forKey: .longitude)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(feedbackType, forKey: .feedbackType)
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
    }
}
