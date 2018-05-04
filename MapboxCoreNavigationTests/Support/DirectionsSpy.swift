import Foundation
import MapboxDirections

@objc(MBDirectionsSpy)
class DirectionsSpy: Directions {
    
    var lastCalculateOptionsCompletion: RouteCompletionHandler?
    
    override func calculate(_ options: MatchOptions, completionHandler: @escaping Directions.MatchCompletionHandler) -> URLSessionDataTask {
        assert(false, "Not ready to handle \(#function)")
        return DummyURLSessionDataTask()
    }
    
    override func calculate(_ options: RouteOptions, completionHandler: @escaping Directions.RouteCompletionHandler) -> URLSessionDataTask {
        lastCalculateOptionsCompletion = completionHandler
        return DummyURLSessionDataTask()
    }
    
    override func calculateRoutes(matching options: MatchOptions, completionHandler: @escaping Directions.RouteCompletionHandler) -> URLSessionDataTask {
        assert(false, "Not ready to handle \(#function)")
        return DummyURLSessionDataTask()
    }
    
    public func fireLastCalculateCompletion(with waypoints: [Waypoint]?, routes: [Route]?, error: NSError?) {
        guard let lastCalculateOptionsCompletion = lastCalculateOptionsCompletion else {
            assert(false, "Can't fire a completion handler which doesn't exist!")
            return
        }

        lastCalculateOptionsCompletion(waypoints, routes, error)
    }
    
    public func reset() {
        lastCalculateOptionsCompletion = nil
    }
}
