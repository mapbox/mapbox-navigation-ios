import MapboxCoreNavigation
import MapboxDirections

public class RoutingProviderSpy: RoutingProvider {
    public func calculateRoutes(options: RouteOptions,
                                completionHandler: @escaping IndexedRouteResponseCompletionHandler) -> NavigationProviderRequest? {
        return nil
    }

    public func calculateRoutes(options: RouteOptions,
                                completionHandler: @escaping Directions.RouteCompletionHandler) -> NavigationProviderRequest? {
        return nil
    }

    public func calculateRoutes(options: MatchOptions,
                                completionHandler: @escaping MapboxDirections.Directions.MatchCompletionHandler) -> NavigationProviderRequest? {
        return nil
    }

    public func refreshRoute(indexedRouteResponse:IndexedRouteResponse,
                             fromLegAtIndex: UInt32,
                             completionHandler: @escaping Directions.RouteCompletionHandler) -> NavigationProviderRequest? {
        return nil
    }

    public func refreshRoute(indexedRouteResponse:IndexedRouteResponse,
                             fromLegAtIndex: UInt32,
                             currentRouteShapeIndex: Int,
                             currentLegShapeIndex: Int,
                             completionHandler: @escaping Directions.RouteCompletionHandler) -> NavigationProviderRequest? {
        return nil
    }

    public init() {}

}
