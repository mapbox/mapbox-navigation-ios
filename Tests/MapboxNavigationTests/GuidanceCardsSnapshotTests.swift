import MapboxDirections
@testable import MapboxNavigation
import MapboxCoreNavigation
import SnappyShrimp
@testable import TestHelper
import Foundation

@available(iOS 11.0, *)
/// :nodoc:
class GuidanceCardsSnapshotTests: SnapshotTest {
    let tertiaryRouteOptions = NavigationRouteOptions(coordinates: [
        CLLocationCoordinate2D(latitude: 39.749216, longitude: -105.008272),
        CLLocationCoordinate2D(latitude: 39.694833, longitude: -104.976949),
    ])
        
    override func setUp() {
        super.setUp()
        recordMode = false
    }
    
    
        func disableTestRegularManeuver() {
        let route = Fixture.route(from: "route-with-tertiary", options: tertiaryRouteOptions)
        
        let host = UIViewController(nibName: nil, bundle: nil)
        let container = UIView.forAutoLayout()
        let subject = InstructionsCardViewController(nibName: nil, bundle: nil)
        
        host.view.addSubview(container)
        constrain(container, to: host.view)
        
        embed(parent: host, child: subject, in: container) { (parent, cards) -> [NSLayoutConstraint] in
            cards.view.translatesAutoresizingMaskIntoConstraints = false
            return cards.view.constraintsForPinning(to: container)
        }
        
        let progress = RouteProgress(route: route, routeIndex: 0, options: tertiaryRouteOptions, legIndex: 0, spokenInstructionIndex: 0)
        
        subject.routeProgress = progress
        
        verify(host, for: Device.iPhone8Plus.portrait)
    }
    
    func disableTestLanesManeuver() {
        let route = Fixture.route(from: "route-with-tertiary", options: tertiaryRouteOptions)
        
        let host = UIViewController(nibName: nil, bundle: nil)
        let container = UIView.forAutoLayout()
        let subject = InstructionsCardViewController(nibName: nil, bundle: nil)
        
        host.view.addSubview(container)
        constrain(container, to: host.view)
        
        embed(parent: host, child: subject, in: container) { (parent, cards) -> [NSLayoutConstraint] in
            cards.view.translatesAutoresizingMaskIntoConstraints = false
            return cards.view.constraintsForPinning(to: container)
        }
        
        let progress = RouteProgress(route: route, routeIndex: 0, options: tertiaryRouteOptions, legIndex: 0, spokenInstructionIndex: 0)
        progress.currentLegProgress.stepIndex = 1
        
        subject.routeProgress = progress
        
        verify(host, for: Device.iPhone8Plus.portrait)
    }
    
    func disableTestTertiaryManeuver() {
        let route = Fixture.route(from: "route-with-tertiary", options: tertiaryRouteOptions)
        
        let host = UIViewController(nibName: nil, bundle: nil)
        let container = UIView.forAutoLayout()
        let subject = InstructionsCardViewController(nibName: nil, bundle: nil)
        
        host.view.addSubview(container)
        constrain(container, to: host.view)
        
        embed(parent: host, child: subject, in: container) { (parent, cards) -> [NSLayoutConstraint] in
            cards.view.translatesAutoresizingMaskIntoConstraints = false
            return cards.view.constraintsForPinning(to: container)
        }
        
        let progress = RouteProgress(route: route, routeIndex: 0, options: tertiaryRouteOptions, legIndex: 0, spokenInstructionIndex: 0)
        progress.currentLegProgress.stepIndex = 5
        
        subject.routeProgress = progress
        subject.view.setNeedsDisplay()
        
        verify(host, for: Device.iPhone8Plus.portrait)
    }
}
