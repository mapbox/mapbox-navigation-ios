import MapboxDirections

/**
 
 */
public struct RoutePreviewOptions {
    
    /**
     
     */
    public let routeResponse: RouteResponse
    
    /**
     
     */
    public let routeIndex: Int
    
    /**
     
     */
    public init(routeResponse: RouteResponse, routeIndex: Int = 0) {
        self.routeResponse = routeResponse
        self.routeIndex = routeIndex
    }
}
