import CoreLocation
import MapboxDirections
@testable import MapboxCoreNavigation

public final class RouterDataSourceSpy: RouterDataSource {
    public var locationManagerType: NavigationLocationManager.Type = NavigationLocationManagerSpy.self

    public init() {}
}

final class RouterSpy: NSObject, Router {
    var delegate: MapboxCoreNavigation.RouterDelegate?

    var routingProviderSpy = RoutingProviderSpy()
    var routingProvider: MapboxCoreNavigation.RoutingProvider {
        return routingProviderSpy
    }

    var customRoutingProvider: RoutingProvider?
    var routeProgress: RouteProgress
    var dataSource: MapboxCoreNavigation.RouterDataSource
    var route: Route
    var indexedRouteResponse: IndexedRouteResponse

    var continuousAlternatives: [MapboxCoreNavigation.AlternativeRoute] = []

    var initialManeuverAvoidanceRadius = RerouteController.DefaultManeuverAvoidanceRadius

    var location: CLLocation?

    var rawLocation: CLLocation?

    var heading: CLHeading?

    var reroutesProactively = true

    var refreshesRoute = false

    // MARK: Spy properties

    var returnedUserIsOnRoute = true
    var returnedUpdateRouteResult = true
    var advanceLegResult: Result<RouteProgress, Error> = .failure(DirectionsError.noData)

    var passedIndexedRouteResponse: IndexedRouteResponse?
    var passedLocation: CLLocation?
    var passedRouteProgress: RouteProgress?
    var passedRouteOptions: RouteOptions?
    var passedLocations: [CLLocation]?
    var passedLocationManager: CLLocationManager?
    var passedHeading: CLHeading?

    var updateRouteCalled = false
    var advanceLegIndexCalled = false
    var finishRoutingCalled = false
    var rerouteCalled = false
    var didUpdateLocationsCalled = false
    var didUpdateHeadingCalled = false

    // MARK: Methods

    convenience init(alongRouteAtIndex routeIndex: Int,
                     in routeResponse: RouteResponse,
                     options: RouteOptions,
                     routingProvider: RoutingProvider,
                     dataSource source: RouterDataSource) {
        let indexedRouteResponse = IndexedRouteResponse(routeResponse: routeResponse, routeIndex: routeIndex)
        self.init(indexedRouteResponse: indexedRouteResponse,
                  customRoutingProvider: routingProvider,
                  dataSource: source)
    }

    convenience init(alongRouteAtIndex routeIndex: Int,
                     in routeResponse: RouteResponse,
                     options: RouteOptions,
                     customRoutingProvider: RoutingProvider?,
                     dataSource source: RouterDataSource) {
        let indexedRouteResponse = IndexedRouteResponse(routeResponse: routeResponse, routeIndex: routeIndex)
        self.init(indexedRouteResponse: indexedRouteResponse,
                  customRoutingProvider: customRoutingProvider,
                  dataSource: source)
    }

    init(indexedRouteResponse: IndexedRouteResponse,
         customRoutingProvider: RoutingProvider? = nil,
         dataSource source: RouterDataSource) {

        self.indexedRouteResponse = indexedRouteResponse
        self.customRoutingProvider = customRoutingProvider
        self.dataSource = source

        self.route = indexedRouteResponse.routeResponse.routes![indexedRouteResponse.routeIndex]
        self.routeProgress = RouteProgress(route: indexedRouteResponse.currentRoute!, options: indexedRouteResponse.validatedRouteOptions)
        super.init()
    }

    func userIsOnRoute(_ location: CLLocation) -> Bool {
        passedLocation = location
        return returnedUserIsOnRoute
    }

    func reroute(from location: CLLocation, along routeProgress: RouteProgress) {
        rerouteCalled = true
        passedLocation = location
        passedRouteProgress = routeProgress
    }

    func advanceLegIndex(completionHandler: AdvanceLegCompletionHandler?) {
        advanceLegIndexCalled = true
        completionHandler?(advanceLegResult)
    }

    func updateRoute(with indexedRouteResponse: IndexedRouteResponse, routeOptions: RouteOptions?, completion: ((Bool) -> Void)?) {
        updateRouteCalled = true
        passedIndexedRouteResponse = indexedRouteResponse
        passedRouteOptions = routeOptions
        completion?(returnedUpdateRouteResult)
    }

    func finishRouting() {
        finishRoutingCalled = true
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        didUpdateLocationsCalled = true
        passedLocationManager = manager
        passedLocations = locations
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        didUpdateHeadingCalled = true
        passedLocationManager = manager
        passedHeading = newHeading
    }

}
