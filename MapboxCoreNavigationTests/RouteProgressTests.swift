import Foundation
import XCTest
import MapboxDirections
import struct Polyline.Polyline
import Turf
@testable import MapboxCoreNavigation

class RouteProgressTests: XCTestCase {
    func testRouteProgress() {
        let routeProgress = RouteProgress(route: route)
        XCTAssertEqual(routeProgress.fractionTraveled, 0)
        XCTAssertEqual(routeProgress.distanceRemaining, 4054.2)
        XCTAssertEqual(routeProgress.distanceTraveled, 0)
        XCTAssertEqual(round(routeProgress.durationRemaining), 858)
    }
    
    func testRouteLegProgress() {
        let routeProgress = RouteProgress(route: route)
        XCTAssertEqual(routeProgress.currentLeg.description, "Hyde Street, Page Street")
        XCTAssertEqual(routeProgress.currentLegProgress.distanceTraveled, 0)
        XCTAssertEqual(round(routeProgress.currentLegProgress.durationRemaining), 858)
        XCTAssertEqual(routeProgress.currentLegProgress.fractionTraveled, 0)
        XCTAssertEqual(routeProgress.currentLegProgress.stepIndex, 0)
        XCTAssertEqual(routeProgress.currentLegProgress.followOnStep?.description, "Turn left onto Hyde Street")
        XCTAssertEqual(routeProgress.currentLegProgress.upcomingStep?.description, "Turn right onto California Street")
    }
    
