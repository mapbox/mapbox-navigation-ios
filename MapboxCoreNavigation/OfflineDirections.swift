import Foundation
import MapboxDirections
import MapboxNavigationNative

/** :nodoc:
 A closure to call when the `NavigationDirections` router has been configured completely.
 */
@available(*, deprecated)
public typealias NavigationDirectionsCompletionHandler = (_ tilesURL: URL) -> Void

/** :nodoc:
 An error that occurs when calculating directions potentially offline using the `NavigationDirections.calculate(_:offline:completionHandler:)` method.
*/
@available(*, deprecated)
public enum OfflineRoutingError: LocalizedError {
    /**
     A standard Directions API error occurred.
     
     A Directions API error can occur whether directions are calculated online or offline.
     */
    case standard(DirectionsError)
    /**
     The router returned a response that isn’t correctly formatted.
    */
    case invalidResponse
    
    case unknown(underlying: Error)
    
    public var localizedDescription: String {
        switch self {
        case .standard(let error):
            return error.localizedDescription
        case .invalidResponse:
            return NSLocalizedString("OFFLINE_CORRUPT_DATA", bundle: .mapboxCoreNavigation, value: "Found an invalid route while offline.", comment: "Error message when an offline route request returns a response that can’t be deserialized")
        case .unknown(let underlying):
            return "Unknown Error: \(underlying.localizedDescription)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .standard(let error):
            return error.failureReason
        case .unknown(let underlying):
            return (underlying as? LocalizedError)?.failureReason
        default:
            return nil
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .standard(let error):
            return error.recoverySuggestion
        case .unknown(let underlying):
            return (underlying as? LocalizedError)?.recoverySuggestion
        default:
            return nil
        }
    }
}

@available(*, deprecated)
struct NavigationDirectionsConstants {
    static let offlineSerialQueueLabel = Bundle.mapboxCoreNavigation.bundleIdentifier!.appending(".offline")
    static let unpackSerialQueueLabel = Bundle.mapboxCoreNavigation.bundleIdentifier!.appending(".offline.unpack")
    static let offlineSerialQueue = DispatchQueue(label: NavigationDirectionsConstants.offlineSerialQueueLabel)
    static let unpackSerialQueue = DispatchQueue(label: NavigationDirectionsConstants.unpackSerialQueueLabel)
}

/** :nodoc:
 A closure to call when an unpacking operation has made some progress.
 
 - parameter totalBytes: The total size of tile pack in bytes.
 - parameter remainingBytes: The remaining number of bytes left to download.
 */
@available(*, deprecated)
public typealias UnpackProgressHandler = (_ totalBytes: UInt64, _ remainingBytes: UInt64) -> ()

/** :nodoc:
 A closure to call once an unpacking operation has completed.
 
 - parameter numberOfTiles: The number of tiles that were unpacked.
 - parameter error: Potential error that occured when trying to unpack.
 */
@available(*, deprecated)
public typealias UnpackCompletionHandler = (_ numberOfTiles: UInt64, _ error: Error?) -> ()

/** :nodoc:
 A closure (block) to be called when a directions request is complete.
 
 - parameter waypoints: An array of `Waypoint` objects. Each waypoint object corresponds to a `Waypoint` object in the original `RouteOptions` object. The locations and names of these waypoints are the result of conflating the original waypoints to known roads. The waypoints may include additional information that was not specified in the original waypoints.
 
 If the request was canceled or there was an error obtaining the routes, this argument may be `nil`.
 - parameter routes: An array of `Route` objects. The preferred route is first; any alternative routes come next if the `RouteOptions` object’s `includesAlternativeRoutes` property was set to `true`. The preferred route depends on the route options object’s `profileIdentifier` property.
 
 If the request was canceled or there was an error obtaining the routes, this argument is `nil`. This is not to be confused with the situation in which no results were found, in which case the array is present but empty.
 - parameter error: The error that occurred, or `nil` if the placemarks were obtained successfully.
 */
@available(*, deprecated)
public typealias OfflineRouteCompletionHandler = (_ session: Directions.Session, _ result: Result<RouteResponse, OfflineRoutingError>) -> Void

/** :nodoc:
 A `NavigationDirections` object provides you with optimal directions between different locations, or waypoints. The directions object passes your request to a built-in routing engine and returns the requested information to a closure (block) that you provide. A directions object can handle multiple simultaneous requests. A `RouteOptions` object specifies criteria for the results, such as intermediate waypoints, a mode of transportation, or the level of detail to be returned. In addition to `Directions`, `NavigationDirections` provides support for offline routing.
 
 Each result produced by the directions object is stored in a `Route` object. Depending on the `RouteOptions` object you provide, each route may include detailed information suitable for turn-by-turn directions, or it may include only high-level information such as the distance, estimated travel time, and name of each leg of the trip. The waypoints that form the request may be conflated with nearby locations, as appropriate; the resulting waypoints are provided to the closure.
 */
