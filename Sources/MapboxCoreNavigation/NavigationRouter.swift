@_implementationOnly import MapboxCommon_Private
import MapboxDirections
import MapboxNavigationNative

/**
 Provides alternative access to routing API.
 
 Use this class instead `Directions` requests wrapper to request new routes or refresh an existing one. Depending on `RouterSource`, `NavigationRouter` will use online and/or onboard routing engines. This may be used when designing purely online or offline apps, or when you need to provide best possible service regardless of internet collection.
 */
public class NavigationRouter {
    /**
     Unique identifier for a giver request.
     
     Valid only for the same instance of `NavigationRouter` that issued it.
     */
    public typealias RequestId = UInt64
    
    /**
     A request handler for the ongoing router action.
     
     You can use this instance to cancel ongoing task if needed. Retaining this handler will keep related `NavigationRouter` from deallocating.
     */
    public struct RoutingRequest {
        /**
         Related request identifier.
         */
        public let id: RequestId
        
        // Intended retain cycle to prevent deallocating. `RoutingRequest` will be deleted once request completes.
        let router: NavigationRouter
        
        /**
         Cancels the request if it is still active.
         */
        public func cancel() {
            router.finish(request: id)
        }
    }
    
    /**
     Defines source of routing engine to be used for requests.
     */
    public enum RouterSource {
        /**
         Fetch data online only
         
         Such `NavigationRouter` is equivalent of using bare `Directions` wrapper.
         */
        case online
        /**
         Use online data only
         
         In order for such `NavigationRouter` to function properly, proper navigation data should be available onboard. `.offline` router will not be able to refresh routes.
         */
        case offline
        /**
         Attempts to use `online` with fallback to `offline`.
         
         `.hybrid` router will be able to refresh routes only using internet connection.
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
    
    static var __testRoutesStub: ((_: RouteOptions, _: @escaping Directions.RouteCompletionHandler) -> RequestId)? = nil
    
    // MARK: - Properties
    /**
     List of ongoing tasks for the router.
     
     You can see if router is busy with somethin, or used related `RoutingRequest.cancel()` to cancel requests as needed.
     */
    public private(set) var activeRequests: [RequestId : RoutingRequest] = [:]
    /**
     Configured routing engine source.
     */
    public let source: RouterSource
    
    private let requestsLock = NSLock()
    private let router: RouterInterface
    private let settings: NavigationSettings
    
    //MARK: - Initialization
    
    /**
     Initializes new `NavigationRouter`.
     
     - parameter source: routing engine source to use.
     - parameter settings: settings object, used to get credentials and cache configuration.
     */
    public init(_ source: RouterSource = .hybrid, settings: NavigationSettings = .shared) {
        self.source = source
        self.settings = settings
        
        let factory = NativeHandlersFactory(tileStorePath: settings.tileStoreConfiguration.navigatorLocation.tileStoreURL?.path ?? "",
                                            credentials: settings.directions.credentials)
        self.router = MapboxNavigationNative.RouterFactory.build(for: source.nativeSource,
                                                                 cache: factory.cacheHandle,
                                                                 historyRecorder: factory.historyRecorder)
    }
    
    // MARK: - Public methods
    
