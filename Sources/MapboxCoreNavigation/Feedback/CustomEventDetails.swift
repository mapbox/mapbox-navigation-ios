import CoreLocation
import Polyline
import UIKit
import AVFoundation
import MapboxDirections

struct CustomEventDetails: GlobalEventDetails {
    let version: String
    let simulation: Bool
    let locationEngine: String?
    let coordinate: CLLocationCoordinate2D?
    
    var type: EventType
    var event: String?
    var payload: String?
    var eventVersion: Int
    var customEventVersion: String
    let created: Date = Date()
    var sessionIdentifier: String
    var driverMode: String
    var sdkIdentifier: String?
    var startTimestamp: Date?

    var percentTimeInPortrait: Int = 0
    var percentTimeInForeground: Int = 0
    var totalTimeInForeground: TimeInterval = 0
    var totalTimeInBackground: TimeInterval = 0
    
    init(type: EventType, session: SessionState, defaultInterface: Bool, payload: String? = "", passiveDataSource: PassiveNavigationEventsManagerDataSource? = nil, activeDataSource: ActiveNavigationEventsManagerDataSource? = nil) {
        self.type = type
        sessionIdentifier = session.identifier.uuidString
        sdkIdentifier = defaultInterface ? "mapbox-navigation-ui-ios" : "mapbox-navigation-ios"
        startTimestamp = session.departureTimestamp
        self.version = "2.4"
        self.customEventVersion = "1.0.0"
        self.event = CustomEventType.analytics.rawValue
        self.eventVersion = 0
        self.payload = payload
        
        coordinate = passiveDataSource?.rawLocation?.coordinate ?? activeDataSource?.router.rawLocation?.coordinate
        let locationManagerType = (passiveDataSource != nil) ? passiveDataSource?.locationManagerType : activeDataSource?.locationManagerType
        locationEngine = String(describing: locationManagerType)
        driverMode = (passiveDataSource != nil) ? "freeDrive" : "trip"
        simulation = locationManagerType is SimulatedLocationManager.Type
    }
    
    private enum CodingKeys: String, CodingKey {
        case latitude = "lat"
        case longitude = "lng"
        case version
        case created
        case startTimestamp
        case sdkIdentifier
        case sdkVersion
        case platform
        case operatingSystem
        case locationEngine
        case device
        case simulation
        case driverMode
        case event
        case customEventVersion
        case payload
        case audioType
        case applicationState
        case batteryLevel
        case batteryPluggedIn
        case screenBrightness
        case volumeLevel
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(simulation, forKey: .simulation)
        try container.encodeIfPresent(locationEngine, forKey: .locationEngine)
        try container.encode(created.ISO8601, forKey: .created)
        try container.encodeIfPresent(sdkIdentifier, forKey: .sdkIdentifier)
        try container.encode(sdkVersion, forKey: .sdkVersion)
        try container.encode(platform, forKey: .platform)
        try container.encode(operatingSystem, forKey: .operatingSystem)
        try container.encodeIfPresent(device, forKey: .device)
        try container.encode(driverMode, forKey: .driverMode)
        try container.encodeIfPresent(event, forKey: .event)
        try container.encode(coordinate?.latitude, forKey: .latitude)
        try container.encode(coordinate?.longitude, forKey: .longitude)
        try container.encodeIfPresent(payload, forKey: .payload)
        try container.encodeIfPresent(startTimestamp?.ISO8601, forKey: .startTimestamp)
        try container.encodeIfPresent(customEventVersion, forKey: .customEventVersion)
        try container.encode(screenBrightness, forKey: .screenBrightness)
        try container.encode(volumeLevel, forKey: .volumeLevel)
        try container.encode(audioType, forKey: .audioType)
        try container.encode(applicationState, forKey: .applicationState)
        try container.encode(batteryLevel, forKey: .batteryLevel)
        try container.encode(batteryPluggedIn, forKey: .batteryPluggedIn)
    }
}
