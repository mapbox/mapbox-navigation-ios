import XCTest
import Foundation
import MapboxDirections
import CoreLocation

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

    class func routeWithBannerInstructions() -> Route {
        return route(from: "route-with-banner-instructions", waypoints: [Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165)), Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))])
    }
}
