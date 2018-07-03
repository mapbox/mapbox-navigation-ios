import Foundation
import CoreLocation
import Polyline
import UIKit
import AVFoundation

struct EventDetails {
    var originalRequestIdentifier: String?
    var requestIdentifier: String?
    var coordinate: CLLocationCoordinate2D?
    var originalGeometry: Polyline?
    var originalDistance: CLLocationDistance?
    var originalEstimatedDuration: TimeInterval?
    var originalStepCount: Int?
    var geometry: Polyline?
    var distance: CLLocationDistance?
    var estimatedDuration: TimeInterval?
    var created: Date
    var startTimestamp: Date?
    var sdkIdentifier: String
    var sdkVersion: String
    var profile: String
    var simulation: Bool
    var sessionIdentifier: String
    var distanceCompleted: CLLocationDistance
    var distanceRemaining: TimeInterval
    var durationRemaining: TimeInterval
    var rerouteCount: Int
    var volumeLevel: Int
    var audioType: String
    var screenBrightness: Int
    var batteryPluggedIn: Bool
    var batteryLevel: Int
    var applicationState: UIApplicationState
    var userAbsoluteDistanceToDestination: CLLocationDistance?
    var locationEngine: CLLocationManager.Type?
    var percentTimeInPortrait: Int
    var percentTimeInForeground: Int
    var locationManagerDesiredAccuracy: CLLocationAccuracy?
    
    var stepIndex: Int
    var stepCount: Int
    var legIndex: Int
    var legCount: Int
    var totalStepCount: Int
    
    init(routeController: RouteController, session: SessionState) {
        created = Date()
        if let start = session.departureTimestamp {
            startTimestamp =  start
        }
        
        sdkIdentifier = routeController.usesDefaultUserInterface ? "mapbox-navigation-ui-ios" : "mapbox-navigation-ios"
        sdkVersion = String(describing: Bundle(for: RouteController.self).object(forInfoDictionaryKey: "CFBundleShortVersionString")!)
        
        profile = routeController.routeProgress.route.routeOptions.profileIdentifier.rawValue
        simulation = routeController.locationManager is ReplayLocationManager || routeController.locationManager is SimulatedLocationManager ? true : false
        
        sessionIdentifier = session.identifier.uuidString
        originalRequestIdentifier = session.originalRoute.routeIdentifier
        requestIdentifier = routeController.routeProgress.route.routeIdentifier
        
        if let location = routeController.locationManager.location {
            coordinate = location.coordinate
            
            if let coordinates = routeController.routeProgress.route.coordinates, let lastCoord = coordinates.last {
                userAbsoluteDistanceToDestination = location.distance(from: CLLocation(latitude: lastCoord.latitude, longitude: lastCoord.longitude))
            }
        }
        
        if let geometry = session.originalRoute.coordinates {
            originalGeometry = Polyline(coordinates: geometry)
            originalDistance = round(session.originalRoute.distance)
            originalEstimatedDuration = round(session.originalRoute.expectedTravelTime)
            originalStepCount = session.originalRoute.legs.map({$0.steps.count}).reduce(0, +)
        }
        if let geometry = session.currentRoute.coordinates {
            self.geometry = Polyline(coordinates: geometry)
            distance = round(session.currentRoute.distance)
            estimatedDuration = round(session.currentRoute.expectedTravelTime)
        }
        
        distanceCompleted = round(session.totalDistanceCompleted + routeController.routeProgress.distanceTraveled)
        distanceRemaining = round(routeController.routeProgress.distanceRemaining)
        durationRemaining = round(routeController.routeProgress.durationRemaining)
        
        rerouteCount = session.numberOfReroutes
        
        volumeLevel = Int(AVAudioSession.sharedInstance().outputVolume * 100)
        audioType = AVAudioSession.sharedInstance().audioType
        screenBrightness = Int(UIScreen.main.brightness * 100)
        
        batteryPluggedIn = UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
        batteryLevel = UIDevice.current.batteryLevel >= 0 ? Int(UIDevice.current.batteryLevel * 100) : -1
        applicationState = UIApplication.shared.applicationState
        if let manager = routeController.locationManager {
            locationEngine = type(of: manager)
            locationManagerDesiredAccuracy = manager.desiredAccuracy
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
