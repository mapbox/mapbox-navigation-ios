import CoreLocation
import MapboxDirections
import MapboxNavigationCore

public final class RoutingProviderSpy: RoutingProvider, @unchecked Sendable {
    public var calculateRouteOptionsCalled = false
    public var calculateMatchOptionsCalled = false

    public var passedRouteOptions: RouteOptions?
    public var passedMatchOptions: MatchOptions?

    var returnedRoutes: NavigationRoutes?
    var returnedError: Error?

    public func calculateRoutes(options: RouteOptions) -> Task<NavigationRoutes, Error> {
        calculateRouteOptionsCalled = true
        passedRouteOptions = options
        return Task {
            guard let returnedRoutes else {
                throw returnedError ?? DirectionsError.noData
            }
            return returnedRoutes
        }
    }

    public func calculateRoutes(options: MatchOptions) -> Task<NavigationRoutes, Error> {
        calculateMatchOptionsCalled = true
        passedMatchOptions = options
        return Task {
            guard let returnedRoutes else {
                throw returnedError ?? DirectionsError.noData
            }
            return returnedRoutes
        }
    }

    public func reset() {
        calculateRouteOptionsCalled = false
        calculateMatchOptionsCalled = false
        passedRouteOptions = nil
        passedMatchOptions = nil
    }
}
