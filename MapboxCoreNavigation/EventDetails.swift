import Foundation
import CoreLocation
import Polyline
import UIKit
import AVFoundation

struct EventDetails {
    
    let originalRequestIdentifier: String?
    let requestIdentifier: String?
    let coordinate: CLLocationCoordinate2D?
    let originalGeometry: Polyline?
    let originalDistance: CLLocationDistance?
    let originalEstimatedDuration: TimeInterval?
    let originalStepCount: Int?
    let geometry: Polyline?
    let distance: CLLocationDistance?
    let estimatedDuration: TimeInterval?
    let created: Date = Date()
    let startTimestamp: Date?
    let sdkIdentifier: String
    let sdkVersion: String = String(describing: Bundle(for: RouteController.self).object(forInfoDictionaryKey: "CFBundleShortVersionString")!)
    let profile: String
    let simulation: Bool
    let sessionIdentifier: String
    let distanceCompleted: CLLocationDistance
    let distanceRemaining: TimeInterval
    let durationRemaining: TimeInterval
    let rerouteCount: Int
    let volumeLevel: Int = Int(AVAudioSession.sharedInstance().outputVolume * 100)
    let audioType: String = AVAudioSession.sharedInstance().audioType
    let screenBrightness: Int = Int(UIScreen.main.brightness * 100)
    let batteryPluggedIn: Bool = [.charging, .full].contains(UIDevice.current.batteryState)
    let batteryLevel: Int = UIDevice.current.batteryLevel >= 0 ? Int(UIDevice.current.batteryLevel * 100) : -1
    let applicationState: UIApplicationState = UIApplication.shared.applicationState
    let userAbsoluteDistanceToDestination: CLLocationDistance?
    let locationEngine: CLLocationManager.Type?
    let percentTimeInPortrait: Int
    let percentTimeInForeground: Int
    let locationManagerDesiredAccuracy: CLLocationAccuracy?
    
    let stepIndex: Int
    let stepCount: Int
    let legIndex: Int
    let legCount: Int
    let totalStepCount: Int
    
