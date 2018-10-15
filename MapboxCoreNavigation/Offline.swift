import Foundation
import MapboxDirections
import MapboxNavigationNative


public enum OfflineRoutingError: Error {
    case unexpectedRouteResult
    case corruptRouteData
    case responseError(String)
}


public class OfflineDirections: Directions {
    
    struct Constants {
        static let offlineSerialQueueLabel = Bundle.mapboxCoreNavigation.bundleIdentifier!.appending(".offline")
        static let serialQueue = DispatchQueue(label: Constants.offlineSerialQueueLabel)
    }
    
    let tilesPath: String
    let translationsPath: String
    
    public typealias OfflineCompletionHandler = (_ error: NSError?) -> Void
    
    public init(accessToken: String?, host: String?, tilesPath: String, translationsPath: String, completionHandler: @escaping OfflineCompletionHandler) {
        self.tilesPath = tilesPath
        self.translationsPath = translationsPath
        
        super.init(accessToken: accessToken, host: host)
        
        Constants.serialQueue.sync {
            let tilesPath = self.tilesPath.replacingOccurrences(of: "file://", with: "")
            let translationsPath = self.translationsPath.replacingOccurrences(of: "file://", with: "")
            self.navigator.configureRouter(forTilesPath: tilesPath, translationsPath: translationsPath)
            
            DispatchQueue.main.async {
                completionHandler(nil)
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
