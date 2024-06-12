import CoreLocation
import Foundation
import MapboxDirections
@_spi(MapboxInternal) @testable import MapboxNavigationCore
import Turf
import UIKit.UIImage

public class Fixture: NSObject {
    public class var bundle: Bundle {
#if SWIFT_PACKAGE
        return .module
#else
        return Bundle(for: self)
#endif
    }

    public class func stringFromFileNamed(name: String) -> String {
        guard let path = bundle.path(forResource: name, ofType: "json") else {
            assertionFailure("Fixture \(name) not found.")
            return ""
        }
        do {
            return try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            assertionFailure("Unable to decode fixture at \(path): \(error).")
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
            var response = try decoder.decode(RouteResponse.self, from: responseData)

            // Like `Directions.postprocess(_:fetchStartDate:uuid:)`
            let mappedRoutes = response.routes?.map {
                var route = $0
                let fetchStartDate = Date(timeIntervalSince1970: 3600)
                route.fetchStartDate = fetchStartDate
                route.responseEndDate = Date(timeInterval: 1, since: fetchStartDate)
                return route
            }
            response.routes = mappedRoutes
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

    public class func navigationRoutes(from jsonFile: String, options: RouteOptions) async -> NavigationRoutes {
        let responseData = JSONFromFileNamed(name: jsonFile)
        do {
            let decoder = JSONDecoder()
            decoder.userInfo[.options] = options
            decoder.userInfo[.credentials] = Fixture.credentials
            var response = try decoder.decode(RouteResponse.self, from: responseData)

            // Like `Directions.postprocess(_:fetchStartDate:uuid:)`
            let mappedRoutes = response.routes?.map {
                var route = $0
                let fetchStartDate = Date(timeIntervalSince1970: 3600)
                route.fetchStartDate = fetchStartDate
                route.responseEndDate = Date(timeInterval: 1, since: fetchStartDate)
                return route
            }
            response.routes = mappedRoutes
            return try await NavigationRoutes(
                routeResponse: response,
                routeIndex: 0,
                responseOrigin: .online
            )
        } catch {
            preconditionFailure("Unable to decode JSON fixture: \(error)")
        }
    }

    public class func navigationRoute(from jsonFile: String, options: RouteOptions) async -> NavigationRoute {
        let routes = await navigationRoutes(from: jsonFile, options: options)
        return routes.mainRoute
    }

    public class func generateTrace(for route: Route, speedMultiplier: Double = 1) -> [CLLocation] {
        route.shape?.coordinates.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) } ?? []
    }

    public class func routeLegProgress(
        expectedTravelTime: TimeInterval = 0.0,
        stepDistance: Turf.LocationDistance = 0.0,
        stepCount: Int = 1
    ) -> RouteLegProgress {
        var steps: [RouteStep] = []
        for i in 0..<stepCount {
            let maneuverType: ManeuverType = i == stepCount - 1 ? .arrive : i == 0 ? .depart : .turn
            steps.append(RouteStep(
                transportType: .automobile,
                maneuverLocation: .init(),
                maneuverType: maneuverType,
                instructions: "empty",
                drivingSide: .right,
                distance: stepDistance,
                expectedTravelTime: expectedTravelTime
            ))
        }
        return RouteLegProgress(leg: RouteLeg(
            steps: steps,
            name: "empty",
            distance: 0.0,
            expectedTravelTime: expectedTravelTime,
            profileIdentifier: .automobile
        ))
    }

    public class func makeVisualInstruction(
        maneuverType: ManeuverType = .arrive,
        maneuverDirection: ManeuverDirection = .left,
        primaryInstruction: [VisualInstruction.Component] = [],
        secondaryInstruction: [VisualInstruction.Component]? = nil,
        drivingSide: DrivingSide = .right
    ) -> VisualInstructionBanner {
        let primary = VisualInstruction(
            text: "Instruction",
            maneuverType: maneuverType,
            maneuverDirection: maneuverDirection,
            components: primaryInstruction
        )
        var secondary: VisualInstruction? = nil
        if let secondaryInstruction {
            secondary = VisualInstruction(
                text: "Instruction",
                maneuverType: maneuverType,
                maneuverDirection: maneuverDirection,
                components: secondaryInstruction
            )
        }

        return VisualInstructionBanner(
            distanceAlongStep: 482.803,
            primary: primary,
            secondary: secondary,
            tertiary: nil,
            quaternary: nil,
            drivingSide: drivingSide
        )
    }

