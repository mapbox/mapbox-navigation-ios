import XCTest
import MapboxDirections
import TestHelper
import Turf
@testable import MapboxNavigation

class RouteTests: XCTestCase {
    func testPolylineAroundManeuver() {
        // Convert the match from https://github.com/mapbox/navigation-ios-examples/pull/28 into a route.
        // The details of the route are unimportant; what matters is the geometry.
        let response = Fixture.mapMatchingResponse(from: "route-doubling-back")
        let routes = response.routes
        let route = routes!.first!
        let leg = route.legs.first!
        
        // There are four traversals of the intersection at Linnégatan and Brahegatan, two left turns from one direction and one right turn from another direction.
        let traversals = [1, 8, 13, 20]
        for stepIndex in traversals {
            let precedingStep = leg.steps[stepIndex - 1]
            let precedingStepPolyline = precedingStep.shape!
            let followingStep = leg.steps[stepIndex]
            let stepPolyline = followingStep.shape!
            let maneuverPolyline = route.polylineAroundManeuver(legIndex: 0, stepIndex: stepIndex, distance: 30)
            
            let firstIndexedCoordinate = precedingStepPolyline.closestCoordinate(to: maneuverPolyline.coordinates[0])
            XCTAssertNotNil(firstIndexedCoordinate)
            XCTAssertLessThan(firstIndexedCoordinate?.distance ?? .greatestFiniteMagnitude, 1, "Start of maneuver polyline for step \(stepIndex) is \(firstIndexedCoordinate?.distance ?? -1) away from approach to intersection.")
            
            let indexedManeuverLocation = stepPolyline.closestCoordinate(to: followingStep.maneuverLocation)
            XCTAssertLessThan(indexedManeuverLocation?.distance ?? .greatestFiniteMagnitude, 1, "Maneuver polyline for step \(stepIndex) turns \(indexedManeuverLocation?.distance ?? -1) away from intersection.")
            
            let lastIndexedCoordinate = stepPolyline.closestCoordinate(to: maneuverPolyline.coordinates.last!)
            XCTAssertNotNil(lastIndexedCoordinate)
            XCTAssertLessThan(lastIndexedCoordinate?.distance ?? .greatestFiniteMagnitude, 1, "End of maneuver polyline for step \(stepIndex) is \(lastIndexedCoordinate?.distance ?? -1) away from outlet from intersection.")
        }
    }
}
