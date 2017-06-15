import Mapbox
import Polyline

extension MGLMapboxEvents {
    class func addDefaultEvents(routeProgress: RouteProgress, sessionIdentifier: UUID) -> [String: Any] {
        var modifiedEventDictionary: [String: Any] = [:]
    
        modifiedEventDictionary["platform"] = UIDevice.current.systemName
        modifiedEventDictionary["operatingSystemVersion"] = "\(UIDevice.current.systemName)-\(UIDevice.current.systemVersion)"
        modifiedEventDictionary["sdkIdentifier"] = "mapbox-navigation-ios"
        modifiedEventDictionary["sdkVersion"] = "0.4.0"
        modifiedEventDictionary["eventVersion"] = 1
        modifiedEventDictionary["sessionIdentifier"] = sessionIdentifier
        
        if let geometry = routeProgress.route.coordinates {
            modifiedEventDictionary["geometry"] = Polyline(coordinates: geometry)
        }

        modifiedEventDictionary["created"] = Date.ISO8601
        modifiedEventDictionary["routeProfile"] = routeProgress.route.routeOptions.profileIdentifier
        
        modifiedEventDictionary["batteryLevel"] = UIDevice.current.batteryState
        modifiedEventDictionary["applicationState"] = UIApplication.shared.applicationState
        modifiedEventDictionary["screenBrightness"] = UIScreen.main.brightness
        
        return modifiedEventDictionary
    }
    
    class func addEventPrefix(eventDictionary: [String: Any], eventPrefix: String) -> [String: Any] {
        var newDictionary: [String: Any] = [:]
        
        for key in Array(eventDictionary.keys) {
            newDictionary["\(eventPrefix)"] = eventDictionary[key]
        }
        
        return newDictionary
    }
    
}
