import MapboxCommon_Private
import MapboxNavigationNative
import MapboxNavigationNative_Private

struct RouteParserClient: Sendable {
    var createRoutesData: @Sendable (_ primaryRoute: any RouteInterface, _ alternativeRoutes: [any RouteInterface])
        -> any RoutesData
    var parseDirectionsRoutesForResponse: @Sendable (
        _ forResponse: String,
        _ request: String,
        _ routeOrigin: RouterOrigin
    ) -> Expected<NSArray, NSString>
    var parseDirectionsRoutesForResponseWithCallback: @Sendable (
        _ forResponse: String,
        _ request: String,
        _ routeOrigin: RouterOrigin,
        _ callback: @escaping RouteParserCallback
    ) -> Void
    var parseDirectionsResponseForResponseDataRef: @Sendable (
        _ responseDataRef: DataRef,
        _ request: String,
        _ routeOrigin: RouterOrigin
    ) -> Expected<NSArray, NSString>
    var parseDirectionsResponseForResponseDataRefWithCallback: @Sendable (
        _ responseDataRef: DataRef,
        _ request: String,
        _ routeOrigin: RouterOrigin,
        _ callback: @escaping RouteParserCallback
    ) -> Void
    var parseMapMatchingResponseForResponseDataRef: @Sendable (
        _ responseDataRef: DataRef,
        _ request: String,
        _ routeOrigin: RouterOrigin
    ) -> Expected<NSArray, NSString>
    var parseMapMatchingResponseForResponseDataRefWithCallback: @Sendable (
        _ responseDataRef: DataRef,
        _ request: String,
        _ routeOrigin: RouterOrigin,
        _ callback: @escaping RouteParserCallback
    ) -> Void
}

extension RouteParserClient {
    static var liveValue: RouteParserClient {
        Self(
            createRoutesData: { primaryRoute, alternativeRoutes in
                RouteParser.createRoutesData(forPrimaryRoute: primaryRoute, alternativeRoutes: alternativeRoutes)
            },
            parseDirectionsRoutesForResponse: { response, request, routeOrigin in
                RouteParser.parseDirectionsRoutes(forResponse: response, request: request, routeOrigin: routeOrigin)
            },
            parseDirectionsRoutesForResponseWithCallback: { response, request, routeOrigin, callback in
                RouteParser.parseDirectionsRoutes(
                    forResponse: response,
                    request: request,
                    routeOrigin: routeOrigin,
                    callback: callback
                )
            },
            parseDirectionsResponseForResponseDataRef: { responseDataRef, request, routeOrigin in
                RouteParser.parseDirectionsResponse(
                    forResponseDataRef: responseDataRef,
                    request: request,
                    routeOrigin: routeOrigin
                )
            },
            parseDirectionsResponseForResponseDataRefWithCallback: { responseDataRef, request, routeOrigin, callback in
                RouteParser.parseDirectionsResponse(
                    forResponseDataRef: responseDataRef,
                    request: request,
                    routeOrigin: routeOrigin,
                    callback: callback
                )
            },
            parseMapMatchingResponseForResponseDataRef: { responseDataRef, request, routeOrigin in
                RouteParser.parseMapMatchingResponse(
                    forResponseDataRef: responseDataRef,
                    request: request,
                    routerOrigin: routeOrigin
                )
            },
            parseMapMatchingResponseForResponseDataRefWithCallback: { responseDataRef, request, routeOrigin, callback in
                RouteParser.parseMapMatchingResponse(
                    forResponseDataRef: responseDataRef,
                    request: request,
                    routerOrigin: routeOrigin,
                    callback: callback
                )
            }
        )
    }
}
