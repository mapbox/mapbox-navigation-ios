import Foundation
import MapboxDirections
import MapboxCoreNavigation

class Fixture {
    internal class func JSONFromFileNamed(name: String) -> [String: Any] {
        guard let path = Bundle(for: self).path(forResource: name, ofType: "json") else {
            return [:]
        }
        guard let data = NSData(contentsOfFile: path) as Data? else {
            return [:]
        }
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        } catch {
            return [:]
        }
    }
    
    class func route(from url: URL) -> Route {
        let semaphore = DispatchSemaphore(value: 0)
        
        var json = [String: Any]()
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                assertionFailure("No route data")
                return
            }
            json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String : Any]
            semaphore.signal()
        }.resume()
        
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        
        return route(from: json)
    }
    
    class func route(from filename: String) -> Route {
        let response = Fixture.JSONFromFileNamed(name: filename)
        return route(from: response)
    }
    
    fileprivate class func route(from response: [String: Any]) -> Route {
        let jsonRoute = (response["routes"] as! [AnyObject]).first as! [String: Any]
        let jsonWaypoints = response["waypoints"] as! [[String: Any]]
        
        let waypoints: [Waypoint] = jsonWaypoints.map { (waypointDict) -> Waypoint in
            let locationDict = waypointDict["location"] as! [CLLocationDegrees]
            let coord = CLLocationCoordinate2D(latitude: locationDict[1], longitude: locationDict[0])
            return Waypoint(coordinate: coord)
        }
        
        let options = NavigationRouteOptions(waypoints: waypoints, profileIdentifier: .automobileAvoidingTraffic)
        let route = Route(json: jsonRoute, waypoints: waypoints, routeOptions: options)
        
        return route
    }
}
