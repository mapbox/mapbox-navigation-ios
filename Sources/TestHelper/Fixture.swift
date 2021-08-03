import Foundation
import CoreLocation
import MapboxDirections
import UIKit.UIImage
@testable import MapboxCoreNavigation

public class Fixture: NSObject {
    public class var bundle: Bundle {
        get {
            #if SWIFT_PACKAGE
            return .module
            #else
            return Bundle(for: self)
            #endif
        }
    }
    
    public class func stringFromFileNamed(name: String) -> String {
        guard let path = bundle.path(forResource: name, ofType: "json") else {
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
    
    public class func JSONFromFileNamed(name: String) -> Data {
        guard let path = bundle.path(forResource: name, ofType: "json") else {
            preconditionFailure("Fixture \(name) not found.")
        }
        guard let data = NSData(contentsOfFile: path) as Data? else {
            preconditionFailure("No data found at \(path).")
        }
        return data
    }

    public static func image(named imageName: String) -> UIImage {
        guard let image = UIImage(named: imageName, in: bundle, compatibleWith: nil) else {
            preconditionFailure("Fixture image \(imageName) not found.")
        }
        return image
    }
    
    public class func downloadRouteFixture(coordinates: [CLLocationCoordinate2D], fileName: String, completion: @escaping () -> Void) {
        let accessToken = "<# Mapbox Access Token #>"
        let credentials = DirectionsCredentials(accessToken: accessToken)
        let directions = Directions(credentials: credentials)
        
        let options = RouteOptions(coordinates: coordinates, profileIdentifier: .automobileAvoidingTraffic)
        options.includesSteps = true
        options.routeShapeResolution = .full
        let filePath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
        
        _ = directions.calculate(options, completionHandler: { (session, result) in
            guard case let .success(response) = result else { return }
 
            guard let routes = response.routes, !routes.isEmpty else { return }
            print("Route downloaded to \(filePath)")
            completion()
        })
    }
    
    public class var blankStyle: URL {
        let path = bundle.path(forResource: "EmptyStyle", ofType: "json")
        return URL(fileURLWithPath: path!)
    }
    
    public class func locations(from name: String) -> [CLLocation] {
        let data = JSONFromFileNamed(name: name)
        
        let locations = try! JSONDecoder().decode([Location].self, from: data)
        
        return locations.map { CLLocation($0) }
    }
    
    public class func routeResponse(from jsonFile: String, options: RouteOptions) -> RouteResponse {
        let responseData = JSONFromFileNamed(name: jsonFile)
        do {
            let decoder = JSONDecoder()
            decoder.userInfo[.options] = options
            decoder.userInfo[.credentials] = Fixture.credentials
            let response = try decoder.decode(RouteResponse.self, from: responseData)
            
            // Like `Directions.postprocess(_:fetchStartDate:uuid:)`
            response.routes?.forEach {
                $0.routeIdentifier = response.identifier
                let fetchStartDate = Date(timeIntervalSince1970: 3600)
                $0.fetchStartDate = fetchStartDate
                $0.responseEndDate = Date(timeInterval: 1, since: fetchStartDate)
            }
            return response
        } catch {
            preconditionFailure("Unable to decode JSON fixture: \(error)")
        }
    }
    
    public class func mapMatchingResponse(from jsonFile: String, options: MatchOptions) -> MapMatchingResponse {
        let responseData = JSONFromFileNamed(name: jsonFile)
        do {
            let decoder = JSONDecoder()
            decoder.userInfo[.options] = options
            decoder.userInfo[.credentials] = Fixture.credentials
            return try decoder.decode(MapMatchingResponse.self, from: responseData)
        } catch {
            preconditionFailure("Unable to decode JSON fixture: \(error)")
        }
    }
    
    public class func routeResponseFromMatches(at filePath: String, options: MatchOptions) -> RouteResponse {
        options.shapeFormat = .polyline
        let response = mapMatchingResponse(from: filePath, options: options)
        return try! RouteResponse(matching: response, options: options, credentials: Fixture.credentials)
    }
    
    public class func route(from jsonFile: String, options: RouteOptions) -> Route {
        let response = routeResponse(from: jsonFile, options: options)
        guard let route = response.routes?.first else {
            preconditionFailure("No routes")
        }
        
        return route
    }
    
    public class func waypoints(from jsonFile: String, options: RouteOptions) -> [Waypoint] {
        let response = routeResponse(from: jsonFile, options: options)
        guard let waypoints = response.waypoints else {
            preconditionFailure("No waypoints")
        }
        return waypoints
    }
    
    // Returns `Route` objects from a match response
    public class func routesFromMatches(at filePath: String, options: MatchOptions) -> [Route]? {
        let routeResponse = routeResponseFromMatches(at: filePath, options: options)
        guard let routes = routeResponse.routes else {
            preconditionFailure("No routes")
        }
        return routes
    }
    
    public class func generateTrace(for route: Route, speedMultiplier: Double = 1) -> [CLLocation] {
        let traceCollector = TraceCollector()
        let locationManager = SimulatedLocationManager(route: route)
        locationManager.delegate = traceCollector
        locationManager.speedMultiplier = speedMultiplier
        
        while locationManager.currentDistance < route.distance {
            locationManager.tick()
        }
        
        return traceCollector.locations
    }
    
    public class func routeLegProgress() -> RouteLegProgress {
        let routeStep = RouteStep(transportType: .automobile,
                                  maneuverLocation: .init(),
                                  maneuverType: .arrive,
                                  instructions: "empty",
                                  drivingSide: .right,
                                  distance: 0.0,
                                  expectedTravelTime: 0.0)
        return RouteLegProgress(leg: RouteLeg(steps: [routeStep],
                                              name: "empty",
                                              distance: 0.0,
                                              expectedTravelTime: 0.0,
                                              profileIdentifier: .automobile))
    }

    public static let credentials: DirectionsCredentials = DirectionsCredentials(accessToken: "deadbeef", host: URL(string: "https://example.com")!)
}

class TraceCollector: NSObject, CLLocationManagerDelegate {
    var locations = [CLLocation]()
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locations.append(contentsOf: locations)
    }
}
