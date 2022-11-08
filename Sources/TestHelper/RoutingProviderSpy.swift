import MapboxCoreNavigation
import MapboxDirections

public class RoutingProviderSpy: RoutingProvider {
    public var calculateRoutesCalled = false
    public var refreshRoutesCalled = false
    public var returnedNavigationProviderRequest: NavigationProviderRequest? = nil

    public func calculateRoutes(options: RouteOptions,
                                completionHandler: @escaping IndexedRouteResponseCompletionHandler) -> NavigationProviderRequest? {
        calculateRoutesCalled = true
        return returnedNavigationProviderRequest
    }

    public func calculateRoutes(options: RouteOptions,
                                completionHandler: @escaping Directions.RouteCompletionHandler) -> NavigationProviderRequest? {
        calculateRoutesCalled = true
        return returnedNavigationProviderRequest
    }

    public func calculateRoutes(options: MatchOptions,
                                completionHandler: @escaping MapboxDirections.Directions.MatchCompletionHandler) -> NavigationProviderRequest? {
        calculateRoutesCalled = true
        return returnedNavigationProviderRequest
    }

    public func refreshRoute(indexedRouteResponse:IndexedRouteResponse,
                             fromLegAtIndex: UInt32,
                             completionHandler: @escaping Directions.RouteCompletionHandler) -> NavigationProviderRequest? {
        refreshRoutesCalled = true
        return returnedNavigationProviderRequest
    }

    public func refreshRoute(indexedRouteResponse:IndexedRouteResponse,
                             fromLegAtIndex: UInt32,
                             currentRouteShapeIndex: Int,
                             currentLegShapeIndex: Int,
                             completionHandler: @escaping Directions.RouteCompletionHandler) -> NavigationProviderRequest? {
        refreshRoutesCalled = true
        return returnedNavigationProviderRequest
    }
    
    public init() {}

}
