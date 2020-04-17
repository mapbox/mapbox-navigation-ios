import Foundation
import MapboxDirections

public class DirectionsSpy: Directions {
    public var lastCalculateOptionsCompletion: RouteCompletionHandler?
    
    override public func calculate(_ options: MatchOptions, completionHandler: @escaping Directions.MatchCompletionHandler) -> URLSessionDataTask {
        assert(false, "Not ready to handle \(#function)")
        return DummyURLSessionDataTask()
    }
    
    override public func calculate(_ options: RouteOptions, completionHandler: @escaping Directions.RouteCompletionHandler) -> URLSessionDataTask {
        lastCalculateOptionsCompletion = completionHandler
        return DummyURLSessionDataTask()
    }
    
    override public func calculateRoutes(matching options: MatchOptions, completionHandler: @escaping Directions.RouteCompletionHandler) -> URLSessionDataTask {
        assert(false, "Not ready to handle \(#function)")
        return DummyURLSessionDataTask()
    }
    
    public func fireLastCalculateCompletion(with waypoints: [Waypoint]?, routes: [Route]?, error: DirectionsError?) {
        let wpts = waypoints ?? []
        let options = RouteOptions(waypoints: wpts)
        
        let session: Directions.Session = (options: options, credentials: credentials)
        guard let lastCalculateOptionsCompletion = lastCalculateOptionsCompletion else {
            assert(false, "Can't fire a completion handler which doesn't exist!")
            return
        }
        
        if let error = error {
            lastCalculateOptionsCompletion(session, .failure(error))
        } else {
            let response = RouteResponse(httpResponse: nil, routes: routes, waypoints: waypoints, options: .route(options), credentials: credentials)
    
            lastCalculateOptionsCompletion(session, .success(response))
        }
}
    
    public convenience init() {
        self.init(credentials: Fixture.credentials)
    }
    
    public func reset() {
        lastCalculateOptionsCompletion = nil
    }
}
