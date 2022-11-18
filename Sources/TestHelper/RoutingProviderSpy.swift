import CoreLocation
import MapboxCoreNavigation
import MapboxDirections

public class RoutingProviderSpy: RoutingProvider {
    public var calculateRoutesCalled = false
    public var refreshRoutesCalled = false

    public var passedRouteOptions: RouteOptions?
    public var passedMatchOptions: MatchOptions?
    public var passedIndexedRouteResponse: IndexedRouteResponse?
    public var passedFromLegAtIndex: UInt32?
    public var passedCurrentRouteShapeIndex: Int?
    public var passedCurrentLegShapeIndex: Int?

    public var returnedNavigationProviderRequest: NavigationProviderRequest?
    public var returnedRoutesResult: Result<IndexedRouteResponse, DirectionsError> = .failure(.unableToRoute)
    public var returnedDirectionsRoutesResult: Result<RouteResponse, DirectionsError> = .failure(.unableToRoute)
    public var returnedMapMatchingRoutesResult: Result<MapMatchingResponse, DirectionsError> = .failure(.unableToRoute)
    public var returnedRefreshResult: Result<RouteResponse, DirectionsError> = .failure(.unableToRoute)

    public var session: Directions.Session!

    public func calculateRoutes(options: RouteOptions,
                                completionHandler: @escaping IndexedRouteResponseCompletionHandler) -> NavigationProviderRequest? {
        calculateRoutesCalled = true
        passedRouteOptions = options
        completionHandler(returnedRoutesResult)
        return returnedNavigationProviderRequest
    }

    public func calculateRoutes(options: RouteOptions,
                                completionHandler: @escaping Directions.RouteCompletionHandler) -> NavigationProviderRequest? {
        calculateRoutesCalled = true
        passedRouteOptions = options
        completionHandler(session, returnedDirectionsRoutesResult)
        return returnedNavigationProviderRequest
    }

    public func calculateRoutes(options: MatchOptions,
                                completionHandler: @escaping MapboxDirections.Directions.MatchCompletionHandler) -> NavigationProviderRequest? {
        calculateRoutesCalled = true
        passedMatchOptions = options
        completionHandler(session, returnedMapMatchingRoutesResult)
        return returnedNavigationProviderRequest
    }

    public func refreshRoute(indexedRouteResponse: IndexedRouteResponse,
                             fromLegAtIndex: UInt32,
                             completionHandler: @escaping Directions.RouteCompletionHandler) -> NavigationProviderRequest? {
        refreshRoutesCalled = true
        passedIndexedRouteResponse = indexedRouteResponse
        passedFromLegAtIndex = fromLegAtIndex
        completionHandler(session, returnedRefreshResult)
        return returnedNavigationProviderRequest
    }

    public func refreshRoute(indexedRouteResponse: IndexedRouteResponse,
                             fromLegAtIndex: UInt32,
                             currentRouteShapeIndex: Int,
                             currentLegShapeIndex: Int,
                             completionHandler: @escaping Directions.RouteCompletionHandler) -> NavigationProviderRequest? {
        refreshRoutesCalled = true
        passedIndexedRouteResponse = indexedRouteResponse
        passedFromLegAtIndex = fromLegAtIndex
        passedCurrentRouteShapeIndex = currentRouteShapeIndex
        passedCurrentLegShapeIndex = currentLegShapeIndex
        completionHandler(session, returnedRefreshResult)
        return returnedNavigationProviderRequest
    }
    
    public init() {
        let routeOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 38.878206, longitude: -77.037265),
            CLLocationCoordinate2D(latitude: 38.910736, longitude: -76.966906),
        ])
        session = (options: routeOptions, credentials: .mocked)
    }

}
