import Foundation
import MapboxDirections
import MapboxNavigationNative


public enum OfflineRoutingError: Error {
    case unexpectedRouteResult
    case corruptRouteData
    case responseError(String)
}

/**
 An `OfflineDirections` object provides you with optimal directions between different locations, or waypoints. The directions object passes your request to the [Mapbox Directions API](https://www.mapbox.com/api-documentation/?language=Swift#directions) and returns the requested information to a closure (block) that you provide. A directions object can handle multiple simultaneous requests. A `RouteOptions` object specifies criteria for the results, such as intermediate waypoints, a mode of transportation, or the level of detail to be returned.
 
 Each result produced by the directions object is stored in a `Route` object. Depending on the `RouteOptions` object you provide, each route may include detailed information suitable for turn-by-turn directions, or it may include only high-level information such as the distance, estimated travel time, and name of each leg of the trip. The waypoints that form the request may be conflated with nearby locations, as appropriate; the resulting waypoints are provided to the closure.
 */
public class OfflineDirections: Directions {
    
    struct Constants {
        static let offlineSerialQueueLabel = Bundle.mapboxCoreNavigation.bundleIdentifier!.appending(".offline")
        static let serialQueue = DispatchQueue(label: Constants.offlineSerialQueueLabel)
    }
    
    let tilesPath: String
    let translationsPath: String
    
    public typealias OfflineCompletionHandler = (_ numberOfTiles: UInt) -> Void
    
    
    /**
     Initializes a newly created directions object with an optional access token and host.
     
     - parameter accessToken: A Mapbox [access token](https://www.mapbox.com/help/define-access-token/). If an access token is not specified when initializing the directions object, it should be specified in the `MGLMapboxAccessToken` key in the main application bundle’s Info.plist.
     - parameter host: An optional hostname to the server API. The [Mapbox Directions API](https://www.mapbox.com/api-documentation/?language=Swift#directions) endpoint is used by default.
     - parameter tilesPath: The location where the tiles has been sideloaded to.
     - parameter translationsPath: The location where the translations has been sideloaded to.
     */
    public init(accessToken: String?, host: String?, tilesPath: String, translationsPath: String, completionHandler: @escaping OfflineCompletionHandler) {
        self.tilesPath = tilesPath
        self.translationsPath = translationsPath
        
        super.init(accessToken: accessToken, host: host)
        
        Constants.serialQueue.sync {
            let tilesPath = self.tilesPath.replacingOccurrences(of: "file://", with: "")
            let translationsPath = self.translationsPath.replacingOccurrences(of: "file://", with: "")
            let tileCount = self.navigator.setupRouter(tilesPath, translationsPath: translationsPath)
            
            DispatchQueue.main.async {
                completionHandler(tileCount)
            }
        }
    }
    
    var _navigator: MBNavigator!
    var navigator: MBNavigator {
        
        assert(currentQueueName() == Constants.offlineSerialQueueLabel,
               "The offline navigator must be accessed from the dedicated serial queue")
        
        if _navigator == nil {
            self._navigator = MBNavigator()
        }
        
        return _navigator
    }
    
    
    /**
     Begins asynchronously calculating the route or routes using the given options and delivers the results to a closure.
     
     This method retrieves the routes asynchronously via MapboxNavigationNative.
     
     Routes may be displayed atop a [Mapbox map](https://www.mapbox.com/maps/). They may be cached but may not be stored permanently. To use the results in other contexts or store them permanently, [upgrade to a Mapbox enterprise plan](https://www.mapbox.com/directions/#pricing).
     
     - parameter options: A `RouteOptions` object specifying the requirements for the resulting routes.
     - parameter completionHandler: The closure (block) to call with the resulting routes. This closure is executed on the application’s main thread.
     */
    open func calculateOffline(_ options: RouteOptions, completionHandler: @escaping RouteCompletionHandler) {
        
        let url = self.url(forCalculating: options)
        
        Constants.serialQueue.sync { [weak self] in
            
            guard let result = self?.navigator.getRouteForDirectionsUri(url.absoluteString) else {
                return completionHandler(nil, nil, OfflineRoutingError.unexpectedRouteResult as NSError)
            }
            
            guard let data = result.json.data(using: .utf8) else {
                return completionHandler(nil, nil, OfflineRoutingError.corruptRouteData as NSError)
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                if let errorValue = json["error"] as? String {
                    DispatchQueue.main.async {
                        let error = NSError(domain: "..", code: 102, userInfo: [NSLocalizedDescriptionKey: errorValue])
                        return completionHandler(nil, nil, error)
                    }
                } else {
                    let response = options.response(from: json)
                    
                    DispatchQueue.main.async {
                        return completionHandler(response.0, response.1, nil)
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    return completionHandler(nil, nil, error as NSError)
                }
            }
        }
    }
}

fileprivate func currentQueueName() -> String? {
    let name = __dispatch_queue_get_label(nil)
    return String(cString: name, encoding: .utf8)
}
