import Mapbox
import Polyline

extension MGLMapboxEvents {
    class func addDefaultEvents(routeProgress: RouteProgress, sessionIdentifier: UUID) -> [String: Any] {
        var modifiedEventDictionary: [String: Any] = [:]
    
        modifiedEventDictionary["platform"] = String.systemName
        modifiedEventDictionary["operatingSystemVersion"] = "\(String.systemName)-\(String.systemVersion)"
        modifiedEventDictionary["sdkIdentifier"] = "mapbox-navigation-ios"
        modifiedEventDictionary["sdkVersion"] = String(describing: Bundle(for: RouteController.self).object(forInfoDictionaryKey: "CFBundleShortVersionString")!)
        modifiedEventDictionary["eventVersion"] = 1
        modifiedEventDictionary["sessionIdentifier"] = sessionIdentifier
        
        if let geometry = routeProgress.route.coordinates {
            modifiedEventDictionary["geometry"] = Polyline(coordinates: geometry)
        }

        modifiedEventDictionary["created"] = Date().ISO8601
        modifiedEventDictionary["routeProfile"] = routeProgress.route.routeOptions.profileIdentifier
        
        modifiedEventDictionary["batteryLevel"] = UIDevice.current.batteryState
        modifiedEventDictionary["applicationState"] = UIApplication.shared.applicationState
        modifiedEventDictionary["screenBrightness"] = UIScreen.main.brightness
        
        return modifiedEventDictionary
    }
}
