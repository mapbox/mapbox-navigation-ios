import Foundation
import CoreLocation
import MapboxDirections
@testable import MapboxCoreNavigation


@objc(MBFixture)
public class Fixture: NSObject {
    public class func stringFromFileNamed(name: String) -> String {
        guard let path = Bundle(for: self).path(forResource: name, ofType: "json") else {
            assert(false, "Fixture \(name) not found.")
            return ""
        }
        do {
            return try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            assert(false, "Unable to decode fixture at \(path): \(error).")
            return ""
        }
    }
    
    @objc
    public class func JSONFromFileNamed(name: String) -> [String: Any] {
        guard let path = Bundle(for: Fixture.self).path(forResource: name, ofType: "json") else {
            assert(false, "Fixture \(name) not found.")
            return [:]
        }
        guard let data = NSData(contentsOfFile: path) as Data? else {
            assert(false, "No data found at \(path).")
            return [:]
        }
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        } catch {
            assert(false, "Unable to decode JSON fixture at \(path): \(error).")
            return [:]
        }
    }
    
    public class func downloadRouteFixture(coordinates: [CLLocationCoordinate2D], fileName: String, completion: @escaping () -> Void) {
        let accessToken = "<# Mapbox Access Token #>"
        let directions = Directions(accessToken: accessToken)
        
        let options = RouteOptions(coordinates: coordinates, profileIdentifier: .automobileAvoidingTraffic)
        options.includesSteps = true
        options.routeShapeResolution = .full
        let filePath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
        
        _ = directions.calculate(options, completionHandler: { (waypoints, routes, error) in
            guard let _ = routes?.first else { return }
            print("Route downloaded to \(filePath)")
            completion()
        })
    }
    
    public class var blankStyle: URL {
        let path = Bundle(for: self).path(forResource: "EmptyStyle", ofType: "json")
        return URL(fileURLWithPath: path!)
    }
    
    public class func locations(from name: String) -> [CLLocation] {
        guard let path = Bundle(for: Fixture.self).path(forResource: name, ofType: "json") else {
            assert(false, "Fixture \(name) not found.")
            return []
        }
        guard let data = NSData(contentsOfFile: path) as Data? else {
            assert(false, "No data found at \(path).")
            return []
        }
        
        let locations = try! JSONDecoder().decode([Location].self, from: data)
        
        return locations.map { CLLocation($0) }
    }
    
    @objc(routeFromJSONFileName:)
    public class func route(from jsonFile: String) -> Route {
        let response = JSONFromFileNamed(name: jsonFile)
        let waypoints = Fixture.waypoints(from: jsonFile)
        let jsonRoute = (response["routes"] as! [AnyObject]).first as! [String : Any]
        let route = Route(json: jsonRoute, waypoints: waypoints, options: NavigationRouteOptions(waypoints: waypoints))
        
        // Like `Directions.postprocess(_:fetchStartDate:uuid:)`
        route.routeIdentifier = response["uuid"] as? String
        let fetchStartDate = Date(timeIntervalSince1970: 3600)
        route.fetchStartDate = fetchStartDate
        route.responseEndDate = Date(timeInterval: 1, since: fetchStartDate)
        
        return route
    }
    
    public class func waypoints(from jsonFile: String) -> [Waypoint] {
        let response = JSONFromFileNamed(name: jsonFile)
        let waypointsArray = response["waypoints"] as! [[String: Any]]
        let waypoints = waypointsArray.map { (waypointDict) -> Waypoint in
            let location = waypointDict["location"] as! [CLLocationDegrees]
            let longitude = location[0]
            let latitude = location[1]
            return Waypoint(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        }
        return waypoints
    }
    
    // Returns `Route` objects from a match response
    public class func routesFromMatches(at filePath: String) -> [Route]? {
        let path = Bundle(for: Fixture.self).path(forResource: filePath, ofType: "json")
        let url = URL(fileURLWithPath: path!)
        let data = try! Data(contentsOf: url)
        let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        let tracepoints = json["tracepoints"] as! [Any]
        let coordinates = Array(repeating: CLLocationCoordinate2D(latitude: 0, longitude: 0), count: tracepoints.count)
        
        // Adapted from MatchOptions.response(containingRoutesFrom:) in MapboxDirections.
        let jsonWaypoints = json["tracepoints"] as! [Any]
        // Assume MatchOptions.waypointIndices contains the first and last indices only.
        let waypoints = [jsonWaypoints.first!, jsonWaypoints.last!].map { jsonWaypoint -> Waypoint in
            let jsonWaypoint = jsonWaypoint as! [String: Any]
            let location = jsonWaypoint["location"] as! [Double]
            let coordinate = CLLocationCoordinate2D(latitude: location[1], longitude: location[0])
            return Waypoint(coordinate: coordinate, name: jsonWaypoint["name"] as? String)
        }
        let opts = RouteOptions(coordinates: coordinates, profileIdentifier: .automobile)
        
        return (json["matchings"] as? [[String: Any]])?.map {
            Route(json: $0, waypoints: waypoints, options: opts)
        }
    }
    
    public class func generateTrace(for route: Route) -> [CLLocation] {
        
        let traceCollector = TraceCollector()
        let locationManager = SimulatedLocationManager(route: route)
        locationManager.delegate = traceCollector
        
        while locationManager.currentDistance < route.distance {
            locationManager.tick()
        }
        
        return traceCollector.locations
    }
}

class TraceCollector: NSObject, CLLocationManagerDelegate {
    
    var locations = [CLLocation]()
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locations.append(contentsOf: locations)
    }
}
