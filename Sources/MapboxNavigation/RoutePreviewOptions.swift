import MapboxDirections

/**
 Customization options for the routes(s) preview using `RoutePreviewViewController` banner.
 */
public struct RoutePreviewOptions {
    
    /**
     `RouteResponse` object, that contains an array of the `Route` objects, details about which
     will be presented.
     */
    public let routeResponse: RouteResponse
    
    /**
     The index of the route within the original `RouteResponse` object.
     */
    public let routeIndex: Int
    
    /**
     Initializes a `RoutePreviewOptions` struct.
     
     - paramater routeResponse: `RouteResponse` object, that contains an array of the `Route` objects,
     details about which will be presented.
     - paramater routeIndex: The index of the route within the original `RouteResponse` object.
     */
    public init(routeResponse: RouteResponse, routeIndex: Int = 0) {
        self.routeResponse = routeResponse
        self.routeIndex = routeIndex
    }
}