    /**
     Begins asynchronously calculating routes using the given options and delivers the results to a closure.
     
     Depending on configured `RouterSource`, this method may retrieve the routes asynchronously from the [Mapbox Directions API](https://www.mapbox.com/api-documentation/navigation/#directions) over a network connection or use onboard routing engine with available offline data.
     
     Routes may be displayed atop a [Mapbox map](https://www.mapbox.com/maps/).
     
     - parameter options: A `RouteOptions` object specifying the requirements for the resulting routes.
     - parameter completionHandler: The closure (block) to call with the resulting routes. This closure is executed on the application’s main thread.
     - returns: Related request identifier. If, while waiting for the completion handler to execute, you no longer want the resulting routes, cancel corresponding task using `activeRequests`.
     */
    @discardableResult public func requestRoutes(options: RouteOptions,
                                                 completionHandler: @escaping Directions.RouteCompletionHandler) -> RequestId {
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
     - returns: Related request identifier. If, while waiting for the completion handler to execute, you no longer want the resulting routes, cancel corresponding task using `activeRequests`.
     */
    @discardableResult public func requestRoutes(options: MatchOptions,
                                                 completionHandler: @escaping Directions.MatchCompletionHandler) -> RequestId {
        return doRequest(options: options) { (result: Result<MapMatchingResponse, DirectionsError>) in
            let session = (options: options as DirectionsOptions,
                           credentials: self.settings.directions.credentials)
            completionHandler(session, result)
        }
    }
    
    /**
     Begins asynchronously refreshing the selected route, optionally starting from an arbitrary leg.
     
     This method retrieves skeleton route data asynchronously from the Mapbox Directions Refresh API over a network connection. If a connection error or server error occurs, details about the error are passed into the given completion handler in lieu of the routes.
     
     - precondition: Set `RouteOptions.refreshingEnabled` to `true` when calculating the original route.
     
     - parameter indexedRouteResponse: The `RouteResponse` and selected `routeIndex` in it to be refreshed.
     - parameter fromLegAtIndex: The index of the leg in the route at which to begin refreshing. The response will omit any leg before this index and refresh any leg from this index to the end of the route. If this argument is omitted, the entire route is refreshed.
     - parameter completionHandler: The closure (block) to call with updated `RouteResponse` data. Order of `routes` remain unchanged comparing to original `indexedRouteResponse`. This closure is executed on the application’s main thread.
     - returns: Related request identifier. If, while waiting for the completion handler to execute, you no longer want the resulting routes, cancel corresponding task using `activeRequests`.
     */
    @discardableResult public func refreshRoute(indexedRouteResponse: IndexedRouteResponse,
                                                fromLegAtIndex startLegIndex: UInt32 = 0,
                                                completionHandler: @escaping Directions.RouteCompletionHandler) -> RequestId {
        guard case let .route(routeOptions) = indexedRouteResponse.routeResponse.options,
              let responseIdentifier = indexedRouteResponse.routeResponse.identifier else {
            preconditionFailure("Invalid route data passed for refreshing.")
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
        requestsLock.lock()
        requestId = router.getRouteRefresh(for: refreshOptions,
                                           route: routeJSONString) { [weak self] result, _ in
            guard let self = self else { return }
            
            self.parseResponse(requestId: requestId,
                               userInfo: [.options: routeOptions,
                                          .credentials: self.settings.directions.credentials],
                               result: result) { (response: Result<RouteResponse, DirectionsError>) in
                let session = (options: routeOptions as DirectionsOptions,
                               credentials: self.settings.directions.credentials)
                completionHandler(session, response)
            }
        }
        activeRequests[requestId] = .init(id: requestId,
                                          router: self)
        requestsLock.unlock()
        return requestId
    }
    
    // MARK: - Private methods
    
    fileprivate func finish(request id: RequestId) {
        requestsLock.lock(); defer {
            requestsLock.unlock()
        }
        
        router.cancelRequest(forToken: id)
        activeRequests[id] = nil
    }
    
    fileprivate func complete(requestId: RequestId, with result: @escaping () -> Void) {
        DispatchQueue.main.async {
            result()
            self.finish(request: requestId)
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
    
    fileprivate func parseResponse<ResponseType: Codable>(requestId: RequestId, userInfo: [CodingUserInfoKey : Any], result: Expected<AnyObject, AnyObject>, completion: @escaping (Result<ResponseType, DirectionsError>) -> Void) {
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
    
    fileprivate func doRequest<ResponseType: Codable>(options: DirectionsOptions,
                                                      completion: @escaping (Result<ResponseType, DirectionsError>) -> Void) -> RequestId {
        let directionsUri = settings.directions.url(forCalculating: options).absoluteString
        var requestId: RequestId!
        requestsLock.lock()
        requestId = router.getRouteForDirectionsUri(directionsUri) { [weak self] (result, _) in
            guard let self = self else { return }
            
            self.parseResponse(requestId: requestId,
                               userInfo: [.options: options,
                                          .credentials: self.settings.directions.credentials],
                                          result: result,
                                          completion: completion)
        }
        activeRequests[requestId] = .init(id: requestId,
                                          router: self)
        requestsLock.unlock()
        return requestId
    }
}

extension DirectionsProfileIdentifier {
    var nativeProfile: RoutingProfile {
        return RoutingProfile(profile: rawValue)
    }
}
