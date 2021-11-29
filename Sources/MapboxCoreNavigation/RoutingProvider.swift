import Foundation
import MapboxDirections

/**
 Protocol which defines a type which can be used for fetching or refreshing routes.
 
 SDK provides conformance to this protocol for `Directions` and `MapboxRoutingProvider`.
 */
public protocol RoutingProvider {
    
    /**
     Routing caluclation method.
     
     - parameter options: A `RouteOptions` object specifying the requirements for the resulting routes.
     - parameter completionHandler: The closure (block) to call with the resulting routes. This closure is executed on the application’s main thread.
     - returns: Related request. If, while waiting for the completion handler to execute, you no longer want the resulting routes, cancel corresponding task using this handle.
     */
    @discardableResult func calculateRoutes(options: RouteOptions,
                                            completionHandler: @escaping Directions.RouteCompletionHandler) -> NavigationProviderRequest?
    
    /**
     Map matching calculation method.
     
     - parameter options: A `MatchOptions` object specifying the requirements for the resulting matches.
     - parameter completionHandler: The closure (block) to call with the resulting matches. This closure is executed on the application’s main thread.
     - returns: Related request. If, while waiting for the completion handler to execute, you no longer want the resulting routes, cancel corresponding task using this handle.
     */
    @discardableResult func calculateRoutes(options: MatchOptions,
                                            completionHandler: @escaping Directions.MatchCompletionHandler) -> NavigationProviderRequest?
    
    /**
     Route refreshing method.
     
     - parameter indexedRouteResponse: The `RouteResponse` and selected `routeIndex` in it to be refreshed.
     - parameter fromLegAtIndex: The index of the leg in the route at which to begin refreshing. The response will omit any leg before this index and refresh any leg from this index to the end of the route. If this argument is omitted, the entire route is refreshed.
     - parameter completionHandler: The closure (block) to call with updated `RouteResponse` data. Order of `routes` remain unchanged comparing to original `indexedRouteResponse`. This closure is executed on the application’s main thread.
     - returns: Related request. If, while waiting for the completion handler to execute, you no longer want the resulting routes, cancel corresponding task using this handle.
     */
    @discardableResult func refreshRoute(indexedRouteResponse: IndexedRouteResponse,
                                         fromLegAtIndex: UInt32,
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