    public class func makeSpokenInstruction() -> SpokenInstruction {
        return SpokenInstruction(distanceAlongStep: 100, text: "Instruction", ssmlText: "instruction")
    }

    public static func route(
        waypoints: [CLLocationCoordinate2D],
        profileIdentifier: ProfileIdentifier = .automobile,
        transportType: TransportType = .automobile
    ) -> (response: RouteResponse, route: Route) {
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
            var leg = generateLeg(
                between: legOrigin,
                and: legDestination,
                profileIdentifier: profileIdentifier,
                transportType: transportType
            )
            leg.source = legs.last?.destination
            legs.append(leg)
            legOrigin = legDestination
        }

        let route = Route(
            legs: legs,
            shape: routeShape,
            distance: routeDistance(between: waypoints),
            expectedTravelTime: 0
        )
        let response = RouteResponse(
            httpResponse: nil,
            routes: [route],
            options: .route(.init(coordinates: waypoints)),
            credentials: .mock()
        )
        return (response: response, route: route)
    }

    public static func navigationRoutes(
        between origin: CLLocationCoordinate2D,
        and destination: CLLocationCoordinate2D,
        legsCount: Int = 1,
        profileIdentifier: ProfileIdentifier = .automobile,
        transportType: TransportType = .automobile
    ) async -> NavigationRoutes {
        let (response, _) = route(
            between: origin,
            and: destination,
            legsCount: legsCount,
            profileIdentifier: profileIdentifier,
            transportType: transportType
        )
        return try! await NavigationRoutes(
            routeResponse: response,
            routeIndex: 0,
            responseOrigin: .online
        )
    }

    public static func route(
        between origin: CLLocationCoordinate2D,
        and destination: CLLocationCoordinate2D,
        legsCount: Int = 1,
        profileIdentifier: ProfileIdentifier = .automobile,
        transportType: TransportType = .automobile
    ) -> (response: RouteResponse, route: Route) {
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

    public static func generateCoordinates(
        between start: CLLocationCoordinate2D,
        and end: CLLocationCoordinate2D,
        count: Int
    ) -> [CLLocationCoordinate2D] {
        precondition(count > 0)

        let directionToEnd = start.direction(to: end)
        let distance = start.distance(to: end)
        var coordinates: [CLLocationCoordinate2D] = []

        for distance in stride(from: 0, to: distance, by: distance / CLLocationDistance(count)) {
            coordinates.append(start.coordinate(at: distance, facing: directionToEnd))
        }

        return coordinates
    }

    public static func generateLeg(
        between origin: CLLocationCoordinate2D,
        and destination: CLLocationCoordinate2D,
        profileIdentifier: ProfileIdentifier = .automobile,
        transportType: TransportType = .automobile
    ) -> RouteLeg {
        let distance = origin.distance(to: destination)
        let shape = LineString([origin, destination])
        let intersection = Intersection(
            location: destination,
            headings: [origin.direction(to: destination)],
            approachIndex: 0,
            outletIndex: 0,
            outletIndexes: .init(integer: 0),
            approachLanes: nil,
            usableApproachLanes: nil,
            preferredApproachLanes: nil,
            usableLaneIndication: nil
        )

        var arriveStep = RouteStep(
            transportType: transportType,
            maneuverLocation: destination,
            maneuverType: .arrive,
            instructions: "arrive",
            drivingSide: .right,
            distance: distance,
            expectedTravelTime: 0,
            intersections: [intersection]
        )
        arriveStep.shape = shape
        var leg = RouteLeg(
            steps: [arriveStep],
            name: "",
            distance: distance,
            expectedTravelTime: 0,
            profileIdentifier: profileIdentifier
        )
        leg.destination = Waypoint(coordinate: destination)
        return leg
    }

    public static func createFeedbackEvent() -> FeedbackEvent {
        return FeedbackEvent(metadata: .init(
            userFeedbackHandle: nil,
            screenshot: nil,
            userFeedbackMetadata: nil
        ))
    }

    public static let credentials: Credentials = .mock()
}
