import Mapbox
import Polyline

extension MGLMapboxEvents {
    public class func addDefaultEvents(routeProgress: RouteProgress, sessionIdentifier: UUID, sessionNumberOfReroutes: Int = 0) -> [String: Any] {
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
        modifiedEventDictionary["profile"] = routeProgress.route.routeOptions.profileIdentifier
        
        modifiedEventDictionary["rerouteCount"] = sessionNumberOfReroutes
        
        modifiedEventDictionary["batteryLevel"] = UIDevice.current.batteryState
        modifiedEventDictionary["applicationState"] = UIApplication.shared.applicationState
        modifiedEventDictionary["screenBrightness"] = UIScreen.main.brightness
        
        return modifiedEventDictionary
    }
}
