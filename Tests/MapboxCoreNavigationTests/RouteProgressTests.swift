import Foundation
import XCTest
import CoreLocation
import MapboxDirections
import TestHelper
import struct Polyline.Polyline
import Turf
@testable import MapboxCoreNavigation

class RouteProgressTests: TestCase {

    var route: Route!
    var routeWithNoDistance: Route!

    override func setUp() {
        super.setUp()

        route = makeRoute()
        routeWithNoDistance = makeRouteWithNoDistance()
    }

    func testRouteProgress() {
        let routeProgress = RouteProgress(route: route, options: routeOptions)
        XCTAssertEqual(routeProgress.fractionTraveled, 0)
        XCTAssertEqual(routeProgress.distanceRemaining, 4054.2)
        XCTAssertEqual(routeProgress.distanceTraveled, 0)
        XCTAssertEqual(round(routeProgress.durationRemaining), 858)
    }

    func testRouteWithNoDistance() {
        let routeProgress = RouteProgress(route: routeWithNoDistance, options: routeOptions)
        XCTAssertEqual(routeProgress.distanceRemaining, 0)
        XCTAssertEqual(routeProgress.distanceTraveled, 0)
        XCTAssertEqual(round(routeProgress.durationRemaining), 0)
        XCTAssertEqual(routeProgress.fractionTraveled, 1)
        XCTAssertEqual(routeProgress.currentLegProgress.distanceRemaining, 0)
        XCTAssertEqual(routeProgress.currentLegProgress.distanceTraveled, 0)
        XCTAssertEqual(routeProgress.currentLegProgress.durationRemaining, 0)
        XCTAssertEqual(routeProgress.currentLegProgress.fractionTraveled, 1)
    }

    func testRouteLegProgress() {
        let routeProgress = RouteProgress(route: route, options: routeOptions)
        XCTAssertEqual(routeProgress.currentLeg.description, "Hyde Street, Page Street")
        XCTAssertEqual(routeProgress.currentLegProgress.distanceTraveled, 0)
        XCTAssertEqual(round(routeProgress.currentLegProgress.durationRemaining), 858)
        XCTAssertEqual(routeProgress.currentLegProgress.fractionTraveled, 0)
        XCTAssertEqual(routeProgress.currentLegProgress.stepIndex, 0)
        XCTAssertEqual(routeProgress.currentLegProgress.followOnStep?.description, "Turn left onto Hyde Street")
        XCTAssertEqual(routeProgress.currentLegProgress.upcomingStep?.description, "Turn right onto California Street")
    }
    
