import CoreLocation
import Foundation
import MapboxCommon
import MapboxDirections
import MapboxNavigationNative

public final class RouteInterfaceMock: RouteInterface {
    public static let realRequestUri =
        "https://api.mapbox.com/directions/v5/mapbox/driving/1.0,1.0;2.0,2.0?access_token=mock"

    public static let realRouteJson = {
        let encoder = JSONEncoder()
        let route = Route.mock()
        let jsonData = try! encoder.encode(route)
        return String(data: jsonData, encoding: .utf8)!
    }()

    public var routeId: String
    public var responseUuid: String
    public var routeIndex: UInt32
    public var responseJsonRef: MapboxCommon.DataRef
    public var requestUri: String
    public var routerOrigin: RouterOrigin
    public var routeInfo: RouteInfo
    public var waypoints: [MapboxNavigationNative.Waypoint]
    public var expirationTimeMs: NSNumber?
    public var lastRefreshTimestamp: Date?
    public var routeGeometry: [Coordinate2D]
    public var mapboxApi: MapboxAPI

    public init(
        routeId: String = UUID().uuidString,
        responseUuid: String = UUID().uuidString,
        routeIndex: UInt32 = 0,
        responseJsonRef: DataRef = .init(data: RouteInterfaceMock.realRouteJson.data(using: .utf8)!),
        requestUri: String = RouteInterfaceMock.realRequestUri,
        routerOrigin: RouterOrigin = .online,
        routeInfo: RouteInfo = .init(alerts: []),
        waypoints: [MapboxNavigationNative.Waypoint] = [],
        expirationTimeMs: NSNumber? = nil,
        lastRefreshTimestamp: Date? = nil,
        routeGeometry: [Coordinate2D] = [],
        mapboxApi: MapboxAPI = .directions
    ) {
        self.routeId = routeId
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

    public func getResponseJsonRef() -> MapboxCommon.DataRef { responseJsonRef }

    public func getRequestUri() -> String { requestUri }

    public func getRouterOrigin() -> RouterOrigin { routerOrigin }

    public func getRouteInfo() -> RouteInfo { routeInfo }

    public func getWaypoints() -> [MapboxNavigationNative.Waypoint] { waypoints }

    public func getExpirationTimeMs() -> NSNumber? { expirationTimeMs }

    public func getLastRefreshTimestamp() -> Date? { lastRefreshTimestamp }

    public func getRouteGeometry() -> [Coordinate2D] { routeGeometry }

    public func getMapboxAPI() -> MapboxAPI { mapboxApi }
}
