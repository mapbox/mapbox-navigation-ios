import Foundation
import MapboxDirections

/**
 Protocol which defines a type which can be used for fetching or refreshing routes.
 
 SDK provides conformance to this protocol for `Directions` and `MapboxRoutingProvider`.
 */
public protocol RoutingProvider {
    
    typealias IndexedRouteResponseCompletionHandler = (_ result: Result<IndexedRouteResponse, DirectionsError>) -> Void
    
    /**
     Begins asynchronously calculating routes using the given options and delivers the results to a closure.
     
     - parameter options: A `RouteOptions` object specifying the requirements for the resulting routes.
     - parameter completionHandler: The closure (block) to call with the resulting routes. This closure is executed on the application’s main thread.
     - returns: Related request. If, while waiting for the completion handler to execute, you no longer want the resulting routes, cancel corresponding task using this handle.
     */
    @discardableResult func calculateRoutes(options: RouteOptions,
                                            completionHandler: @escaping IndexedRouteResponseCompletionHandler) -> NavigationProviderRequest?
    
    /**
     Begins asynchronously calculating routes using the given options and delivers the results to a closure.
     
     - parameter options: A `RouteOptions` object specifying the requirements for the resulting routes.
     - parameter completionHandler: The closure (block) to call with the resulting routes. This closure is executed on the application’s main thread.
     - returns: Related request. If, while waiting for the completion handler to execute, you no longer want the resulting routes, cancel corresponding task using this handle.
     */
    @available(*, deprecated, renamed: "calculateRoutes(options:completionHandler:)")
    @discardableResult func calculateRoutes(options: RouteOptions,
                                            completionHandler: @escaping Directions.RouteCompletionHandler) -> NavigationProviderRequest?
    
    /**
     Begins asynchronously calculating matches using the given options and delivers the results to a closure.
     
     - parameter options: A `MatchOptions` object specifying the requirements for the resulting matches.
     - parameter completionHandler: The closure (block) to call with the resulting matches. This closure is executed on the application’s main thread.
     - returns: Related request. If, while waiting for the completion handler to execute, you no longer want the resulting routes, cancel corresponding task using this handle.
     */
    @discardableResult func calculateRoutes(options: MatchOptions,
                                            completionHandler: @escaping Directions.MatchCompletionHandler) -> NavigationProviderRequest?
    
    /**
     Begins asynchronously refreshing the route with the given identifier, starting from an arbitrary leg along the route.
     
     - parameter indexedRouteResponse: The `RouteResponse` and selected `routeIndex` in it to be refreshed.
     - parameter fromLegAtIndex: The index of the leg in the route at which to begin refreshing. The response will omit any leg before this index and refresh any leg from this index to the end of the route. If this argument is `0`, the entire route is refreshed.
     - parameter completionHandler: The closure (block) to call with updated `RouteResponse` data. Order of `routes` remain unchanged comparing to original `indexedRouteResponse`. This closure is executed on the application’s main thread.
     - returns: Related request. If, while waiting for the completion handler to execute, you no longer want the resulting routes, cancel corresponding task using this handle.
     */
    @discardableResult func refreshRoute(indexedRouteResponse: IndexedRouteResponse,
                                         fromLegAtIndex: UInt32,
                                         completionHandler: @escaping Directions.RouteCompletionHandler) -> NavigationProviderRequest?

    /**
     Begins asynchronously refreshing the route with the given identifier, starting from an arbitrary leg and shape index along the route.

     - parameter indexedRouteResponse: The `RouteResponse` and selected `routeIndex` in it to be refreshed.
     - parameter fromLegAtIndex: The index of the leg in the route at which to begin refreshing. The response will omit any leg before this index and refresh any leg from this index to the end of the route.
     - parameter currentRouteShapeIndex: Index relative to route shape, representing the point the user is currently located at.
     - parameter currentRouteShapeIndex: Index relative to `fromLegAtIndex` leg shape, representing the point the user is currently located at.
     - parameter completionHandler: The closure (block) to call with updated `RouteResponse` data. Order of `routes` remain unchanged comparing to original `indexedRouteResponse`. This closure is executed on the application’s main thread.
     - returns: Related request. If, while waiting for the completion handler to execute, you no longer want the resulting routes, cancel corresponding task using this handle.
     */
    @discardableResult func refreshRoute(indexedRouteResponse: IndexedRouteResponse,
                                         fromLegAtIndex: UInt32,
                                         currentRouteShapeIndex: Int,
                                         currentLegShapeIndex: Int,
                                         completionHandler: @escaping Directions.RouteCompletionHandler) -> NavigationProviderRequest?
}

/**
 `RoutingProvider` request type.
 */
public protocol NavigationProviderRequest {
    /**
     Request identifier.
     
     Unique within related `RoutingProvider`.
     */
    var requestIdentifier: UInt64 { get }
    
    /**
     Cancels ongoing request if it didn't finish yet.
     */
    func cancel()
}
