import Polyline
import MapboxDirections
import AVFoundation
import MapboxMobileEvents

let SecondsBeforeCollectionAfterFeedbackEvent: TimeInterval = 20
let EventVersion = 6

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
    var stepCount: Int?
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
            stepCount = session.currentRoute.legs.map({$0.steps.count}).reduce(0, +)
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
        modifiedEventDictionary["stepCount"] = stepCount

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
        }
        
        modifiedEventDictionary["percentTimeInPortrait"] = percentTimeInPortrait
        modifiedEventDictionary["percentTimeInForeground"] = percentTimeInForeground

        return modifiedEventDictionary
    }
}

extension MMEEventsManager {
    open static var unrated: Int { return -1 }
    
    func addDefaultEvents(routeController: RouteController) -> [String: Any] {
        return EventDetails(routeController: routeController, session: routeController.sessionState).eventDictionary
    }
    
    func navigationDepartEvent(routeController: RouteController) -> [String: Any] {
        var eventDictionary = self.addDefaultEvents(routeController: routeController)
        eventDictionary["event"] = MMEEventTypeNavigationDepart
        return eventDictionary
    }
    
    func navigationArriveEvent(routeController: RouteController) -> [String: Any] {
        var eventDictionary = self.addDefaultEvents(routeController: routeController)
        eventDictionary["event"] = MMEEventTypeNavigationArrive
        return eventDictionary
    }
    
    //TODO: Change event semantic to `.exit`
    func navigationCancelEvent(routeController: RouteController, rating potentialRating: Int? = nil, comment: String? = nil) -> [String: Any] {
        let rating = potentialRating ?? MMEEventsManager.unrated
        var eventDictionary = self.addDefaultEvents(routeController: routeController)
        eventDictionary["event"] = MMEEventTypeNavigationCancel
        eventDictionary["arrivalTimestamp"] = routeController.sessionState.arrivalTimestamp?.ISO8601 ?? NSNull()
        
        let validRating: Bool = (rating >= MMEEventsManager.unrated && rating <= 100)
        assert(validRating, "MMEEventsManager: Invalid Rating. Values should be between \(MMEEventsManager.unrated) (none) and 100.")
        guard validRating else { return eventDictionary }
        eventDictionary["rating"] = rating
        
        if comment != nil {
            eventDictionary["comment"] = comment
        }
        return eventDictionary
    }
    
    func navigationFeedbackEvent(routeController: RouteController, type: FeedbackType, description: String?) -> [String: Any] {
        var eventDictionary = self.addDefaultEvents(routeController: routeController)
        eventDictionary["event"] = MMEEventTypeNavigationFeedback
        
        eventDictionary["userId"] = UIDevice.current.identifierForVendor?.uuidString
        eventDictionary["feedbackType"] = type.description
        eventDictionary["description"] = description
        
        eventDictionary["step"] = routeController.routeProgress.currentLegProgress.stepDictionary
        eventDictionary["screenshot"] = captureScreen(scaledToFit: 250)?.base64EncodedString()
        
        return eventDictionary
    }
    
    func navigationRerouteEvent(routeController: RouteController, eventType: String = MMEEventTypeNavigationReroute) -> [String: Any] {
        let timestamp = Date()
        
        var eventDictionary = self.addDefaultEvents(routeController: routeController)
        eventDictionary["event"] = eventType
        
        eventDictionary["secondsSinceLastReroute"] = routeController.sessionState.lastRerouteDate != nil ? round(timestamp.timeIntervalSince(routeController.sessionState.lastRerouteDate!)) : -1
        eventDictionary["step"] = routeController.routeProgress.currentLegProgress.stepDictionary
        
        // These are placeholders until the route controller's RouteProgress is updated after rerouting
        eventDictionary["newDistanceRemaining"] = -1
        eventDictionary["newDurationRemaining"] = -1
        eventDictionary["newGeometry"] = nil
        eventDictionary["screenshot"] = captureScreen(scaledToFit: 250)?.base64EncodedString()
        
        return eventDictionary
    }
    
    func navigationFeedbackEventWithLocationsAdded(event: CoreFeedbackEvent, routeController: RouteController) -> [String: Any] {
        var eventDictionary = event.eventDictionary
        eventDictionary["feedbackId"] = event.id.uuidString
        eventDictionary["locationsBefore"] = routeController.sessionState.pastLocations.allObjects.filter { $0.timestamp <= event.timestamp}.map {$0.dictionaryRepresentation}
        eventDictionary["locationsAfter"] = routeController.sessionState.pastLocations.allObjects.filter {$0.timestamp > event.timestamp}.map {$0.dictionaryRepresentation}
        return eventDictionary
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

extension RouteLegProgress {
    var stepDictionary: [String: Any] {
        get {
            return [
                "upcomingInstruction": upComingStep?.instructions ?? NSNull(),
                "upcomingType": upComingStep?.maneuverType.description ?? NSNull(),
                "upcomingModifier": upComingStep?.maneuverDirection.description ?? NSNull(),
                "upcomingName": upComingStep?.names?.joined(separator: ";") ?? NSNull(),
                "previousInstruction": currentStep.instructions,
                "previousType": currentStep.maneuverType.description,
                "previousModifier": currentStep.maneuverDirection.description,
                "previousName": currentStep.names?.joined(separator: ";") ?? NSNull(),
                "distance": Int(currentStep.distance),
                "duration": Int(currentStep.expectedTravelTime),
                "distanceRemaining": Int(currentStepProgress.distanceRemaining),
                "durationRemaining": Int(currentStepProgress.durationRemaining)
            ]
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

class FeedbackEvent: CoreFeedbackEvent {
    func update(type: FeedbackType, source: FeedbackSource, description: String?) {
        eventDictionary["feedbackType"] = type.description
        eventDictionary["source"] = source.description
        eventDictionary["description"] = description
    }
}

class RerouteEvent: CoreFeedbackEvent {
    func update(newRoute: Route) {
        if let geometry = newRoute.coordinates {
            eventDictionary["newGeometry"] = Polyline(coordinates: geometry).encodedPolyline
            eventDictionary["newDistanceRemaining"] = round(newRoute.distance)
            eventDictionary["newDurationRemaining"] = round(newRoute.expectedTravelTime)
        }
    }
}