    init(routeController: RouteController, session: SessionState) {
        
        
        startTimestamp = session.departureTimestamp ?? nil
        sdkIdentifier = routeController.usesDefaultUserInterface ? "mapbox-navigation-ui-ios" : "mapbox-navigation-ios"
        profile = routeController.routeProgress.route.routeOptions.profileIdentifier.rawValue
        simulation = routeController.locationManager is ReplayLocationManager || routeController.locationManager is SimulatedLocationManager ? true : false
        
        sessionIdentifier = session.identifier.uuidString
        originalRequestIdentifier = session.originalRoute.routeIdentifier
        requestIdentifier = routeController.routeProgress.route.routeIdentifier
        
        let location = routeController.locationManager.location
        coordinate = location?.coordinate ?? nil
        
        if let coordinates = routeController.routeProgress.route.coordinates, let lastCoord = coordinates.last {
            userAbsoluteDistanceToDestination = location?.distance(from: CLLocation(latitude: lastCoord.latitude, longitude: lastCoord.longitude)) ?? nil
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
        
        distanceCompleted = round(session.totalDistanceCompleted + routeController.routeProgress.distanceTraveled)
        distanceRemaining = round(routeController.routeProgress.distanceRemaining)
        durationRemaining = round(routeController.routeProgress.durationRemaining)
        
        rerouteCount = session.numberOfReroutes
        
        
        if let manager = routeController.locationManager {
            locationEngine = type(of: manager)
            locationManagerDesiredAccuracy = manager.desiredAccuracy
        } else {
            locationEngine = nil
            locationManagerDesiredAccuracy = nil
        }
        
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
        
        stepIndex = routeController.routeProgress.currentLegProgress.stepIndex
        stepCount = routeController.routeProgress.currentLeg.steps.count
        legIndex = routeController.routeProgress.legIndex
        legCount = routeController.routeProgress.route.legs.count
        totalStepCount = routeController.routeProgress.route.legs.map { $0.steps.count }.reduce(0, +)
    }
    
    var eventDictionary: [String: Any] {
        var modifiedEventDictionary: [String: Any] = [:]
        
        modifiedEventDictionary["created"] = created.ISO8601
        
        if let startTimestamp = startTimestamp {
            modifiedEventDictionary["startTimestamp"] = startTimestamp.ISO8601
        }
        
        modifiedEventDictionary["eventVersion"] = EventVersion
        
        modifiedEventDictionary["platform"] = ProcessInfo.systemName
        modifiedEventDictionary["operatingSystem"] = "\(ProcessInfo.systemName) \(ProcessInfo.systemVersion)"
        modifiedEventDictionary["device"] = UIDevice.current.machine
        
        modifiedEventDictionary["sdkIdentifier"] = sdkIdentifier
        modifiedEventDictionary["sdkVersion"] = sdkVersion
        
        modifiedEventDictionary["profile"] = profile
        modifiedEventDictionary["simulation"] = simulation
        
        modifiedEventDictionary["sessionIdentifier"] = sessionIdentifier
        modifiedEventDictionary["originalRequestIdentifier"] = originalRequestIdentifier
        modifiedEventDictionary["requestIdentifier"] = requestIdentifier
        
        modifiedEventDictionary["lat"] = coordinate?.latitude
        modifiedEventDictionary["lng"] = coordinate?.longitude
        
        modifiedEventDictionary["originalGeometry"] = originalGeometry?.encodedPolyline
        modifiedEventDictionary["originalEstimatedDistance"] = originalDistance
        modifiedEventDictionary["originalEstimatedDuration"] = originalEstimatedDuration
        modifiedEventDictionary["originalStepCount"] = originalStepCount
        
        modifiedEventDictionary["geometry"] = geometry?.encodedPolyline
        modifiedEventDictionary["estimatedDistance"] = distance
        modifiedEventDictionary["estimatedDuration"] = estimatedDuration
        
        modifiedEventDictionary["distanceCompleted"] = distanceCompleted
        modifiedEventDictionary["distanceRemaining"] = distanceRemaining
        modifiedEventDictionary["durationRemaining"] = durationRemaining
        
        modifiedEventDictionary["rerouteCount"] = rerouteCount
        
        modifiedEventDictionary["volumeLevel"] = volumeLevel
        modifiedEventDictionary["audioType"] = audioType
        modifiedEventDictionary["screenBrightness"] = screenBrightness
        
        modifiedEventDictionary["batteryPluggedIn"] = batteryPluggedIn
        modifiedEventDictionary["batteryLevel"] = batteryLevel
        modifiedEventDictionary["applicationState"] = applicationState.telemetryString
        modifiedEventDictionary["absoluteDistanceToDestination"] = userAbsoluteDistanceToDestination
        if let locationEngine = locationEngine {
            modifiedEventDictionary["locationEngine"] = String(describing: locationEngine)
            modifiedEventDictionary["locationManagerDesiredAccuracy"] = locationManagerDesiredAccuracy
        }
        
        modifiedEventDictionary["percentTimeInPortrait"] = percentTimeInPortrait
        modifiedEventDictionary["percentTimeInForeground"] = percentTimeInForeground
        
        modifiedEventDictionary["stepIndex"] = stepIndex
        modifiedEventDictionary["stepCount"] = stepCount
        modifiedEventDictionary["legIndex"] = legIndex
        modifiedEventDictionary["legCount"] = legCount
        modifiedEventDictionary["totalStepCount"] = totalStepCount
        
        return modifiedEventDictionary
    }
}

extension EventDetails {
    
    static func defaultEvents(routeController: RouteController) -> [String: Any] {
        return EventDetails(routeController: routeController, session: routeController.eventsManager.sessionState).eventDictionary
    }
}
