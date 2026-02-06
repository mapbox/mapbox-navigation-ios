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

    static func makeRoutesJson(with routes: [Route]) -> String {
        let encoder = JSONEncoder()
        let route = routes[0]
        let routeOptions = makeRoutesOptions(with: route)
        var routeResponse = RouteResponse(httpResponse: nil, options: .route(routeOptions), credentials: .mock())
        routeResponse.routes = routes
        let jsonData = try! encoder.encode(routeResponse)
        return String(data: jsonData, encoding: .utf8)!
    }

    public static let realRouteJson = RouteInterfaceMock.makeRoutesJson(with: [.mock()])

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
    public var directionsRouteContextRef: DataRef

    public convenience init(
        route: Route,
        routeId: String? = nil,
        routeIndex: Int = 0
    ) {
        let json = RouteInterfaceMock.makeRoutesJson(with: [route])
        let options = RouteInterfaceMock.makeRoutesOptions(with: route)
        self.init(
            routeId: routeId,
            routeIndex: UInt32(routeIndex),
            responseJsonRef: .init(data: json.data(using: .utf8)!),
            requestUri: Directions.url(forCalculating: options, credentials: .mock()).absoluteString
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
        mapboxApi: MapboxAPI = .directions,
        directionsRouteContextRef: DataRef = DataRef(data: Data())
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
        self.directionsRouteContextRef = directionsRouteContextRef
    }

    public func getRouteId() -> String { routeId }

    public func getResponseUuid() -> String { responseUuid }

    public func getRouteIndex() -> UInt32 { routeIndex }

    public func getResponseJsonRef() -> DataRef { responseJsonRef }

    public func getRequestUri() -> String { requestUri }

    public func getRouterOrigin() -> RouterOrigin { routerOrigin }

    public func getRouteInfo() -> RouteInfo { routeInfo }

    public func getWaypoints() -> [MapboxNavigationNative_Private.Waypoint] { waypoints }

    public func getExpirationTimeMs() -> NSNumber? { expirationTimeMs }

    public func getLastRefreshTimestamp() -> Date? { lastRefreshTimestamp }

    public func getRouteGeometry() -> [Coordinate2D] { routeGeometry }

    public func getMapboxAPI() -> MapboxAPI { mapboxApi }

    public func getDirectionsRouteContextRef() -> DataRef { directionsRouteContextRef }
}