    func testRouteStepProgress() {
        let routeProgress = RouteProgress(route: route)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.distanceRemaining, 384.1)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.distanceTraveled, 0)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.durationRemaining, 86.6, accuracy: 0.001)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.fractionTraveled, 0)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.userDistanceToManeuverLocation, Double.infinity)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.step.description, "Head south on Taylor Street")
    }
    
    func testNextRouteStepProgress() {
        let routeProgress = RouteProgress(route: route)
        routeProgress.currentLegProgress.stepIndex = 1
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.spokenInstructionIndex, 0)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.distanceRemaining, 439.1)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.distanceTraveled, 0)
        XCTAssertEqual(round(routeProgress.currentLegProgress.currentStepProgress.durationRemaining), 73)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.fractionTraveled, 0)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.userDistanceToManeuverLocation, Double.infinity)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.step.description, "Turn right onto California Street")
    }
    
    func testRemainingWaypointsAlongRoute() {
        var coordinates = [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 2, longitude: 3),
            CLLocationCoordinate2D(latitude: 4, longitude: 6),
            CLLocationCoordinate2D(latitude: 6, longitude: 9),
            CLLocationCoordinate2D(latitude: 8, longitude: 12),
            CLLocationCoordinate2D(latitude: 10, longitude: 15),
            CLLocationCoordinate2D(latitude: 12, longitude: 18),
        ]
        
        // Single leg
        var options = RouteOptions(coordinates: [coordinates.first!, coordinates.last!])
        var waypoints = options.waypoints(fromLegAt: 0)
        XCTAssertEqual(waypoints.0.map { $0.coordinate }, [coordinates.first!])
        XCTAssertEqual(waypoints.1.map { $0.coordinate }, [coordinates.last!])
        
        // Two legs
        options = RouteOptions(coordinates: [coordinates[0], coordinates[1], coordinates.last!])
        waypoints = options.waypoints(fromLegAt: 0)
        XCTAssertEqual(waypoints.0.map { $0.coordinate }, [coordinates[0]])
        XCTAssertEqual(waypoints.1.map { $0.coordinate }, [coordinates[1], coordinates.last!])
        waypoints = options.waypoints(fromLegAt: 1)
        XCTAssertEqual(waypoints.0.map { $0.coordinate }, [coordinates[1]])
        XCTAssertEqual(waypoints.1.map { $0.coordinate }, [coordinates.last!])
        
        // Every coordinate is a leg
        options = RouteOptions(coordinates: coordinates)
        waypoints = options.waypoints(fromLegAt: 0)
        XCTAssertEqual(waypoints.0.map { $0.coordinate }, [coordinates.first!])
        XCTAssertEqual(waypoints.1.map { $0.coordinate }, Array(coordinates.dropFirst()))
        
        // Every coordinate is a via point
        for waypoint in options.waypoints {
            waypoint.separatesLegs = false
        }
        waypoints = options.waypoints(fromLegAt: 0)
        XCTAssertEqual(waypoints.0.map { $0.coordinate }, Array(coordinates.dropLast()))
        XCTAssertEqual(waypoints.1.map { $0.coordinate }, [coordinates.last!])
    }
    
    func routeLegProgress(options: RouteOptions, routeCoordinates: [CLLocationCoordinate2D]) -> RouteLegProgress {
        let source = options.waypoints.first!
        let destination = options.waypoints.last!
        options.shapeFormat = .polyline
        let jsonLeg = [
            "steps": [
                [
                    "maneuver": [
                        "type": "depart",
                        "location": [source.coordinate.longitude, source.coordinate.latitude],
                    ],
                    "name": "",
                    "mode": "",
                    "geometry": Polyline(coordinates: routeCoordinates, precision: 1e5).encodedPolyline,
                ],
                [
                    "maneuver": [
                        "type": "arrive",
                        "location": [destination.coordinate.longitude, destination.coordinate.latitude],
                    ],
                    "name": "",
                    "mode": "",
                ],
            ],
            "distance": 0.0,
            "duration": 0.0,
            "summary": "",
        ] as [String: Any]
        let leg = RouteLeg(json: jsonLeg, source: source, destination: destination, options: options)
        return RouteLegProgress(leg: leg)
    }
    
    func testRemainingWaypointsAlongLeg() {
        // Linear leg
        var coordinates = [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 2, longitude: 3),
            CLLocationCoordinate2D(latitude: 4, longitude: 6),
            CLLocationCoordinate2D(latitude: 6, longitude: 9),
            CLLocationCoordinate2D(latitude: 8, longitude: 12),
            CLLocationCoordinate2D(latitude: 10, longitude: 15),
            CLLocationCoordinate2D(latitude: 12, longitude: 18),
        ]
        
        // No via points
        var options = RouteOptions(coordinates: [coordinates.first!, coordinates.last!])
        var legProgress = routeLegProgress(options: options, routeCoordinates: coordinates)
        
        var remainingWaypoints = legProgress.remainingWaypoints(among: Array(options.waypoints.dropLast()))
        XCTAssertEqual(remainingWaypoints.count, 0,
                       "With no via points, at the start of the leg, neither the source nor a via point should remain")
        
        legProgress.currentStepProgress.distanceTraveled = coordinates[0].distance(to: coordinates[1]) / 2.0
        remainingWaypoints = legProgress.remainingWaypoints(among: Array(options.waypoints.dropLast()))
        XCTAssertEqual(remainingWaypoints.count, 0,
                       "With no via points, partway down the leg, neither the source nor a via point should remain")
        
        legProgress.currentStepProgress.distanceTraveled = coordinates[0].distance(to: coordinates[1])
        remainingWaypoints = legProgress.remainingWaypoints(among: Array(options.waypoints.dropLast()))
        XCTAssertEqual(remainingWaypoints.count, 0,
                       "With no via points, partway down the leg, neither the source nor a via point should remain")
        
        // Every coordinate is a via point.
        options = RouteOptions(coordinates: coordinates)
        
        legProgress = routeLegProgress(options: options, routeCoordinates: coordinates)
        remainingWaypoints = legProgress.remainingWaypoints(among: Array(options.waypoints.dropLast()))
        XCTAssertEqual(remainingWaypoints.count, options.waypoints.count - 2,
                       "At the start of the leg, all but the source should remain")
        
        legProgress = routeLegProgress(options: options, routeCoordinates: coordinates)
        legProgress.currentStepProgress.distanceTraveled = coordinates[0].distance(to: coordinates[1]) / 2.0
        remainingWaypoints = legProgress.remainingWaypoints(among: Array(options.waypoints.dropLast()))
        XCTAssertEqual(remainingWaypoints.count, options.waypoints.count - 2,
                       "Halfway to the first via point, all but the source should remain")
        
        legProgress.currentStepProgress.distanceTraveled = coordinates[0].distance(to: coordinates[1])
        remainingWaypoints = legProgress.remainingWaypoints(among: Array(options.waypoints.dropLast()))
        XCTAssertEqual(remainingWaypoints.count, options.waypoints.count - 3,
                       "At the first via point, all but the source and first via point should remain")
        
        // Leg that backtracks
        coordinates = [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 2, longitude: 3),
            CLLocationCoordinate2D(latitude: 4, longitude: 6),
            CLLocationCoordinate2D(latitude: 6, longitude: 9), // begin backtracking
            CLLocationCoordinate2D(latitude: 4, longitude: 6),
            CLLocationCoordinate2D(latitude: 2, longitude: 3),
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
        ]
        
        // No via points.
        options = RouteOptions(coordinates: [coordinates.first!, coordinates.last!])
        legProgress = routeLegProgress(options: options, routeCoordinates: coordinates)
        
        remainingWaypoints = legProgress.remainingWaypoints(among: Array(options.waypoints.dropLast()))
        XCTAssertEqual(remainingWaypoints.count, 0,
                       "With no via points, at the start of a leg that backtracks, neither the source nor a via point should remain")
        
        legProgress.currentStepProgress.distanceTraveled = coordinates[0].distance(to: coordinates[1])
        remainingWaypoints = legProgress.remainingWaypoints(among: Array(options.waypoints.dropLast()))
        XCTAssertEqual(remainingWaypoints.count, 0,
                       "With no via points, partway down a leg before backtracking, neither the source nor a via point should remain")
        
        legProgress.currentStepProgress.distanceTraveled = coordinates[0].distance(to: coordinates[3]) + coordinates[3].distance(to: coordinates[4])
        remainingWaypoints = legProgress.remainingWaypoints(among: Array(options.waypoints.dropLast()))
        XCTAssertEqual(remainingWaypoints.count, 0,
                       "With no via points, partway down a leg after backtracking, neither the source nor a via point should remain")
        
        // Every coordinate is a via point.
        options = RouteOptions(coordinates: coordinates)
        
        legProgress = routeLegProgress(options: options, routeCoordinates: coordinates)
        remainingWaypoints = legProgress.remainingWaypoints(among: Array(options.waypoints.dropLast()))
        XCTAssertEqual(remainingWaypoints.count, 5,
                       "At the start of a leg that backtracks, all but the source should remain")
        
        legProgress.currentStepProgress.distanceTraveled = coordinates[0].distance(to: coordinates[1])
        remainingWaypoints = legProgress.remainingWaypoints(among: Array(options.waypoints.dropLast()))
        XCTAssertEqual(remainingWaypoints.count, 4,
                       "At the first via point before backtracking, all but the source and first via point should remain")
        
        legProgress.currentStepProgress.distanceTraveled = LineString(coordinates).distance() / 2.0
        remainingWaypoints = legProgress.remainingWaypoints(among: Array(options.waypoints.dropLast()))
        XCTAssertEqual(remainingWaypoints.count, 2,
                       "At the via point where the leg backtracks, only the via points after backtracking should remain")
        
        legProgress.currentStepProgress.distanceTraveled = LineString(coordinates).distance() / 2.0 + coordinates[3].distance(to: coordinates[4]) / 2.0
        remainingWaypoints = legProgress.remainingWaypoints(among: Array(options.waypoints.dropLast()))
        XCTAssertEqual(remainingWaypoints.count, 2,
                       "Halfway to the via point where the leg backtracks, only the via points after backtracking should remain")
        
        legProgress.currentStepProgress.distanceTraveled = LineString(coordinates).distance() / 2.0 + coordinates[3].distance(to: coordinates[4])
        remainingWaypoints = legProgress.remainingWaypoints(among: Array(options.waypoints.dropLast()))
        XCTAssertEqual(remainingWaypoints.count, 1,
                       "At the first via point after backtracking, all but one of the via points after backtracking should remain")
        
        legProgress.currentStepProgress.distanceTraveled = LineString(coordinates).distance()
        remainingWaypoints = legProgress.remainingWaypoints(among: Array(options.waypoints.dropLast()))
        XCTAssertEqual(remainingWaypoints.count, 0,
                       "At the last via point after backtracking, nothing should remain")
    }
}