@available(*, deprecated, message: "Use the Directions class instead.")
public class NavigationDirections: Directions {
    /**
     Configures the router with the given set of tiles.
     
     - parameter tilesURL: The location where the tiles has been sideloaded to.
     - parameter completionHandler: A block that is called when the router is completely configured.
     */
    public func configureRouter(tilesURL: URL, completionHandler: @escaping NavigationDirectionsCompletionHandler) {
        NavigationDirectionsConstants.offlineSerialQueue.sync {
            let tilesConfig = TilesConfig(tilesPath: tilesURL.path,
                                          inMemoryTileCache: nil,
                                          mapMatchingSpatialCache: nil,
                                          threadsCount: nil,
                                          endpointConfig: nil)
            
            let settingsProfile = SettingsProfile(application: ProfileApplication.kMobile, platform: ProfilePlatform.KIOS)
            self.navigator = Navigator(profile: settingsProfile, config: NavigatorConfig() , customConfig: "", tilesConfig: tilesConfig)
            
            DispatchQueue.main.async {
                completionHandler(tilesURL)
            }
        }
    }
    
    /**
     Unpacks a .tar-file at the given filePathURL to a writeable output directory.
     The target at the filePathURL will be consumed while unpacking.
     
     - parameter filePathURL: The file path to the .tar-file.
     - parameter outputDirectoryURL: The output directory.
     - parameter progressHandler: Unpacking reports progress every 500ms.
     - parameter completionHandler: Called when unpacking completed.
     */
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
            
            let navigator: Navigator = {
                let settingsProfile = SettingsProfile(application: ProfileApplication.kMobile, platform: ProfilePlatform.KIOS)
                return Navigator(profile: settingsProfile, config: NavigatorConfig(), customConfig: "", tilesConfig: TilesConfig())
            }()
            let numberOfTiles = navigator.unpackTiles(forPackedTilesPath: tilePath, outputDirectory: outputPath)
            
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
     
     Routes may be displayed atop a [Mapbox map](https://www.mapbox.com/maps/).
     
     - parameter options: A `RouteOptions` object specifying the requirements for the resulting routes.
     - parameter offline: Determines whether to calculate the route offline or online.
     - parameter completionHandler: The closure (block) to call with the resulting routes. This closure is executed on the application’s main thread.
     If called `NavigationDirections` instance is deallocated before route calculation is finished - completion won't be called.
     */
    public func calculate(_ options: RouteOptions, offline: Bool = true, completionHandler: @escaping OfflineRouteCompletionHandler) {
        
        guard offline else {
            super.calculate(options) { (session, result) in
                
                switch result {
                case let .failure(directionsError):
                    completionHandler(session, .failure(.standard(directionsError)))
                case let .success(response):
                    completionHandler(session, .success(response))
                }
            }
            return
        }
        
        let url = self.url(forCalculating: options)
        let session: Directions.Session = (options: options, credentials: self.credentials)
        
        NavigationDirectionsConstants.offlineSerialQueue.async { [weak self] in
            guard let result = self?.navigator.getRouteForDirectionsUri(url.absoluteString) else {
                return
            }
            
            guard let data = result.json.data(using: .utf8) else {
                DispatchQueue.main.async {
                    completionHandler(session, .failure(.invalidResponse))
                }
                return
            }
            DispatchQueue.main.async {
                
                do {
                    let decoder = JSONDecoder()
                    decoder.userInfo[.options] = options
                    decoder.userInfo[.credentials] = session.credentials
                    let response = try decoder.decode(RouteResponse.self, from: data)
                    guard let routes = response.routes, !routes.isEmpty else {
                        return completionHandler(session, .failure(.standard(.unableToRoute)))
                    }
                    return completionHandler(session, .success(response))
                }
                catch {
                    return completionHandler(session, .failure(.unknown(underlying: error)))
                }
            }
        }
    }
    
    var _navigator: Navigator!
    var navigator: Navigator {
        get {
            assert(currentQueueName() == NavigationDirectionsConstants.offlineSerialQueueLabel,
                   "The offline navigator must be accessed from the dedicated serial queue")
            
            if _navigator == nil {
                let settingsProfile = SettingsProfile(application: ProfileApplication.kMobile, platform: ProfilePlatform.KIOS)
                self._navigator = Navigator(profile: settingsProfile, config: NavigatorConfig(), customConfig: "", tilesConfig: TilesConfig())
            }
            
            return _navigator
        }
        
        set {
            _navigator = newValue
        }
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
