import XCTest
import Foundation
import CoreLocation
import MapboxDirections

internal class Fixture {
    internal class func stringFromFileNamed(name: String) -> String {
        guard let path = Bundle(for: self).path(forResource: name, ofType: "json") else {
            XCTAssert(false, "Fixture \(name) not found.")
            return ""
        }
        do {
            return try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            XCTAssert(false, "Unable to decode fixture at \(path): \(error).")
            return ""
        }
    }
    
    internal class func JSONFromFileNamed(name: String) -> [String: Any] {
        guard let path = Bundle(for: self).path(forResource: name, ofType: "json") else {
            XCTAssert(false, "Fixture \(name) not found.")
            return [:]
        }
        guard let data = NSData(contentsOfFile: path) as Data? else {
            XCTAssert(false, "No data found at \(path).")
            return [:]
        }
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        } catch {
            XCTAssert(false, "Unable to decode JSON fixture at \(path): \(error).")
            return [:]
        }
    }
    
    class func downloadRouteFixture(coordinates: [CLLocationCoordinate2D], fileName: String, completion: @escaping () -> Void) {
        let accessToken = "<# Mapbox Access Token #>"
        let directions = Directions(accessToken: accessToken)
        
        let options = RouteOptions(coordinates: coordinates, profileIdentifier: .automobileAvoidingTraffic)
        options.includesSteps = true
        options.routeShapeResolution = .full
        let filePath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
        
        _ = directions.calculate(options, completionHandler: { (waypoints, routes, error) in
            guard let route = routes?.first else { return }
            
            NSKeyedArchiver.archiveRootObject(route, toFile: filePath)
            print("Route downloaded to \(filePath)")
            completion()
        })
    }
    
    class var blankStyle: URL {
        let path = Bundle(for: self).path(forResource: "EmptyStyle", ofType: "json")
        return URL(fileURLWithPath: path!)
    }
    
    class func route(from jsonFile: String, waypoints: [Waypoint]) -> Route {
        let response = JSONFromFileNamed(name: jsonFile)
        let jsonRoute = (response["routes"] as! [AnyObject]).first as! [String : Any]
        return Route(json: jsonRoute, waypoints: waypoints, options: RouteOptions(waypoints: waypoints))
    }
    
    // Returns `Route` objects from a match response
    class func routesFromMatches(at filePath: String) -> [Route]? {
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

    class func routeWithBannerInstructions() -> Route {
        return route(from: "route-with-banner-instructions", waypoints: [Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165)), Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))])
    }
}
