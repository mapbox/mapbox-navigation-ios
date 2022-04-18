import MapboxDirections

public struct RoutesPreviewOptions {
    
    var routeResponse: RouteResponse
    
    var routeIndex: Int
    
    public init(routeResponse: RouteResponse, routeIndex: Int = 0) {
        self.routeResponse = routeResponse
        self.routeIndex = routeIndex
    }
}