    func testRouteStepProgress() {
        let routeProgress = RouteProgress(route: route, options: routeOptions)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.distanceRemaining, 384.1)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.distanceTraveled, 0)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.durationRemaining, 86.6, accuracy: 0.001)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.fractionTraveled, 0)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.userDistanceToManeuverLocation, 384.1)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.step.description, "Head south on Taylor Street")
    }
    
    func testNextRouteStepProgress() {
        let routeProgress = RouteProgress(route: route, options: routeOptions)
        routeProgress.currentLegProgress.stepIndex = 1
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.spokenInstructionIndex, 0)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.distanceRemaining, 439.1)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.distanceTraveled, 0)
        XCTAssertEqual(round(routeProgress.currentLegProgress.currentStepProgress.durationRemaining), 73)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.fractionTraveled, 0)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.userDistanceToManeuverLocation, 439.1)
        XCTAssertEqual(routeProgress.currentLegProgress.currentStepProgress.step.description, "Turn right onto California Street")
    }
    
    func testRemainingWaypointsAlongRoute() {
        let coordinates = [
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
    
    func routeLeg(options: RouteOptions, routeCoordinates: [CLLocationCoordinate2D]) -> RouteLeg {
        let source = options.waypoints.first!
        let destination = options.waypoints.last!
        options.shapeFormat = .polyline
        let steps = [
            RouteStep(transportType: .automobile, maneuverLocation: source.coordinate, maneuverType: .depart, maneuverDirection: nil, instructions: "", initialHeading: nil, finalHeading: nil, drivingSide: .right, exitCodes: nil, exitNames: nil, phoneticExitNames: nil, distance: 0, expectedTravelTime: 0, names: nil, phoneticNames: nil, codes: nil, destinationCodes: nil, destinations: nil, intersections: nil, instructionsSpokenAlongStep: nil, instructionsDisplayedAlongStep: nil),
            RouteStep(transportType: .automobile, maneuverLocation: destination.coordinate, maneuverType: .arrive, maneuverDirection: nil, instructions: "", initialHeading: nil, finalHeading: nil, drivingSide: .right, exitCodes: nil, exitNames: nil, phoneticExitNames: nil, distance: 0, expectedTravelTime: 0, names: nil, phoneticNames: nil, codes: nil, destinationCodes: nil, destinations: nil, intersections: nil, instructionsSpokenAlongStep: nil, instructionsDisplayedAlongStep: nil),
        ]
        steps[0].shape = LineString(routeCoordinates)
        return RouteLeg(steps: steps, name: "", distance: 0, expectedTravelTime: 0, profileIdentifier: .automobile)
    }
    
    func routeLegProgress(options: RouteOptions, routeCoordinates: [CLLocationCoordinate2D], shapeIndex: Int = 0) -> RouteLegProgress {
        let leg = routeLeg(options: options, routeCoordinates: routeCoordinates)
        return RouteLegProgress(leg: leg, shapeIndex: shapeIndex)
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
        
        legProgress.currentStepProgress.distanceTraveled = LineString(coordinates).distance()! / 2.0
        remainingWaypoints = legProgress.remainingWaypoints(among: Array(options.waypoints.dropLast()))
        XCTAssertEqual(remainingWaypoints.count, 2,
                       "At the via point where the leg backtracks, only the via points after backtracking should remain")
        
        legProgress.currentStepProgress.distanceTraveled = LineString(coordinates).distance()! / 2.0 + coordinates[3].distance(to: coordinates[4]) / 2.0
        remainingWaypoints = legProgress.remainingWaypoints(among: Array(options.waypoints.dropLast()))
        XCTAssertEqual(remainingWaypoints.count, 2,
                       "Halfway to the via point where the leg backtracks, only the via points after backtracking should remain")
        
        legProgress.currentStepProgress.distanceTraveled = LineString(coordinates).distance()! / 2.0 + coordinates[3].distance(to: coordinates[4])
        remainingWaypoints = legProgress.remainingWaypoints(among: Array(options.waypoints.dropLast()))
        XCTAssertEqual(remainingWaypoints.count, 1,
                       "At the first via point after backtracking, all but one of the via points after backtracking should remain")
        
        legProgress.currentStepProgress.distanceTraveled = LineString(coordinates).distance()!
        remainingWaypoints = legProgress.remainingWaypoints(among: Array(options.waypoints.dropLast()))
        XCTAssertEqual(remainingWaypoints.count, 0,
                       "At the last via point after backtracking, nothing should remain")
    }
    
    func testSpeedLimits() {
        let coordinates = [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 2, longitude: 3),
            CLLocationCoordinate2D(latitude: 4, longitude: 6),
            CLLocationCoordinate2D(latitude: 6, longitude: 9),
            CLLocationCoordinate2D(latitude: 8, longitude: 12),
            CLLocationCoordinate2D(latitude: 10, longitude: 15),
            CLLocationCoordinate2D(latitude: 12, longitude: 18),
        ]
        let lineString = LineString(coordinates)
        
        let options = RouteOptions(coordinates: [coordinates.first!, coordinates.last!])
        let leg = routeLeg(options: options, routeCoordinates: coordinates)
        leg.segmentMaximumSpeedLimits = [
            .init(value: 10, unit: .kilometersPerHour),
            .init(value: 20, unit: .milesPerHour),
            nil,
            .init(value: 40, unit: .milesPerHour),
            .init(value: 50, unit: .kilometersPerHour),
            .init(value: .infinity, unit: .kilometersPerHour),
        ]
        
        let legProgress = RouteLegProgress(leg: leg)
        
        XCTAssertEqual(legProgress.distanceTraveled, 0)
        XCTAssertEqual(legProgress.currentSpeedLimit, Measurement(value: 10, unit: UnitSpeed.kilometersPerHour))
        legProgress.currentStepProgress.distanceTraveled = lineString.distance(to: coordinates[1])! / 2.0
        XCTAssertEqual(legProgress.currentSpeedLimit, Measurement(value: 10, unit: UnitSpeed.kilometersPerHour))
        
        legProgress.currentStepProgress.distanceTraveled = lineString.distance(to: coordinates[1])!
        XCTAssertEqual(legProgress.currentSpeedLimit, Measurement(value: 20, unit: UnitSpeed.milesPerHour))
        legProgress.currentStepProgress.distanceTraveled = lineString.distance(to: coordinates[1])! + lineString.distance(from: coordinates[1], to: coordinates[2])! / 2.0
        XCTAssertEqual(legProgress.currentSpeedLimit, Measurement(value: 20, unit: UnitSpeed.milesPerHour))
        
        legProgress.currentStepProgress.distanceTraveled = lineString.distance(to: coordinates[2])!
        XCTAssertNil(legProgress.currentSpeedLimit)
        legProgress.currentStepProgress.distanceTraveled = lineString.distance(to: coordinates[2])! + lineString.distance(from: coordinates[2], to: coordinates[3])! / 2.0
        XCTAssertNil(legProgress.currentSpeedLimit)
        
        legProgress.currentStepProgress.distanceTraveled = lineString.distance(to: coordinates[3])!
        XCTAssertEqual(legProgress.currentSpeedLimit, Measurement(value: 40, unit: UnitSpeed.milesPerHour))
        legProgress.currentStepProgress.distanceTraveled = lineString.distance(to: coordinates[3])! + lineString.distance(from: coordinates[3], to: coordinates[4])! / 2.0
        XCTAssertEqual(legProgress.currentSpeedLimit, Measurement(value: 40, unit: UnitSpeed.milesPerHour))
        
        legProgress.currentStepProgress.distanceTraveled = lineString.distance(to: coordinates[4])!
        XCTAssertEqual(legProgress.currentSpeedLimit, Measurement(value: 50, unit: UnitSpeed.kilometersPerHour))
        legProgress.currentStepProgress.distanceTraveled = lineString.distance(to: coordinates[4])! + lineString.distance(from: coordinates[4], to: coordinates[5])! / 2.0
        XCTAssertEqual(legProgress.currentSpeedLimit, Measurement(value: 50, unit: UnitSpeed.kilometersPerHour))
        
        legProgress.currentStepProgress.distanceTraveled = lineString.distance(to: coordinates[5])!
        XCTAssertTrue(legProgress.currentSpeedLimit?.value.isInfinite ?? false)
        legProgress.currentStepProgress.distanceTraveled = lineString.distance(to: coordinates[5])! + (lineString.distance()! - lineString.distance(to: coordinates[5])!) / 2.0
        XCTAssertTrue(legProgress.currentSpeedLimit?.value.isInfinite ?? false)
    }
    
    func testRouteProggressCodable() {
        let routeProgress = RouteProgress(route: route,
                                          options: routeOptions,
                                          routeShapeIndex: 37,
                                          legShapeIndex: 13)
        
        let encoder = JSONEncoder()
        encoder.userInfo[.options] = routeOptions
        let data = try! encoder.encode(routeProgress)
        let decoder = JSONDecoder()
        decoder.userInfo[.options] = routeOptions
        let decoded = try! decoder.decode(RouteProgress.self, from: data)

        XCTAssertEqual(routeProgress.route.distance, decoded.route.distance)
        XCTAssertEqual(routeProgress.route.speechLocale, decoded.route.speechLocale)
        XCTAssertEqual(routeProgress.route.shape, decoded.route.shape)
        XCTAssertEqual(routeProgress.route.expectedTravelTime, decoded.route.expectedTravelTime)
        XCTAssertEqual(routeProgress.routeOptions, decoded.routeOptions)
        XCTAssertEqual(routeProgress.legIndex, decoded.legIndex)
        XCTAssertEqual(routeProgress.currentLegProgress.leg.source, decoded.currentLegProgress.leg.source)
        XCTAssertEqual(routeProgress.currentLegProgress.leg.destination, decoded.currentLegProgress.leg.destination)
        XCTAssertEqual(routeProgress.currentLegProgress.leg.name, decoded.currentLegProgress.leg.name)
        XCTAssertEqual(routeProgress.currentLegProgress.leg.distance, decoded.currentLegProgress.leg.distance)
        XCTAssertEqual(routeProgress.currentLegProgress.leg.source, decoded.currentLegProgress.leg.source)
        XCTAssertEqual(routeProgress.congestionTravelTimesSegmentsByStep.count, decoded.congestionTravelTimesSegmentsByStep.count)
        XCTAssertEqual(routeProgress.congestionTimesPerStep, decoded.congestionTimesPerStep)
        XCTAssertEqual(routeProgress.shapeIndex, decoded.shapeIndex)
        XCTAssertEqual(routeProgress.currentLegProgress.shapeIndex, decoded.currentLegProgress.shapeIndex)
    }
    
    func testRouteLegProgressCodable() {
        let coordinates = [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 2, longitude: 3),
            CLLocationCoordinate2D(latitude: 4, longitude: 6),
            CLLocationCoordinate2D(latitude: 6, longitude: 9),
            CLLocationCoordinate2D(latitude: 8, longitude: 12),
            CLLocationCoordinate2D(latitude: 10, longitude: 15),
            CLLocationCoordinate2D(latitude: 12, longitude: 18),
        ]
        let options = RouteOptions(coordinates: [coordinates.first!, coordinates.last!])
        let legProgress = routeLegProgress(options: options, routeCoordinates: coordinates, shapeIndex: 11)
        
        let data = try! JSONEncoder().encode(legProgress)
        let decoded = try! JSONDecoder().decode(RouteLegProgress.self, from: data)
        
        XCTAssertEqual(legProgress.leg, decoded.leg)
        XCTAssertEqual(legProgress.stepIndex, decoded.stepIndex)
        XCTAssertEqual(legProgress.userHasArrivedAtWaypoint, decoded.userHasArrivedAtWaypoint)
        XCTAssertEqual(legProgress.currentStepProgress.step, decoded.currentStepProgress.step)
        XCTAssertEqual(legProgress.currentStepProgress.distanceTraveled, decoded.currentStepProgress.distanceTraveled)
        XCTAssertEqual(legProgress.shapeIndex, decoded.shapeIndex)
    }
    
    func testRouteStepProgressCodable() {
        let stepProgress = RouteStepProgress(step: RouteStep(transportType: .automobile,
                                                             maneuverLocation: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                                                             maneuverType: .arrive,
                                                             instructions: "instructions",
                                                             drivingSide: .right,
                                                             distance: 13.3,
                                                             expectedTravelTime: 0.7))
        
        let data = try! JSONEncoder().encode(stepProgress)
        let decoded = try! JSONDecoder().decode(RouteStepProgress.self, from: data)
        
        XCTAssertEqual(stepProgress.step, decoded.step)
        XCTAssertEqual(stepProgress.userDistanceToManeuverLocation, decoded.userDistanceToManeuverLocation)
        XCTAssertEqual(stepProgress.intersectionsIncludingUpcomingManeuverIntersection, decoded.intersectionsIncludingUpcomingManeuverIntersection)
        XCTAssertEqual(stepProgress.intersectionIndex, decoded.intersectionIndex)
        XCTAssertEqual(stepProgress.intersectionDistances, decoded.intersectionDistances)
        XCTAssertEqual(stepProgress.userDistanceToUpcomingIntersection, decoded.userDistanceToUpcomingIntersection)
        XCTAssertEqual(stepProgress.visualInstructionIndex, decoded.visualInstructionIndex)
        XCTAssertEqual(stepProgress.spokenInstructionIndex, decoded.spokenInstructionIndex)
    }
}
