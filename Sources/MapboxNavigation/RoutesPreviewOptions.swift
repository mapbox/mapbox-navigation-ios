import MapboxDirections

// :nodoc:
public struct RoutesPreviewOptions {
    
    // :nodoc:
    public var routeResponse: RouteResponse
    
    // :nodoc:
    public var routeIndex: Int
    
    // :nodoc:
    public init(routeResponse: RouteResponse, routeIndex: Int = 0) {
        self.routeResponse = routeResponse
        self.routeIndex = routeIndex
    }
}
