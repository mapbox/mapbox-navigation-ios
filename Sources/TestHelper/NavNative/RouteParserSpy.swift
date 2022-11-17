import MapboxNavigationNative
@_implementationOnly import MapboxCommon_Private
@_implementationOnly import MapboxNavigationNative_Private

public final class RouteParserSpy: RouteParser  {
    public static var returnedRoutes: [RouteInterface]?
    public static var returnedError: String?

    @_implementationOnly
    public override class func parseDirectionsResponse(forResponse response: String,
                                                       request: String,
                                                       routeOrigin: RouterOrigin) -> Expected<NSArray, NSString> {
        if returnedRoutes == nil && returnedError == nil {
            return RouteParser.parseDirectionsRoutes(forResponse: response, request: request, routeOrigin: routeOrigin)
        }
        return returnedRoutes != nil ? Expected(value: (returnedRoutes ?? []) as NSArray) :
            Expected(error: (returnedError ?? "") as NSString)
    }
}
