import MapboxDirections
import XCTest
import MapboxNavigationNative

public final class TestRouteProvider {
    public static func createRoute() -> RouteInterface? {
        let route = Fixture.route(between: .init(latitude: 0, longitude: 0),
                                  and: .init(latitude: 1, longitude: 1))
        return createRoute(routeResponse: route.response)
    }

    public static func createRoute(routeResponse: RouteResponse) -> RouteInterface? {
        guard case let .route(routeOptions) = routeResponse.options else {
            XCTFail("Failed to generate test Route.")
            return nil
        }

        let encoder = JSONEncoder()
        encoder.userInfo[.options] = routeOptions
        guard let routeData = try? encoder.encode(routeResponse),
              let routeJSONString = String(data: routeData, encoding: .utf8) else {
            XCTFail("Failed to encode generated test Route.")
            return nil
        }
        let routeRequest = Directions(credentials: Fixture.credentials).url(forCalculating: routeOptions).absoluteString

        let parsedRoutes = RouteParser.parseDirectionsResponse(forResponse: routeJSONString,
                                                               request: routeRequest,
                                                               routeOrigin: RouterOrigin.custom)
        var generatedRoute: RouteInterface? = nil
        if parsedRoutes.isValue(),
           let validGeneratedRoute = (parsedRoutes.value as? [RouteInterface])?.first {
            generatedRoute = validGeneratedRoute
        } else if parsedRoutes.isError(),
                  let errorReason = parsedRoutes.error as String? {
            XCTFail("Failed to parse generated test route with error: \(errorReason).")
        } else {
            XCTFail("Failed to parse generated test route.")
        }

        return generatedRoute
    }
}
