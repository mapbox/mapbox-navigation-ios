import Foundation
import CoreLocation
import MapboxDirections
import Turf
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
    
    public static func color(named colorName: String) -> UIColor {
        guard let color = UIColor(named: colorName, in: bundle, compatibleWith: nil) else {
            preconditionFailure("Fixture color \(colorName) not found.")
        }
        return color
    }
    
    public class func downloadRouteFixture(coordinates: [CLLocationCoordinate2D], fileName: String, completion: @escaping () -> Void) {
        let accessToken = "<# Mapbox Access Token #>"
        let credentials = Credentials(accessToken: accessToken)
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
        
        while locationManager.currentDistance < route.shape?.distance() ?? 0 {
            locationManager.tick()
        }
        
        return traceCollector.locations
    }
    
    public class func routeLegProgress(expectedTravelTime: TimeInterval = 0.0,
                                       stepDistance: Turf.LocationDistance = 0.0,
                                       stepCount: Int = 1) -> RouteLegProgress {
        var steps = [RouteStep]()
        for i in 0..<stepCount {
            let maneuverType: ManeuverType = i == stepCount - 1 ? .arrive : i == 0 ? .depart : .turn
            steps.append(RouteStep(transportType: .automobile,
                                   maneuverLocation: .init(),
                                   maneuverType: maneuverType,
                                   instructions: "empty",
                                   drivingSide: .right,
                                   distance: stepDistance,
                                   expectedTravelTime: expectedTravelTime))
        }
        return RouteLegProgress(leg: RouteLeg(steps: steps,
                                              name: "empty",
                                              distance: 0.0,
                                              expectedTravelTime: expectedTravelTime,
                                              profileIdentifier: .automobile))
    }

    public class func makeVisualInstruction(maneuverType: ManeuverType = .arrive,
                                            maneuverDirection: ManeuverDirection = .left,
                                            primaryInstruction: [VisualInstruction.Component] = [],
                                            secondaryInstruction: [VisualInstruction.Component]? = nil,
                                            drivingSide: DrivingSide = .right) -> VisualInstructionBanner {
        let primary = VisualInstruction(text: "Instruction",
                                        maneuverType: maneuverType,
                                        maneuverDirection: maneuverDirection,
                                        components: primaryInstruction)
        var secondary: VisualInstruction? = nil
        if let secondaryInstruction = secondaryInstruction {
            secondary = VisualInstruction(text: "Instruction",
                                          maneuverType: maneuverType,
                                          maneuverDirection: maneuverDirection,
                                          components: secondaryInstruction)
        }

        return VisualInstructionBanner(distanceAlongStep: 482.803,
                                       primary: primary,
                                       secondary: secondary,
                                       tertiary: nil,
                                       quaternary: nil,
                                       drivingSide: drivingSide)
    }

    public class func makeSpokenInstruction() -> SpokenInstruction {
        return SpokenInstruction(distanceAlongStep: 100, text: "Instruction", ssmlText: "instruction")
    }

    public static func route(waypoints: [CLLocationCoordinate2D],
                             profileIdentifier: ProfileIdentifier = .automobile,
                             transportType: TransportType = .automobile) -> (response: RouteResponse, route: Route) {
        precondition(waypoints.count >= 2)
        func routeDistance(between waypoints: [CLLocationCoordinate2D]) -> CLLocationDistance {
            var routeDistance: CLLocationDistance = 0
            var origin = waypoints[0]
            for waypointIdx in 1..<waypoints.count {
                let destination = waypoints[waypointIdx]
                routeDistance += origin.distance(to: destination)
                origin = destination
            }
            return routeDistance
        }

        let routeShape = LineString(waypoints)
        var legs: [RouteLeg] = []

        var legOrigin: CLLocationCoordinate2D = waypoints[0]
        for waypointIdx in 1..<waypoints.count {
            let legDestination = waypoints[waypointIdx]
            let leg = generateLeg(between: legOrigin,
                                  and: legDestination,
                                  profileIdentifier: profileIdentifier,
                                  transportType: transportType)
            leg.source = legs.last?.destination
            legs.append(leg)
            legOrigin = legDestination
        }

        let route = Route(legs: legs,
                          shape: routeShape,
                          distance: routeDistance(between: waypoints),
                          expectedTravelTime: 0)
        let response = RouteResponse(httpResponse: nil,
                                     routes: [route],
                                     options: .route(.init(coordinates: waypoints)),
                                     credentials: .mocked)
        return (response: response, route: route)
    }

    public static func route(between origin: CLLocationCoordinate2D,
                             and destination: CLLocationCoordinate2D,
                             legsCount: Int = 1,
                             profileIdentifier: ProfileIdentifier = .automobile,
                             transportType: TransportType = .automobile) -> (response: RouteResponse, route: Route) {
        precondition(legsCount > 0)
        var waypoints: [CLLocationCoordinate2D] = [origin]
        let routeDistance = origin.distance(to: destination)
        let direction = origin.direction(to: destination)
        let distancePerLeg = routeDistance / Double(legsCount)

        var legOrigin: CLLocationCoordinate2D = origin
        for _ in 0..<legsCount {
            let legDestination = legOrigin.coordinate(at: distancePerLeg, facing: direction)
            waypoints.append(legDestination)
            legOrigin = legDestination
        }

        return route(waypoints: waypoints, profileIdentifier: profileIdentifier, transportType: transportType)
    }

    public static func generateCoordinates(between start: CLLocationCoordinate2D,
                                           and end: CLLocationCoordinate2D,
                                           count: Int) -> [CLLocationCoordinate2D] {
        precondition(count > 0)

        let directionToEnd = start.direction(to: end)
        let distance = start.distance(to: end)
        var coordinates: [CLLocationCoordinate2D] = []

        for distance in stride(from: 0, to: distance, by: distance / CLLocationDistance(count)) {
            coordinates.append(start.coordinate(at: distance, facing: directionToEnd))
        }

        return coordinates
    }

    public static func generateLeg(between origin: CLLocationCoordinate2D,
                                   and destination: CLLocationCoordinate2D,
                                   profileIdentifier: ProfileIdentifier = .automobile,
                                   transportType: TransportType = .automobile) -> RouteLeg {
        let distance = origin.distance(to: destination)
        let shape = LineString([origin, destination])
        let intersection = Intersection(location: destination,
                                        headings: [origin.direction(to: destination)],
                                        approachIndex: 0,
                                        outletIndex: 0,
                                        outletIndexes: .init(integer: 0),
                                        approachLanes: nil,
                                        usableApproachLanes: nil,
                                        preferredApproachLanes: nil,
                                        usableLaneIndication: nil)

        let arriveStep = RouteStep(transportType: transportType,
                                   maneuverLocation: destination,
                                   maneuverType: .arrive,
                                   instructions: "arrive",
                                   drivingSide: .right,
                                   distance: distance,
                                   expectedTravelTime: 0,
                                   intersections: [intersection])
        arriveStep.shape = shape
        let leg = RouteLeg(steps: [arriveStep],
                           name: "",
                           distance: distance,
                           expectedTravelTime: 0,
                           profileIdentifier: profileIdentifier)
        leg.destination = Waypoint(coordinate: destination)
        return leg
    }

    public static let credentials: Credentials = .mocked
}

class TraceCollector: NSObject, CLLocationManagerDelegate {
    var locations = [CLLocation]()
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locations.append(contentsOf: locations)
    }
}
