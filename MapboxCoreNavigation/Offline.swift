import Foundation
import MapboxDirections
import MapboxNavigationNative

public enum RequestOption {
    case preferServerSide // TODO: Not yet implemented
    case preferClientSide // TODO: Not yet implemented
    case serverSideOnly
    case clientSideOnly
}

public enum OfflineRoutingError: Error {
    case unexpectedRouteResult
    case corruptRouteData
}

class OfflineStorage: NSObject {
    
    static var tilesPath: URL {
        let path = coreNavigationCacheDirectory.appendingPathComponent("tiles")
        ensureDirectoryExist(at: path)
        return path
    }
    
    static var translationsPath: URL {
        let path = coreNavigationCacheDirectory.appendingPathComponent("translations")
        ensureDirectoryExist(at: path)
        return path
    }
    
    static var coreNavigationCacheDirectory: URL {
        let cacheDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        return URL(fileURLWithPath: cacheDirectory).appendingPathComponent(Bundle.mapboxCoreNavigation.bundleIdentifier!).appendingPathComponent("offline")
    }
    
    // Ensures that a directory exist at the given path.
    // Returns false if no directory was created.
    @discardableResult
    static func ensureDirectoryExist(at path: URL) -> Bool {
        do {
            try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
            return true
        } catch {
            return false
        }
    }
}

public typealias RouteCompletionHandler = (_ waypoints: [Waypoint]?, _ routes: [Route]?, _ error: NSError?) -> Void

public class ExtendedDirections: NSObject {
    
    public static let shared = ExtendedDirections()
    
    static let offlineSerialQueueLabel = Bundle.mapboxCoreNavigation.bundleIdentifier!.appending(".offline")
    
    static let serialQueue = DispatchQueue(label: ExtendedDirections.offlineSerialQueueLabel)
    
    var _navigator: MBNavigator!
    var navigator: MBNavigator {
        //assert(OperationQueue.current?.underlyingQueue?.label == ExtendedDirections.offlineSerialQueueLabel,
        //       "The offline navigator must be accessed from the dedicated serial queue")
        if _navigator == nil {
            self._navigator = MBNavigator()
            
            let tilePath = OfflineStorage.tilesPath.absoluteString.replacingOccurrences(of: "file://", with: "")
            let localizationPath = OfflineStorage.translationsPath.absoluteString.replacingOccurrences(of: "file://", with: "")
            
            // navigator raises an exception after each try:
            // 1: uncompressed tiles packed in a tar archive,
            // 2: uncompressed tiles in directories
            // 3: compressed tiles in directories
            // We are using the 3rd option
            self._navigator.configureRouter(forTilesPath: tilePath, translationsPath: localizationPath)
        }
        
        return _navigator
    }
    
    open func calculate(_ options: RouteOptions, completionHandler: @escaping RouteCompletionHandler) {
        
        guard let navigationOptions = options as? NavigationRouteOptions else {
            Directions.shared.calculate(options, completionHandler: completionHandler)
            return
        }
        
        switch navigationOptions.preferredRequestOption {
        case .preferClientSide:
            fatalError("Not yet implemented")
        case .preferServerSide:
            fatalError("Not yet implemented")
        case .serverSideOnly:
            Directions.shared.calculate(options, completionHandler: completionHandler)
        case .clientSideOnly:
            let url = Directions.shared.url(forCalculating: options)
            
            ExtendedDirections.serialQueue.async { [weak self] in
                guard let result = self?.navigator.getRouteForDirectionsUri(url.absoluteString) else {
                    return completionHandler(nil, nil, OfflineRoutingError.unexpectedRouteResult as NSError)
                }
                
                guard let data = result.json.data(using: .utf8) else {
                    return completionHandler(nil, nil, OfflineRoutingError.corruptRouteData as NSError)
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                    let response = options.response(from: json)
                    
                    DispatchQueue.main.async {
                        completionHandler(response.0, response.1, nil)
                    }
                    
                } catch {
                    DispatchQueue.main.async {
                        completionHandler(nil, nil, error as NSError)
                    }
                }
            }
        }
    }
}
