import Mapbox
import Polyline
import MapboxDirections
import AVFoundation

extension MGLMapboxEvents {
    class func addDefaultEvents(routeController: RouteController) -> [String: Any] {
        var modifiedEventDictionary: [String: Any] = [:]
    
        modifiedEventDictionary["platform"] = String.systemName
        modifiedEventDictionary["device"] = UIDevice.current.machine
        modifiedEventDictionary["operatingSystem"] = "\(String.systemName) \(String.systemVersion)"
        modifiedEventDictionary["sdkIdentifier"] = routeController.usesDefaultUserInterface ? "mapbox-navigation-ui-ios" : "mapbox-navigation-ios"
        modifiedEventDictionary["sdkVersion"] = String(describing: Bundle(for: RouteController.self).object(forInfoDictionaryKey: "CFBundleShortVersionString")!)
        modifiedEventDictionary["eventVersion"] = 1
        modifiedEventDictionary["sessionIdentifier"] = routeController.sessionState.identifier.uuidString
        
        if let location = routeController.locationManager.location {
            modifiedEventDictionary["lat"] = location.coordinate.latitude
            modifiedEventDictionary["lng"] = location.coordinate.longitude
        }
        
        if let geometry = routeController.sessionState.originalRoute.coordinates {
            modifiedEventDictionary["geometry"] = Polyline(coordinates: geometry).encodedPolyline
        }

        modifiedEventDictionary["created"] = Date().ISO8601
        modifiedEventDictionary["profile"] = routeController.routeProgress.route.routeOptions.profileIdentifier.rawValue
        
        modifiedEventDictionary["estimatedDistance"] = round(routeController.sessionState.originalRoute.distance)
        modifiedEventDictionary["estimatedDuration"] = round(routeController.sessionState.originalRoute.expectedTravelTime)
        modifiedEventDictionary["rerouteCount"] = routeController.sessionState.numberOfReroutes

        modifiedEventDictionary["volumeLevel"] = Int(AVAudioSession.sharedInstance().outputVolume * 100)
        modifiedEventDictionary["screenBrightness"] = Int(UIScreen.main.brightness * 100)

        modifiedEventDictionary["batteryPluggedIn"] = UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
        modifiedEventDictionary["batteryLevel"] = UIDevice.current.batteryLevel >= 0 ? Int(UIDevice.current.batteryLevel * 100) : -1
       
        switch UIApplication.shared.applicationState {
        case .active:
            modifiedEventDictionary["applicationState"] = "Foreground"
        case .inactive:
            modifiedEventDictionary["applicationState"] = "Inactive"
        case .background:
            modifiedEventDictionary["applicationState"] = "Background"
        default:
            modifiedEventDictionary["applicationState"] = "Unknown"
        }
        //modifiedEventDictionary["connectivity"] = ??
        
        return modifiedEventDictionary
    }
}

extension UIDevice {
    var machine: String {
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

struct SessionState {
    let startTimestamp = Date()
    let identifier = UUID()
    var totalDistanceCompleted: CLLocationDistance = 0
    var numberOfReroutes = 0
    var lastReroute: Date?
    var hasSentDepartEvent = false
    var hasSentArriveEvent = false
    var originalRoute: Route!
}

struct FeedbackEventState {
    var reroute = false
    var shouldPushEventually = false
    
    var maxLocationOnEitherSideOfReroute = 20
    var indexLocationBeforeReroute = 0
    var countdownToPushEvent = 20
    
    var userLocationsAroundRerouteLocation: [CLLocation] = []
    
    var lastReroute: Date?
    var numberOfReroutes = 0
    
    var timestamp: Date?
    var coordinate: CLLocationCoordinate2D?
    var previousDistanceRemaining: CLLocationDistance = -1
    var previousDurationRemaining: TimeInterval = -1
    
    var newDistanceRemaining: CLLocationDistance = -1
    var newDurationRemaining: TimeInterval = -1
    var secondsSinceLastReroute: TimeInterval = -1
}
