@_implementationOnly import MapboxCommon_Private
import MapboxDirections
import MapboxNavigationNative
@_implementationOnly import MapboxNavigationNative_Private

/// RouterInterface from MapboxNavigationNative
typealias RouterInterfaceNative = MapboxNavigationNative_Private.RouterInterface

/**
 Provides alternative access to routing API.
 
 Use this class instead `Directions` requests wrapper to request new routes or refresh an existing one. Depending on `RouterSource`, `MapboxRoutingProvider` will use online and/or onboard routing engines. This may be used when designing purely online or offline apps, or when you need to provide best possible service regardless of internet collection.
 */
public class MapboxRoutingProvider: RoutingProvider {
    
    /**
     Initializes new `MapboxRoutingProvider`.
     
     - parameter source: routing engine source to use.
     - parameter settings: settings object, used to get credentials and cache configuration.
     - parameter datasetProfileIdentifier: profile setting, used for selecting tiles type for navigation. If set to `nil` (default) - will detect the same profile as used for current navigation.
     */
    public init(_ source: Source = .hybrid, settings: NavigationSettings = .shared, datasetProfileIdentifier: ProfileIdentifier? = nil) {
        self.source = source
        self.settings = settings
        self.datasetProfileIdentifier = datasetProfileIdentifier
    }
    
    // MARK: Configuration
    
    /**
     Configured routing engine source.
     */
    public let source: Source
    
    /**
     Defines source of routing engine to be used for requests.
     */
    public enum Source {
        /**
         Fetch data online only
         
         Such `MapboxRoutingProvider` is equivalent of using bare `Directions` wrapper.
         */
        case online
        /**
         Use offline data only
         
         In order for such `MapboxRoutingProvider` to function properly, proper navigation data should be available offline. `.offline` routing provider will not be able to refresh routes.
         */
        case offline
        /**
         Attempts to use `online` with fallback to `offline`.
         
         `.hybrid` routing provider will be able to refresh routes only using internet connection.
         */
        case hybrid
        
        var nativeSource: RouterType {
            switch self {
            case .online:
                return .online
            case .offline:
                return .onboard
            case .hybrid:
                return .hybrid
            }
        }
    }
    
    private let settings: NavigationSettings
    
    /**
     Profile setting, used for selecting tiles type for navigation.
     */
    public let datasetProfileIdentifier: ProfileIdentifier?
    
    static var __testRoutesStub: ((_: RouteOptions, _: @escaping Directions.RouteCompletionHandler) -> Request?)? = nil
    
    // MARK: Performing and Parsing Requests
    
    /**
     Unique identifier for a giver request.
     
     Valid only for the same instance of `MapboxRoutingProvider` that issued it.
     */
    public typealias RequestId = UInt64
    
    /**
     A request handler for the ongoing routing action.
     
     You can use this instance to cancel ongoing task if needed. Retaining this handler will keep related `MapboxRoutingProvider` from deallocating.
     */
    public struct Request: NavigationProviderRequest {
        /**
         Related request identifier.
         */
        public let requestIdentifier: RequestId
        
        // Intended retain cycle to prevent deallocating. `Request` will be deleted once request completes.
        let routingProvider: MapboxRoutingProvider
        
        /**
         Cancels the request if it is still active.
         */
        public func cancel() {
            routingProvider.router.cancelRouteRefreshRequest(forToken: requestIdentifier)
            routingProvider.router.cancelRouteRequest(forToken: requestIdentifier)
        }
    }
    
    /**
     List of ongoing tasks for the routing provider.
     
     You can see if provider is busy with something, or use related `Request.cancel()` to cancel requests as needed.
     */
    public private(set) var activeRequests: [RequestId : Request] = [:]
    
    private let requestsLock = NSLock()
    
    private lazy var router: RouterInterfaceNative = {
        let factory = NativeHandlersFactory(tileStorePath: settings.tileStoreConfiguration.navigatorLocation.tileStoreURL?.path ?? "",
                                            credentials: settings.directions.credentials,
                                            tilesVersion: Navigator.tilesVersion,
                                            historyDirectoryURL: Navigator.historyDirectoryURL,
                                            datasetProfileIdentifier: datasetProfileIdentifier ?? Navigator.datasetProfileIdentifier)
        return RouterFactory.build(for: source.nativeSource,
                                      cache: factory.cacheHandle,
                                      config: factory.configHandle,
                                      historyRecorder: factory.historyRecorder)
    } ()
    
