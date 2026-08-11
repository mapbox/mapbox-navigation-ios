import CoreLocation
import Foundation
import MapboxCommon
import MapboxDirections
import MapboxNavigationNative_Private

public final class RouteInterfaceMock: RouteInterface {
    public static let realRequestUri =
        "https://api.mapbox.com/directions/v5/mapbox/driving/1.0,1.0;2.0,2.0?access_token=mock"

    static func makeRoutesOptions(with route: Route) -> RouteOptions {
        let source = route.legs[0].source?.coordinate ?? route.legs[0].steps[0].maneuverLocation
        var waypoints = [Waypoint(coordinate: source)]
        waypoints += route.legs.compactMap { $0.destination }
        return RouteOptions(waypoints: waypoints)
    }

    static func makeRoutesJson(with routes: [Route], optionsRoute: Route? = nil) -> String {
        let encoder = JSONEncoder()
        let routeOptions = makeRoutesOptions(with: optionsRoute ?? routes[0])
        var routeResponse = RouteResponse(httpResponse: nil, options: .route(routeOptions), credentials: .mock())
        routeResponse.routes = routes
        let jsonData = try! encoder.encode(routeResponse)
        return String(data: jsonData, encoding: .utf8)!
    }

    public static func makeRoutesJson(route: Route, alternativeRoute: Route? = nil) -> String {
        var routes = [route]
        if let alternativeRoute {
            routes.append(alternativeRoute)
        }
        return makeRoutesJson(with: routes)
    }

    public static let realRouteJson = RouteInterfaceMock.makeRoutesJson(route: .mock())

    /// A stand-in route occupying the positions of a mocked Directions response that the mock itself does
    /// not represent.
    ///
    /// It is deliberately recognizable: if production resolves a route by the wrong index — reading
    /// `routes.first` of a full response, or `routes[getRouteIndex()]` of a ``toJson()`` response —
    /// assertions fail mentioning `"filler"` instead of silently comparing two identical `Route.mock()`s.
    public static let fillerRoute: Route = .mock(legs: [.mock(name: "filler")])

    /// Builds the `routes` array of a mocked Directions response in which `route` sits at `routeIndex`.
    ///
    /// Preceding positions are filled with ``fillerRoute``, keeping ``getRouteIndex()``,
    /// ``getResponseJsonRef()`` and ``toJson()`` mutually consistent, as they are in Navigation Native.
    public static func makeRoutes(placing route: Route, at routeIndex: Int) -> [Route] {
        precondition(routeIndex >= 0, "A route index of a mocked route must not be negative.")
        return [Route](repeating: fillerRoute, count: routeIndex) + [route]
    }

    public var routeId: String
    public var responseUuid: String
    public var routeIndex: UInt32
    public var responseJsonRef: DataRef
    public var requestUri: String
    public var routerOrigin: RouterOrigin
    public var routeInfo: RouteInfo
    public var waypoints: [MapboxNavigationNative_Private.Waypoint]
    public var expirationTimeMs: NSNumber?
    public var lastRefreshTimestamp: Date?
    public var routeGeometry: [Coordinate2D]
    public var mapboxApi: MapboxAPI

    /// Creates a mock of a route located at `routeIndex` of its Directions response.
    ///
    /// The response JSON is built so `routes[routeIndex]` is `route` (see ``makeRoutes(placing:at:)``),
    /// so ``toJson()`` always returns `route`.
    public convenience init(
        route: Route,
        routeId: String? = nil,
        routeIndex: Int = 0,
        mapboxApi: MapboxAPI = .directions
    ) {
        let routes = RouteInterfaceMock.makeRoutes(placing: route, at: routeIndex)
        let json = RouteInterfaceMock.makeRoutesJson(with: routes, optionsRoute: route)
        let options = RouteInterfaceMock.makeRoutesOptions(with: route)
        self.init(
            routeId: routeId,
            routeIndex: UInt32(routeIndex),
            responseJsonRef: .init(data: json.data(using: .utf8)!),
            requestUri: Directions.url(forCalculating: options, credentials: .mock()).absoluteString,
            mapboxApi: mapboxApi
        )
    }

