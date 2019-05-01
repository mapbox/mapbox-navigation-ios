import Foundation
import XCTest
import SnappyShrimp
import MapboxDirections
@testable import TestHelper
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class InstructionsCard: SnapshotTest {
    
    override func setUp() {
        super.setUp()
        recordMode = false
    }
    
    lazy var initialRoute: Route = {
        return Fixture.route(from: jsonFileName)
    }()
    
    @available(iOS 11.0, *)
    func testInstructionsCardCollection() {
        let host = UIViewController(nibName: nil, bundle: nil)
        let container = UIView.forAutoLayout()
        let subject = InstructionsCardCollection(nibName: nil, bundle: nil)
        
        host.view.addSubview(container)
        constrain(container, to: host.view)
        
        embed(parent: host, child: subject, in: container) { (parent, guidanceCard) -> [NSLayoutConstraint] in
            guidanceCard.view.translatesAutoresizingMaskIntoConstraints = false
            return guidanceCard.view.constraintsForPinning(to: container)
        }
        
        let fakeRoute = Fixture.route(from: "route-with-banner-instructions")
        
        let service = MapboxNavigationService(route: initialRoute, directions: DirectionsSpy(accessToken: "knut"), simulating: .never)
        let routeProgress = RouteProgress(route: fakeRoute)
        let intersectionLocation = routeProgress.route.legs.first!.steps.first!.intersections!.first!.location
        let fakeLocation = CLLocation(latitude: intersectionLocation.latitude, longitude: intersectionLocation.longitude)
        subject.steps = routeProgress.steps
        subject.routeProgress = routeProgress
        subject.navigationService(service, didUpdate: routeProgress, with: fakeLocation, rawLocation: fakeLocation)
        
        /// Validate the visible collection view cell
        let cardWidth: CGFloat = 307.0, cardHeight: CGFloat = 100.0
        let visibleCell = subject.collectionView(subject.instructionCollectionView, cellForItemAt: IndexPath(row: 0, section: 0))
        XCTAssertEqual(visibleCell.frame.size, CGSize(width: cardWidth, height: cardHeight))
        XCTAssertEqual(visibleCell.frame.origin, CGPoint(x: 0, y: 0))
        
        /// Validate the partially visible collection view cell
        let collectionViewFlowLayoutMinimumSpacing: CGFloat = 10.0
        let partiallyVisibleCell = subject.collectionView(subject.instructionCollectionView, cellForItemAt: IndexPath(row: 1, section: 0))
        XCTAssertEqual(partiallyVisibleCell.frame.size, CGSize(width: cardWidth, height: cardHeight))
        XCTAssertEqual(partiallyVisibleCell.frame.origin, CGPoint(x: cardWidth + collectionViewFlowLayoutMinimumSpacing, y: 0))
        
        /// Validate the currently setup instructions card's snapshot image
        verify(host, for: Device.iPhoneX.portrait)
    }
    
    func constrain(_ child: UIView, to parent: UIView) {
        let constraints = [
            child.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            child.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            child.topAnchor.constraint(equalTo: parent.topAnchor, constant: 30.0)
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
