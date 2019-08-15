import MapboxDirections
@testable import MapboxNavigation
import MapboxCoreNavigation
import SnappyShrimp
@testable import TestHelper
import Foundation

@available(iOS 11.0, *)
class GuidanceCardsSnapshotTests: SnapshotTest {
    
    override func setUp() {
        super.setUp()
        recordMode = false
    }
    
    func testRegularManeuver() {
        let route = Fixture.route(from: "route-with-tertiary")
        
        let host = UIViewController(nibName: nil, bundle: nil)
        let container = UIView.forAutoLayout()
        let subject = InstructionsCardViewController(nibName: nil, bundle: nil)
        
        host.view.addSubview(container)
        constrain(container, to: host.view)
        
        embed(parent: host, child: subject, in: container) { (parent, cards) -> [NSLayoutConstraint] in
            cards.view.translatesAutoresizingMaskIntoConstraints = false
            return cards.view.constraintsForPinning(to: container)
        }
        
        let progress = RouteProgress(route: route, legIndex: 0, spokenInstructionIndex: 0)
        
        subject.routeProgress = progress
        
        verify(host, for: Device.iPhoneX.portrait)
    }
    
    func testLanesManeuver() {
        let route = Fixture.route(from: "route-with-tertiary")
        
        let host = UIViewController(nibName: nil, bundle: nil)
        let container = UIView.forAutoLayout()
        let subject = InstructionsCardViewController(nibName: nil, bundle: nil)
        
        host.view.addSubview(container)
        constrain(container, to: host.view)
        
        embed(parent: host, child: subject, in: container) { (parent, cards) -> [NSLayoutConstraint] in
            cards.view.translatesAutoresizingMaskIntoConstraints = false
            return cards.view.constraintsForPinning(to: container)
        }
        
        let progress = RouteProgress(route: route, legIndex: 0, spokenInstructionIndex: 0)
        progress.currentLegProgress.stepIndex = 1
        
        subject.routeProgress = progress
        
        verify(host, for: Device.iPhoneX.portrait)
    }
    
    func testTertiaryManeuver() {
        let route = Fixture.route(from: "route-with-tertiary")
        
        let host = UIViewController(nibName: nil, bundle: nil)
        let container = UIView.forAutoLayout()
        let subject = InstructionsCardViewController(nibName: nil, bundle: nil)
        
        host.view.addSubview(container)
        constrain(container, to: host.view)
        
        embed(parent: host, child: subject, in: container) { (parent, cards) -> [NSLayoutConstraint] in
            cards.view.translatesAutoresizingMaskIntoConstraints = false
            return cards.view.constraintsForPinning(to: container)
        }
        
        let progress = RouteProgress(route: route, legIndex: 0, spokenInstructionIndex: 0)
        progress.currentLegProgress.stepIndex = 5
        
        subject.routeProgress = progress
        subject.view.setNeedsDisplay()
        
        verify(host, for: Device.iPhoneX.portrait)
    }

    
    func constrain(_ child: UIView, to parent: UIView) {
        let constraints = [
            child.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            child.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            child.topAnchor.constraint(equalTo: parent.topAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func embed(parent:UIViewController, child: UIViewController, in container: UIView, constrainedBy constraints: ((UIViewController, UIViewController) -> [NSLayoutConstraint])?) {
        child.willMove(toParent: parent)
        parent.addChild(child)
        container.addSubview(child.view)
        if let childConstraints: [NSLayoutConstraint] = constraints?(parent, child) {
            parent.view.addConstraints(childConstraints)
        }
        child.didMove(toParent: parent)
    }
}