    /// Creates a mock of an alternative route located at `routeIndex` of a Directions response that also
    /// contains `mainRoute`.
    ///
    /// - important: ``toJson()`` returns `alternativeRoute`, not `mainRoute` — as Navigation Native does
    /// for an alternative route.
    public convenience init(
        mainRoute: Route,
        alternativeRoute: Route,
        routeId: String? = nil,
        routeIndex: Int = 1,
        mapboxApi: MapboxAPI = .directions
    ) {
        var routes = RouteInterfaceMock.makeRoutes(placing: alternativeRoute, at: routeIndex)
        // The response an alternative comes from always contains the main route as well.
        if routeIndex == 0 {
            routes.append(mainRoute)
        } else {
            routes[0] = mainRoute
        }
        let json = RouteInterfaceMock.makeRoutesJson(with: routes, optionsRoute: alternativeRoute)
        let options = RouteInterfaceMock.makeRoutesOptions(with: alternativeRoute)
        self.init(
            routeId: routeId,
            routeIndex: UInt32(routeIndex),
            responseJsonRef: .init(data: json.data(using: .utf8)!),
            requestUri: Directions.url(forCalculating: options, credentials: .mock()).absoluteString,
            mapboxApi: mapboxApi
        )
    }

    public init(
        routeId: String? = nil,
        responseUuid: String = UUID().uuidString,
        routeIndex: UInt32 = 0,
        responseJsonRef: DataRef = .init(data: RouteInterfaceMock.realRouteJson.data(using: .utf8)!),
        requestUri: String = RouteInterfaceMock.realRequestUri,
        routerOrigin: RouterOrigin = .online,
        routeInfo: RouteInfo = .init(alerts: []),
        waypoints: [MapboxNavigationNative_Private.Waypoint] = [],
        expirationTimeMs: NSNumber? = nil,
        lastRefreshTimestamp: Date? = nil,
        routeGeometry: [Coordinate2D] = [],
        mapboxApi: MapboxAPI = .directions
    ) {
        self.routeId = routeId ?? "\(responseUuid)#\(routeIndex)"
        self.responseUuid = responseUuid
        self.routeIndex = routeIndex
        self.responseJsonRef = responseJsonRef
        self.requestUri = requestUri
        self.routerOrigin = routerOrigin
        self.routeInfo = routeInfo
        self.waypoints = waypoints
        self.expirationTimeMs = expirationTimeMs
        self.lastRefreshTimestamp = lastRefreshTimestamp
        self.routeGeometry = routeGeometry
        self.mapboxApi = mapboxApi
    }

    public func getRouteId() -> String { routeId }

    public func getResponseUuid() -> String { responseUuid }

    public func getRouteIndex() -> UInt32 { routeIndex }

    public func getResponseJsonRef() -> DataRef { responseJsonRef }

    /// Emulates `RouteInterface.toJson()` of Navigation Native: a Directions-shaped response which contains
    /// exactly one route — `routes[routeIndex]` of ``responseJsonRef`` — plus the original response uuid,
    /// waypoints and options.
    ///
    /// The value is always derived from the current ``responseJsonRef`` / ``routeIndex`` pair, so the two
    /// representations cannot drift apart. If that pair is inconsistent (``responseJsonRef`` is not a JSON
    /// object, carries no `routes` array, or ``routeIndex`` is out of its bounds) an empty payload is
    /// returned: the SDK then fails to parse the route exactly as it would for a malformed native
    /// response, so a mock with a wrong index/JSON pairing fails tests instead of silently resolving to a
    /// different route.
    public func toJson() -> DataRef {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: responseJsonRef.data),
              var response = jsonObject as? [String: Any],
              let routes = response["routes"] as? [Any],
              routes.indices.contains(Int(routeIndex))
        else {
            return .init(data: Data())
        }
        response["routes"] = [routes[Int(routeIndex)]]
        guard let data = try? JSONSerialization.data(withJSONObject: response) else {
            return .init(data: Data())
        }
        return .init(data: data)
    }

    public func getRequestUri() -> String { requestUri }

    public func getRouterOrigin() -> RouterOrigin { routerOrigin }

    public func getRouteInfo() -> RouteInfo { routeInfo }

    public func getWaypoints() -> [MapboxNavigationNative_Private.Waypoint] { waypoints }

    public func getExpirationTimeMs() -> NSNumber? { expirationTimeMs }

    public func getLastRefreshTimestamp() -> Date? { lastRefreshTimestamp }

    public func getRouteGeometry() -> [Coordinate2D] { routeGeometry }

    public func getMapboxAPI() -> MapboxAPI { mapboxApi }

    public func getDirectionsRouteContext() -> DirectionsRouteContext {
        fatalError("getDirectionsRouteContext should not be called in tests")
    }
}
