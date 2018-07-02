import Polyline
import MapboxDirections
import AVFoundation
import MapboxMobileEvents


let SecondsBeforeCollectionAfterFeedbackEvent: TimeInterval = 20
let EventVersion = 8

extension MMEEventsManager {
    public static var unrated: Int { return -1 }
    
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
            return machineMirror.children.reduce("") { (identifier: String, element: Mirror.Child) in
                guard let value = element.value as? Int8, value != 0 else { return identifier }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }
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