    private func complete(requestId: RequestId, with result: @escaping () -> Void) {
        DispatchQueue.main.async { [self] in
            result()
            
            requestsLock {
                activeRequests[requestId] = nil
            }
        }
    }

    struct ResponseDisposition: Decodable {
        var code: String?
        var message: String?
        var error: String?
        
        private enum CodingKeys: CodingKey {
            case code, message, error
        }
    }
    
    private func parseResponse<ResponseType: Codable>(requestId: RequestId, userInfo: [CodingUserInfoKey : Any], result: Expected<AnyObject, AnyObject>, completion: @escaping (Result<ResponseType, DirectionsError>) -> Void) {
        do {
            let json = result.value as? String
            guard let data = json?.data(using: .utf8) else {
                self.complete(requestId: requestId) {
                    completion(.failure(.noData))
                }
                return
            }
            
            let decoder = JSONDecoder()
            decoder.userInfo = userInfo
            
            guard let disposition = try? decoder.decode(ResponseDisposition.self, from: data) else {
                let apiError = DirectionsError(code: nil,
                                               message: nil,
                                               response: nil,
                                               underlyingError: result.error as? Error)

                self.complete(requestId: requestId) {
                    completion(.failure(apiError))
                }
                return
            }
            
            guard (disposition.code == nil && disposition.message == nil) || disposition.code == "Ok" else {
                let apiError = DirectionsError(code: disposition.code,
                                               message: disposition.message,
                                               response: nil,
                                               underlyingError: result.error as? Error)

                self.complete(requestId: requestId) {
                    completion(.failure(apiError))
                }
                return
            }
            
            let result = try decoder.decode(ResponseType.self, from: data)
            
            self.complete(requestId: requestId) {
                completion(.success(result))
            }
        } catch {
            self.complete(requestId: requestId) {
                let bailError = DirectionsError(code: nil, message: nil, response: nil, underlyingError: error)
                completion(.failure(bailError))
            }
        }
    }
    
    private func doRequest<ResponseType: Codable>(options: DirectionsOptions,
                                                      completion: @escaping (Result<ResponseType, DirectionsError>) -> Void) -> Request? {
        let directionsUri = settings.directions.url(forCalculating: options).removingSKU().absoluteString
        var requestId: RequestId!
        
        requestId = router.getRouteForDirectionsUri(directionsUri) { [weak self] (result, _) in
            guard let self = self else { return }
            
            self.parseResponse(requestId: requestId,
                               userInfo: [.options: options,
                                          .credentials: self.settings.directions.credentials],
                                          result: result,
                                          completion: completion)
        }
        let request = Request(requestIdentifier: requestId,
                              routingProvider: self)
        requestsLock {
            activeRequests[requestId] = request
        }
        return request
    }
    
    // MARK: Routes Calculation
    
    /**
     Begins asynchronously calculating routes using the given options and delivers the results to a closure.
     
     Depending on configured `RouterSource`, this method may retrieve the routes asynchronously from the [Mapbox Directions API](https://www.mapbox.com/api-documentation/navigation/#directions) over a network connection or use onboard routing engine with available offline data.
     
     Routes may be displayed atop a [Mapbox map](https://www.mapbox.com/maps/).
     
     - parameter options: A `RouteOptions` object specifying the requirements for the resulting routes.
     - parameter completionHandler: The closure (block) to call with the resulting routes. This closure is executed on the application’s main thread.
     - returns: Related request. If, while waiting for the completion handler to execute, you no longer want the resulting routes, cancel corresponding task using this handle or `activeRequests`.
     */
    @discardableResult public func calculateRoutes(options: RouteOptions,
                                                   completionHandler: @escaping Directions.RouteCompletionHandler) -> NavigationProviderRequest? {
        return Self.__testRoutesStub?(options, completionHandler) ??
            doRequest(options: options) { [weak self] (result: Result<RouteResponse, DirectionsError>) in
                guard let self = self else { return }
                let session = (options: options as DirectionsOptions,
                               credentials: self.settings.directions.credentials)
                completionHandler(session, result)
            }
    }
    
