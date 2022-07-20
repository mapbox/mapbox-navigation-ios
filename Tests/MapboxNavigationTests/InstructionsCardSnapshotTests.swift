import XCTest
import Foundation
import SnapshotTesting
import MapboxDirections
import MapboxCoreNavigation
import CoreLocation
@testable import MapboxNavigation
@testable import TestHelper

class InstructionsCardSnapshotTests: TestCase {
    
    let tertiaryRouteOptions = NavigationRouteOptions(coordinates: [
        CLLocationCoordinate2D(latitude: 39.749216, longitude: -105.008272),
        CLLocationCoordinate2D(latitude: 39.694833, longitude: -104.976949),
    ])
        
    override func setUp() {
        super.setUp()
        isRecording = false
        DayStyle().apply()
    }
    
    func testRegularManeuver() {
        let route = Fixture.route(from: "route-with-tertiary", options: tertiaryRouteOptions)
        
        let host = UIViewController(nibName: nil, bundle: nil)
        let container = UIView.forAutoLayout()
        let subject = InstructionsCardViewController(nibName: nil, bundle: nil)
        
        host.view.addSubview(container)
        constrain(container, to: host.view)
        
        host.embed(subject, in: container) { (parent, cards) -> [NSLayoutConstraint] in
            cards.view.translatesAutoresizingMaskIntoConstraints = false
            return cards.view.constraintsForPinning(to: container)
        }
        
        let progress = RouteProgress(route: route, options: tertiaryRouteOptions, legIndex: 0, spokenInstructionIndex: 0)
        
        subject.routeProgress = progress
        assertImageSnapshot(matching: host, as: .image(precision: 0.95))
    }
    
    func testLanesManeuver() {
        let route = Fixture.route(from: "route-with-tertiary", options: tertiaryRouteOptions)
        
        let host = UIViewController(nibName: nil, bundle: nil)
        let container = UIView.forAutoLayout()
        let subject = InstructionsCardViewController(nibName: nil, bundle: nil)
        
        host.view.addSubview(container)
        constrain(container, to: host.view)
        
        host.embed(subject, in: container) { (parent, cards) -> [NSLayoutConstraint] in
            cards.view.translatesAutoresizingMaskIntoConstraints = false
            return cards.view.constraintsForPinning(to: container)
        }
        
        let progress = RouteProgress(route: route, options: tertiaryRouteOptions, legIndex: 0, spokenInstructionIndex: 0)
        progress.currentLegProgress.stepIndex = 1
        
        subject.routeProgress = progress
        
        assertImageSnapshot(matching: host, as: .image(precision: 0.95))
    }
    
    func testTertiaryManeuver() {
        let route = Fixture.route(from: "route-with-tertiary", options: tertiaryRouteOptions)
        
        let host = UIViewController(nibName: nil, bundle: nil)
        let container = UIView.forAutoLayout()
        let subject = InstructionsCardViewController(nibName: nil, bundle: nil)
        
        host.view.addSubview(container)
        constrain(container, to: host.view)
        
        host.embed(subject, in: container) { (parent, cards) -> [NSLayoutConstraint] in
            cards.view.translatesAutoresizingMaskIntoConstraints = false
            return cards.view.constraintsForPinning(to: container)
        }
        
        let progress = RouteProgress(route: route, options: tertiaryRouteOptions, legIndex: 0, spokenInstructionIndex: 0)
        progress.currentLegProgress.stepIndex = 5
        
        subject.routeProgress = progress
        subject.view.setNeedsDisplay()
        
        assertImageSnapshot(matching: host, as: .image(precision: 0.95))
    }
}
