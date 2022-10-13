import MapboxDirections

// :nodoc:
public struct RoutesPreviewOptions {
    
    // :nodoc:
    public let routeResponse: RouteResponse
    
    // :nodoc:
    public let routeIndex: Int
    
    // :nodoc:
    public init(routeResponse: RouteResponse, routeIndex: Int = 0) {
        self.routeResponse = routeResponse
        self.routeIndex = routeIndex
    }
}
