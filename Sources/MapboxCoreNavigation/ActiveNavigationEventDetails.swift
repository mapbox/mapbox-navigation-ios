import CoreLocation
import Polyline
import UIKit
import AVFoundation
import MapboxDirections
import MapboxMobileEvents

struct ActiveNavigationEventDetails: NavigationEventDetails {
    let coordinate: CLLocationCoordinate2D?
    let distance: CLLocationDistance?
    let distanceCompleted: CLLocationDistance
    let distanceRemaining: CLLocationDistance
    let durationRemaining: TimeInterval
    let estimatedDuration: TimeInterval?
    let geometry: Polyline?
    let locationEngine: String?
    let locationManagerDesiredAccuracy: CLLocationAccuracy?
    let originalDistance: CLLocationDistance?
    let originalEstimatedDuration: TimeInterval?
    let originalGeometry: Polyline?
    let originalRequestIdentifier: String?
    let originalStepCount: Int?
    let profile: String
    let requestIdentifier: String?
    let rerouteCount: Int
    let sessionIdentifier: String
    let simulation: Bool
    let startTimestamp: Date?
    let sdkIdentifier: String
    let userAbsoluteDistanceToDestination: CLLocationDistance?
    let driverMode = "trip"
    
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
    var userIdentifier: String?
    var appMetadata: [String: String?]?
    var feedbackType: ActiveNavigationFeedbackType?
    var description: String?
    var screenshot: String?
    var secondsSinceLastReroute: TimeInterval?
    var newDistanceRemaining: CLLocationDistance?
    var newDurationRemaining: TimeInterval?
    var newGeometry: String?
    var totalTimeInForeground: TimeInterval = 0
    var totalTimeInBackground: TimeInterval = 0
    var percentTimeInForeground: Int = 0
    var percentTimeInPortrait: Int = 0
    
    init(dataSource: ActiveNavigationEventsManagerDataSource, session: SessionState, defaultInterface: Bool, appMetadata: [String: String?]? = nil) {
        coordinate = dataSource.router.rawLocation?.coordinate
        startTimestamp = session.departureTimestamp
        sdkIdentifier = defaultInterface ? "mapbox-navigation-ui-ios" : "mapbox-navigation-ios"
        profile = dataSource.routeProgress.routeOptions.profileIdentifier.rawValue
        simulation = dataSource.locationManagerType is SimulatedLocationManager.Type
        
        sessionIdentifier = session.identifier.uuidString
        originalRequestIdentifier = session.routeIdentifier
        requestIdentifier = dataSource.router.indexedRouteResponse.routeResponse.identifier
                
        self.appMetadata = appMetadata
        
        if let location = dataSource.router.rawLocation,
            let coordinates = dataSource.routeProgress.route.shape?.coordinates,
            let lastCoord = coordinates.last {
            userAbsoluteDistanceToDestination = location.distance(from: CLLocation(latitude: lastCoord.latitude, longitude: lastCoord.longitude))
        } else {
            userAbsoluteDistanceToDestination = nil
        }
        
        if let originalRoute = session.originalRoute, let shape = originalRoute.shape {
            originalGeometry = Polyline(coordinates: shape.coordinates)
            originalDistance = round(originalRoute.distance)
            originalEstimatedDuration = round(originalRoute.expectedTravelTime)
            originalStepCount = originalRoute.legs.map({$0.steps.count}).reduce(0, +)
        } else {
            originalGeometry = nil
            originalDistance = nil
            originalEstimatedDuration = nil
            originalStepCount = nil
        }
        
        if let currentRoute = session.currentRoute, let shape = currentRoute.shape {
            self.geometry = Polyline(coordinates: shape.coordinates)
            distance = round(currentRoute.distance)
            estimatedDuration = round(currentRoute.expectedTravelTime)
        } else {
            self.geometry = nil
            distance = nil
            estimatedDuration = nil
        }
        
        distanceCompleted = round(session.totalDistanceCompleted + dataSource.routeProgress.distanceTraveled)
        distanceRemaining = round(dataSource.routeProgress.distanceRemaining)
        durationRemaining = round(dataSource.routeProgress.durationRemaining)
        
        rerouteCount = session.numberOfReroutes
        
        locationEngine = String(describing: dataSource.locationManagerType)
        locationManagerDesiredAccuracy = dataSource.desiredAccuracy
        
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
        case userIdentifier = "userId"
        case appMetadata
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
        case driverMode
        case navigatorSessionIdentifier
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
        try container.encodeIfPresent(userIdentifier, forKey: .userIdentifier)
        try container.encodeIfPresent(appMetadata, forKey: .appMetadata)
        try container.encodeIfPresent(feedbackType?.typeKey, forKey: .feedbackType)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(screenshot, forKey: .screenshot)
        try container.encodeIfPresent(secondsSinceLastReroute, forKey: .secondsSinceLastReroute)
        try container.encodeIfPresent(newDistanceRemaining, forKey: .newDistanceRemaining)
        try container.encodeIfPresent(newDurationRemaining, forKey: .newDurationRemaining)
        try container.encode(totalTimeInForeground, forKey: .totalTimeInForeground)
        try container.encode(totalTimeInBackground, forKey: .totalTimeInBackground)
        try container.encodeIfPresent(rating, forKey: .rating)
        try container.encode(driverMode, forKey: .driverMode)
        try container.encode(NavigationEventsManager.applicationSessionIdentifier, forKey: .navigatorSessionIdentifier)
    }
}
