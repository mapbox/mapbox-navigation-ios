import Foundation
import MapboxDirections
import MapboxNavigationNative

/**
 A closure to call when the `NavigationDirections` router has been configured completely.
 */
public typealias NavigationDirectionsCompletionHandler = (_ numberOfTiles: UInt64) -> Void

enum OfflineRoutingError: Error, LocalizedError {
    case unexpectedRouteResult(String)
    case corruptRouteData(String)
    case responseError(String)
    
    public var localizedDescription: String {
        switch self {
        case .corruptRouteData(let value):
            return value
        case .unexpectedRouteResult(let value):
            return value
        case .responseError(let value):
            return value
        }
    }
    
    var errorDescription: String? {
        return localizedDescription
    }
}

struct NavigationDirectionsConstants {
    static let offlineSerialQueueLabel = Bundle.mapboxCoreNavigation.bundleIdentifier!.appending(".offline")
    static let unpackSerialQueueLabel = Bundle.mapboxCoreNavigation.bundleIdentifier!.appending(".offline.unpack")
    static let offlineSerialQueue = DispatchQueue(label: NavigationDirectionsConstants.offlineSerialQueueLabel)
    static let unpackSerialQueue = DispatchQueue(label: NavigationDirectionsConstants.unpackSerialQueueLabel)
}

/**
 A closure to call when an unpacking operation has made some progress.
 
 - parameter totalBytes: The total size of tile pack in bytes.
 - parameter remainingBytes: The remaining number of bytes left to download.
 */
public typealias UnpackProgressHandler = (_ totalBytes: UInt64, _ remainingBytes: UInt64) -> ()

/**
 A closure to call once an unpacking operation has completed.
 
 - parameter numberOfTiles: The number of tiles that were unpacked.
 - parameter error: Potential error that occured when trying to unpack.
 */
public typealias UnpackCompletionHandler = (_ numberOfTiles: UInt64, _ error: Error?) -> ()

/**
 A `NavigationDirections` object provides you with optimal directions between different locations, or waypoints. The directions object passes your request to a built-in routing engine and returns the requested information to a closure (block) that you provide. A directions object can handle multiple simultaneous requests. A `RouteOptions` object specifies criteria for the results, such as intermediate waypoints, a mode of transportation, or the level of detail to be returned. In addition to `Directions`, `NavigationDirections` provides support for offline routing.
 
 Each result produced by the directions object is stored in a `Route` object. Depending on the `RouteOptions` object you provide, each route may include detailed information suitable for turn-by-turn directions, or it may include only high-level information such as the distance, estimated travel time, and name of each leg of the trip. The waypoints that form the request may be conflated with nearby locations, as appropriate; the resulting waypoints are provided to the closure.
 */
@objc(MBNavigationDirections)
public class NavigationDirections: Directions {
    
    @objc public override init(accessToken: String? = nil, host: String? = nil) {
        super.init(accessToken: accessToken, host: host)
    }
    
    /**
     Configures the router with the given set of tiles.
     
     - parameter tilesURL: The location where the tiles has been sideloaded to.
     - parameter completionHandler: A block that is called when the router is completely configured.
     */
    @objc public func configureRouter(tilesURL: URL, completionHandler: @escaping NavigationDirectionsCompletionHandler) {
        NavigationDirectionsConstants.offlineSerialQueue.sync {
            let tileCount = self.navigator.configureRouter(forTilesPath: tilesURL.path)
            DispatchQueue.main.async {
                completionHandler(tileCount)
            }
        }
    }
    
    @available(*, deprecated, renamed: "NavigationDirections.configureRouter(tilesURL:completionHandler:)")
    @objc public func configureRouter(tilesURL: URL, translationsURL: URL? = nil, completionHandler: @escaping NavigationDirectionsCompletionHandler) {
        configureRouter(tilesURL: tilesURL, completionHandler: completionHandler)
    }
    
    /**
     Unpacks a .tar-file at the given filePathURL to a writeable output directory.
     The target at the filePathURL will be consumed while unpacking.
     
     - parameter filePathURL: The file path to the .tar-file.
     - parameter outputDirectoryURL: The output directory.
     - parameter progressHandler: Unpacking reports progress every 500ms.
     - parameter completionHandler: Called when unpacking completed.
     */
    @objc(unpackTilePackAtURL:outputDirectoryURL:progressHandler:completionHandler:)
    public class func unpackTilePack(at filePathURL: URL, outputDirectoryURL: URL, progressHandler: UnpackProgressHandler?, completionHandler: UnpackCompletionHandler?) {
        
