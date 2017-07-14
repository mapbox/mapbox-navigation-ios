import Polyline
import MapboxDirections
import AVFoundation
import MapboxMobileEvents

let SecondsForCollectionAfterFeedbackEvent: TimeInterval = 20

struct DefaultEventDictionary {
    var arrivalTimestamp: String
    var userId: String
    var event: String
    var feedbackType: Int
    var description: String
    var screenshot: String
    var newDistanceRemaining: CLLocationDistance
    var newDurationRemaining: TimeInterval
    var secondsSinceLastReroute: TimeInterval
    var newGeometry: String
    var created: String
    var startTimestamp: String
    var platform: String
    var operatingSystem: String
    var device: String
    var sdkIdentifier: String
    var sdkVersion: String
    var eventVersion: Int
    var profile: String
    var simulation: Bool
    var sessionIdentifier: String
    var originalRequestIdentifier: String
    var requestIdentifier: String
    var lat: CLLocationDegrees
    var lng: CLLocationDegrees
    var originalGeometry: String
    var originalEstimatedDistance: CLLocationDistance
    var originalEstimatedDuration: TimeInterval
    var geometry: String
    var estimatedDistance: CLLocationDistance
    var estimatedDuration: TimeInterval
    var distanceCompleted: CLLocationDistance
    var distanceRemaining: TimeInterval
    var durationRemaining: TimeInterval
    var rerouteCount: Int
    var volumeLevel: Int
    var screenBrightness: Int
    var batteryPluggedIn: Bool
    var batteryLevel: Float
    var applicationState: String
    
    init(routeProgress: RouteProgress, session: SessionState) {
        created = Date().ISO8601
        modifiedEventDictionary.startTimestamp = session.departureTimestamp?.ISO8601 ?? 0
        
        modifiedEventDictionary.platform = ProcessInfo.systemName
        modifiedEventDictionary.operatingSystem = "\(ProcessInfo.systemName) \(ProcessInfo.systemVersion)"
        modifiedEventDictionary.device = UIDevice.current.machine
        
        modifiedEventDictionary.sdkIdentifier = routeController.usesDefaultUserInterface ? "mapbox-navigation-ui-ios" : "mapbox-navigation-ios"
        modifiedEventDictionary.sdkVersion = String(describing: Bundle(for: RouteController.self).object(forInfoDictionaryKey: "CFBundleShortVersionString")!)
        
        modifiedEventDictionary.eventVersion = 2
        
        modifiedEventDictionary.profile = routeProgress.route.routeOptions.profileIdentifier.rawValue
        modifiedEventDictionary.simulation = routeController.locationManager is ReplayLocationManager || routeController.locationManager is SimulatedLocationManager ? true : false
        
        modifiedEventDictionary.sessionIdentifier = session.identifier.uuidString
        modifiedEventDictionary.originalRequestIdentifier = nil
        modifiedEventDictionary.requestIdentifier = nil
        
        if let location = routeController.locationManager.location {
            modifiedEventDictionary.lat = location.coordinate.latitude
            modifiedEventDictionary.lng = location.coordinate.longitude
        }
        
        if let geometry = session.originalRoute.coordinates {
            modifiedEventDictionary.originalGeometry = Polyline(coordinates: geometry).encodedPolyline
            modifiedEventDictionary.originalEstimatedDistance = round(session.originalRoute.distance)
            modifiedEventDictionary.originalEstimatedDuration = round(session.originalRoute.expectedTravelTime)
        }
        if let geometry = session.currentRoute.coordinates {
            modifiedEventDictionary.geometry = Polyline(coordinates: geometry).encodedPolyline
            modifiedEventDictionary.estimatedDistance = round(session.currentRoute.distance)
            modifiedEventDictionary.estimatedDuration = round(session.currentRoute.expectedTravelTime)
        }
        
        modifiedEventDictionary.distanceCompleted = round(session.totalDistanceCompleted + routeProgress.distanceTraveled)
        modifiedEventDictionary.distanceRemaining = round(routeProgress.distanceRemaining)
        modifiedEventDictionary.durationRemaining = round(routeProgress.durationRemaining)
        
        modifiedEventDictionary.rerouteCount = session.numberOfReroutes
        
        modifiedEventDictionary.volumeLevel = Int(AVAudioSession.sharedInstance().outputVolume * 100)
        modifiedEventDictionary.screenBrightness = Int(UIScreen.main.brightness * 100)
        
        modifiedEventDictionary.batteryPluggedIn = UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
        modifiedEventDictionary.batteryLevel = UIDevice.current.batteryLevel >= 0 ? UIDevice.current.batteryLevel * 100 : -1
        modifiedEventDictionary.applicationState = UIApplication.shared.applicationState.telemetryString
        
        //modifiedEventDictionary.connectivity = ??
        
        return modifiedEventDictionary
    }
    
    func convertToDictionary() -> [String: Any] {
        return
    }
}

extension MMEEventsManager {
    func addDefaultEvents(routeController: RouteController) -> [String: Any] {
        return DefaultEventDictionary(routeProgress: routeController.routeProgress, session: routeController.sessionState).convertToDictionary()
    }
}

extension UIApplicationState {
    var telemetryString: String {
        get {
            switch self {
            case .active:
                return "Foreground"
            case .inactive:
                return "Inactive"
            case .background:
                return "Background"
            }
        }
    }
}

extension UIDevice {
    @nonobjc var machine: String {
        get {
            var systemInfo = utsname()
            uname(&systemInfo)
            let machineMirror = Mirror(reflecting: systemInfo.machine)
            let identifier = machineMirror.children.reduce("") { identifier, element in
                guard let value = element.value as? Int8, value != 0 else { return identifier }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }
            
            return identifier
        }
    }
}

extension CLLocation {
    var eventDictionary: [String: Any] {
        get {
            var locationDictionary:[String: Any] = [:]
            locationDictionary["lat"] = coordinate.latitude
            locationDictionary["lng"] = coordinate.longitude
            locationDictionary["altitude"] = altitude
            locationDictionary["timestamp"] = timestamp.ISO8601
            locationDictionary["horizontalAccuracy"] = horizontalAccuracy
            locationDictionary["verticalAccuracy"] = verticalAccuracy
            locationDictionary["course"] = course
            locationDictionary["speed"] = speed
            return locationDictionary
        }
    }
}

class FixedLengthQueue<T> {
    private var objects = Array<T>()
    private var length: Int
    
    public init(length: Int) {
        self.length = length
    }
    
    public func push(_ obj: T) {
        objects.append(obj)
        if objects.count == length {
            objects.remove(at: 0)
        }
    }
    
    public var allObjects: Array<T> {
        get {
            return Array(objects)
        }
    }
}

class CoreFeedbackEvent: Hashable {
    var id = UUID()
    
    var timestamp: Date
    
    var eventDictionary: [String: Any]
    
    init(timestamp: Date, eventDictionary: [String: Any]) {
        self.timestamp = timestamp
        self.eventDictionary = eventDictionary
    }
    
    var hashValue: Int {
        get {
            return id.hashValue
        }
    }
    
    static func ==(lhs: CoreFeedbackEvent, rhs: CoreFeedbackEvent) -> Bool {
        return lhs.id == rhs.id
    }
}

class FeedbackEvent: CoreFeedbackEvent {}

class RerouteEvent: CoreFeedbackEvent {}
