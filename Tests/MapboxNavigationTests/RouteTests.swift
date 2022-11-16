import XCTest
import MapboxDirections
import TestHelper
import Turf
import MapboxCoreNavigation
@testable import MapboxNavigation

class RouteTests: TestCase {
    func testPolylineAroundManeuver() {
        // Convert the match from https://github.com/mapbox/navigation-ios-examples/pull/28 into a route.
        // The details of the route are unimportant; what matters is the geometry.
        let options = NavigationMatchOptions(coordinates: [
            .init(latitude: 59.3379254707993, longitude: 18.0768391763866),
            .init(latitude: 59.3376613543215, longitude: 18.0758977499228),
            .init(latitude: 59.3371292341531, longitude: 18.0754779388695),
            .init(latitude: 59.3368658096911, longitude: 18.0752713263541),
            .init(latitude: 59.3366161271274, longitude: 18.0758013323718),
            .init(latitude: 59.3363847683606, longitude: 18.0769377012062),
            .init(latitude: 59.3369299420601, longitude: 18.0779707637829),
            .init(latitude: 59.3374784940673, longitude: 18.0789771102838),
            .init(latitude: 59.3376624022706, longitude: 18.0796752015449),
            .init(latitude: 59.3382345065107, longitude: 18.0801207199294),
            .init(latitude: 59.338728497517,  longitude: 18.0793407846583),
            .init(latitude: 59.3390538588298, longitude: 18.0777368583247),
            .init(latitude: 59.3389021418961, longitude: 18.0769242264769),
            .init(latitude: 59.3383325439362, longitude: 18.0764655674924),
            .init(latitude: 59.3381526945276, longitude: 18.0757203959448),
            .init(latitude: 59.3383085323927, longitude: 18.0749662844197),
            .init(latitude: 59.3386507394432, longitude: 18.0749292910378),
            .init(latitude: 59.3396600470949, longitude: 18.0757133256584),
            .init(latitude: 59.3402031271014, longitude: 18.0770724776848),
            .init(latitude: 59.3399246668736, longitude: 18.0784376357593),
            .init(latitude: 59.3393711961939, longitude: 18.0786765675365),
            .init(latitude: 59.3383675368975, longitude: 18.0778982052741),
            .init(latitude: 59.3379254707993, longitude: 18.0768391763866),
            .init(latitude: 59.3376613543215, longitude: 18.0758977499228),
            .init(latitude: 59.3371292341531, longitude: 18.0754779388695),
            .init(latitude: 59.3368658096911, longitude: 18.0752713263541),
            .init(latitude: 59.3366161271274, longitude: 18.0758013323718),
            .init(latitude: 59.3363847683606, longitude: 18.0769377012062),
            .init(latitude: 59.3369299420601, longitude: 18.0779707637829),
            .init(latitude: 59.3374784940673, longitude: 18.0789771102838),
            .init(latitude: 59.3376624022706, longitude: 18.0796752015449),
            .init(latitude: 59.3382345065107, longitude: 18.0801207199294),
            .init(latitude: 59.338728497517,  longitude: 18.0793407846583),
            .init(latitude: 59.3390538588298, longitude: 18.0777368583247),
            .init(latitude: 59.3389021418961, longitude: 18.0769242264769),
            .init(latitude: 59.3383325439362, longitude: 18.0764655674924),
            .init(latitude: 59.3381526945276, longitude: 18.0757203959448),
            .init(latitude: 59.3383085323927, longitude: 18.0749662844197),
            .init(latitude: 59.3386507394432, longitude: 18.0749292910378),
            .init(latitude: 59.3396600470949, longitude: 18.0757133256584),
        ], profileIdentifier: .automobile)
        options.shapeFormat = .polyline
        let response = Fixture.mapMatchingResponse(from: "route-doubling-back", options: options)
        let routes = response.matches
        let route = routes!.first!
        let leg = route.legs.first!
        
        // There are four traversals of the intersection at Linnégatan and Brahegatan, two left turns from one direction and one right turn from another direction.
        let traversals = [1, 8, 13, 20]
        for stepIndex in traversals {
            let precedingStep = leg.steps[stepIndex - 1]
            let precedingStepPolyline = precedingStep.shape!
            let followingStep = leg.steps[stepIndex]
            let stepPolyline = followingStep.shape!
            let maneuverPolyline = route.polylineAroundManeuver(legIndex: 0, stepIndex: stepIndex, distance: 50)
            
            let firstIndexedCoordinate = precedingStepPolyline.closestCoordinate(to: maneuverPolyline.coordinates[0])
            XCTAssertNotNil(firstIndexedCoordinate)
            XCTAssertLessThan(firstIndexedCoordinate!.coordinate.distance(to: maneuverPolyline.coordinates[0]), 1, "Start of maneuver polyline for step \(stepIndex) is \(firstIndexedCoordinate!.coordinate.distance(to: maneuverPolyline.coordinates[0])) away from approach to intersection.")
            
            let indexedManeuverLocation = stepPolyline.closestCoordinate(to: followingStep.maneuverLocation)
            XCTAssertLessThan(indexedManeuverLocation?.distance ?? .greatestFiniteMagnitude, 1, "Maneuver polyline for step \(stepIndex) turns \(indexedManeuverLocation?.distance ?? -1) away from intersection.")
            
            let lastIndexedCoordinate = stepPolyline.closestCoordinate(to: maneuverPolyline.coordinates.last!)
            XCTAssertNotNil(lastIndexedCoordinate)
            XCTAssertLessThan(lastIndexedCoordinate!.coordinate.distance(to: maneuverPolyline.coordinates.last!), 1, "End of maneuver polyline for step \(stepIndex) is \(lastIndexedCoordinate!.coordinate.distance(to: maneuverPolyline.coordinates.last!)) away from outlet from intersection.")
        }
    }
    
    func testContainsStep() {
        guard let route = response.routes?.first else {
            XCTFail("Failed to get route.")
            return
        }

        var legIndex = route.legs.count - 1
        var stepsIndex = route.legs[legIndex].steps.count
        XCTAssertFalse(route.containsStep(at: legIndex, stepIndex: stepsIndex), "Failed to check the step index when it's larger than or equal to the steps count.")
        
        legIndex = route.legs.count
        stepsIndex = 0
        XCTAssertFalse(route.containsStep(at: legIndex, stepIndex: stepsIndex), "Failed to check the leg index when it's larger than or equal to the legs count.")
        
    }
}