        NavigationDirectionsConstants.offlineSerialQueue.sync {
            
            let totalPackedBytes = filePathURL.fileSize!
            
            // Report 0% progress
            progressHandler?(totalPackedBytes, totalPackedBytes)
            
            var timer: DispatchTimer? = DispatchTimer(countdown: .seconds(500), accuracy: .seconds(500), executingOn: NavigationDirectionsConstants.unpackSerialQueue) {
                if let remainingBytes = filePathURL.fileSize {
                    progressHandler?(totalPackedBytes, remainingBytes)
                }
            }

            timer?.arm()
            
            let tilePath = filePathURL.path
            let outputPath = outputDirectoryURL.path
            
            let numberOfTiles = MBNavigator().unpackTiles(forPacked_tiles_path: tilePath, output_directory: outputPath)
            
            // Report 100% progress
            progressHandler?(totalPackedBytes, totalPackedBytes)
            
            timer?.disarm()
            timer = nil
            
            DispatchQueue.main.async {
                completionHandler?(numberOfTiles, nil)
            }
        }
    }
    
    /**
     Begins asynchronously calculating the route or routes using the given options and delivers the results to a closure.
     
     This method retrieves the routes asynchronously via MapboxNavigationNative.
     
     Routes may be displayed atop a [Mapbox map](https://www.mapbox.com/maps/). They may be cached but may not be stored permanently. To use the results in other contexts or store them permanently, [upgrade to a Mapbox enterprise plan](https://www.mapbox.com/navigation/#pricing).
     
     - parameter options: A `RouteOptions` object specifying the requirements for the resulting routes.
     - parameter offline: Determines whether to calculate the route offline or online.
     - parameter completionHandler: The closure (block) to call with the resulting routes. This closure is executed on the application’s main thread.
     */
    @objc(calculateDirectionsWithOptions:offline:completionHandler:)
    public func calculate(_ options: RouteOptions, offline: Bool = true, completionHandler: @escaping Directions.RouteCompletionHandler) {
        
        guard offline == true else {
            super.calculate(options, completionHandler: completionHandler)
            return
        }
        
        let url = self.url(forCalculating: options)
        
        NavigationDirectionsConstants.offlineSerialQueue.async { [weak self] in
            
            guard let result = self?.navigator.getRouteForDirectionsUri(url.absoluteString) else {
                let message = NSLocalizedString("OFFLINE_NO_RESULT", bundle: .mapboxCoreNavigation, value: "Unable to calculate the requested route while offline.", comment: "Error description when an offline route request returns no result")
                let error = OfflineRoutingError.unexpectedRouteResult(message)
                return completionHandler(nil, nil, error as NSError)
            }
            
            guard let data = result.json.data(using: .utf8) else {
                let message = NSLocalizedString("OFFLINE_CORRUPT_DATA", bundle: .mapboxCoreNavigation, value: "Found an invalid route while offline.", comment: "Error message when an offline route request returns a response that can’t be deserialized")
                let error = OfflineRoutingError.corruptRouteData(message)
                return completionHandler(nil, nil, error as NSError)
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                if let errorValue = json["error"] as? String {
                    DispatchQueue.main.async {
                        let error = OfflineRoutingError.responseError(errorValue)
                        return completionHandler(nil, nil, error as NSError)
                    }
                } else {
                    
                    DispatchQueue.main.async {
                        let response = options.response(from: json)
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
    
    var _navigator: MBNavigator!
    var navigator: MBNavigator {
        
        assert(currentQueueName() == NavigationDirectionsConstants.offlineSerialQueueLabel,
               "The offline navigator must be accessed from the dedicated serial queue")
        
        if _navigator == nil {
            self._navigator = MBNavigator()
        }
        
        return _navigator
    }
}

fileprivate func currentQueueName() -> String? {
    let name = __dispatch_queue_get_label(nil)
    return String(cString: name, encoding: .utf8)
}

extension URL {
    
    fileprivate var fileSize: UInt64? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: self.path)
            return attributes[.size] as? UInt64
        } catch {
            return nil
        }
    }
}