    /**
     Begins asynchronously calculating matches using the given options and delivers the results to a closure.
     
     Depending on configured `RouterSource`, this method may retrieve the matches asynchronously from the [Mapbox Map Matching API](https://docs.mapbox.com/api/navigation/#map-matching) over a network connection or use onboard routing engine with available offline data.
     
     - parameter options: A `MatchOptions` object specifying the requirements for the resulting matches.
     - parameter completionHandler: The closure (block) to call with the resulting matches. This closure is executed on the application’s main thread.
     - returns: Related request. If, while waiting for the completion handler to execute, you no longer want the resulting routes, cancel corresponding task using this handle or `activeRequests`.
     */
    @discardableResult public func calculateRoutes(options: MatchOptions,
                                                   completionHandler: @escaping Directions.MatchCompletionHandler) -> NavigationProviderRequest? {
        return doRequest(options: options) { (result: Result<MapMatchingResponse, DirectionsError>) in
            let session = (options: options as DirectionsOptions,
                           credentials: self.settings.directions.credentials)
            completionHandler(session, result)
        }
    }
    
    // MARK: Routes Refreshing
    
    /**
     Begins asynchronously refreshing the selected route, optionally starting from an arbitrary leg.
     
     This method retrieves skeleton route data asynchronously from the Mapbox Directions Refresh API over a network connection. If a connection error or server error occurs, details about the error are passed into the given completion handler in lieu of the routes.
     
     - precondition: Set `RouteOptions.refreshingEnabled` to `true` when calculating the original route.
     
     - parameter indexedRouteResponse: The `RouteResponse` and selected `routeIndex` in it to be refreshed.
     - parameter fromLegAtIndex: The index of the leg in the route at which to begin refreshing. The response will omit any leg before this index and refresh any leg from this index to the end of the route. If this argument is omitted, the entire route is refreshed.
     - parameter completionHandler: The closure (block) to call with updated `RouteResponse` data. Order of `routes` remain unchanged comparing to original `indexedRouteResponse`. This closure is executed on the application’s main thread.
     - returns: Related request. If, while waiting for the completion handler to execute, you no longer want the resulting routes, cancel corresponding task using this handle or `activeRequests`.
     */
    @discardableResult public func refreshRoute(indexedRouteResponse: IndexedRouteResponse,
                                                fromLegAtIndex startLegIndex: UInt32 = 0,
                                                completionHandler: @escaping Directions.RouteCompletionHandler) -> NavigationProviderRequest? {
        guard case let .route(routeOptions) = indexedRouteResponse.routeResponse.options else {
            preconditionFailure("Invalid route data passed for refreshing. Expected `RouteResponse` containing `.route` `ResponseOptions` but got `.match`.")
        }
        
        let session = (options: routeOptions as DirectionsOptions,
                       credentials: self.settings.directions.credentials)
        
        guard let responseIdentifier = indexedRouteResponse.routeResponse.identifier else {
            DispatchQueue.main.async {
                completionHandler(session, .failure(.noData))
            }
            return nil
        }
        
        let encoder = JSONEncoder()
        encoder.userInfo[.options] = routeOptions
        
        let routeIndex = UInt32(indexedRouteResponse.routeIndex)
        
        guard let routeData = try? encoder.encode(indexedRouteResponse.routeResponse),
              let routeJSONString = String(data: routeData, encoding: .utf8) else {
            preconditionFailure("Could not serialize route data for refreshing.")
        }
        
        var requestId: RequestId!
        let refreshOptions = RouteRefreshOptions(requestId: responseIdentifier,
                                                 routeIndex: routeIndex,
                                                 legIndex: startLegIndex,
                                                 routingProfile: routeOptions.profileIdentifier.nativeProfile)
        
        requestId = router.getRouteRefresh(for: refreshOptions,
                                           route: routeJSONString) { [weak self] result, _ in
            guard let self = self else { return }
            
            self.parseResponse(requestId: requestId,
                               userInfo: [.options: routeOptions,
                                          .credentials: self.settings.directions.credentials],
                               result: result) { (response: Result<RouteResponse, DirectionsError>) in
                completionHandler(session, response)
            }
        }
        let request = Request(requestIdentifier: requestId,
                              routingProvider: self)
        requestsLock {
            activeRequests[requestId] = request
        }
        return request
    }
}

extension ProfileIdentifier {
    var nativeProfile: RoutingProfile {
        var mode: RoutingMode
        switch self {
        case .automobile:
            mode = .driving
        case .automobileAvoidingTraffic:
            mode = .drivingTraffic
        case .cycling:
            mode = .cycling
        case .walking:
            mode = .walking
        default:
            mode = .driving
        }
        return RoutingProfile(mode: mode, account: "mapbox")
    }
}

extension URL {
    func removingSKU() -> URL {
        var urlComponents = URLComponents(string: self.absoluteString)!
        let filteredItems = urlComponents.queryItems?.filter { $0.name != "sku" }
        urlComponents.queryItems = filteredItems
        return urlComponents.url!
    }
}
