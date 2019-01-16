import XCTest
import FBSnapshotTestCase
import MapboxDirections
@testable import TestHelper
@testable import MapboxNavigation
@testable import MapboxCoreNavigation


class LaneTests: FBSnapshotTestCase {
    
    let route = Fixture.route(from: "route-for-lane-testing")
    
    var steps: [RouteStep]!
    var routeProgress: RouteProgress!
    var routeController: RouteController!
    let routerDataSource = RouteControllerDataSourceFake()
    var directions: DirectionsSpy!
    
    override func setUp() {
        super.setUp()
        recordMode = false
        agnosticOptions = [.OS, .device]
        
        let bogusToken = "pk.feedCafeDeadBeefBadeBede"
        directions = DirectionsSpy(accessToken: bogusToken)
        
        route.accessToken = bogusToken
        routeController = RouteController(along: route, directions: directions, dataSource: routerDataSource)
        
        steps = routeController.routeProgress.currentLeg.steps
        routeProgress = routeController.routeProgress
    }
    
    func assertLanes(stepIndex: Array<RouteStep>.Index) {
        let rect = CGRect(origin: .zero, size: .iPhone6Plus)
        let navigationView = NavigationView(frame: rect)
        
        routeController.advanceStepIndex(to: stepIndex)
        
        navigationView.lanesView.update(for: routeController.routeProgress.currentLegProgress.currentStepProgress.currentVisualInstruction)
        navigationView.lanesView.show(animated: false)
        
        verify(navigationView.lanesView)
    }
    
    func testStraightRight() {
        assertLanes(stepIndex: 0)
    }
    
    func testRightRight() {
        assertLanes(stepIndex: 1)
    }
    
    func testSlightRight() {
        let view = LaneView(frame: CGRect(origin: .zero, size: CGSize(width: 30, height: 30)))
        view.backgroundColor = .white
        view.lane = Lane(indications: [.slightRight])
        view.maneuverDirection = .slightRight
        view.isValid = true
        verify(view)
    }
    
    func testAllLanes30x30() {
        verifyAllLanes(size: CGSize(size: 30))
    }
    
    func testAllLanes90x90() {
        verifyAllLanes(size: CGSize(size: 90))
    }
    
    func verifyAllLanes(size: CGSize) {
        
        let padding: CGFloat = 4
        let count = CGFloat(LaneIndication.allCases.count)
        let viewSize = CGSize(width: size.width * count + padding * (count + 1),
                              height: size.height * CGFloat(2) + padding * 3)
        
        let view = UIView(frame: CGRect(origin: .zero, size: viewSize))
        view.backgroundColor = .black
        
        for (i, indication) in LaneIndication.allCases.enumerated() {
            
            let usableComponent = LaneIndicationComponent(indications: indication, isUsable: true)
            let unusableComponent = LaneIndicationComponent(indications: indication, isUsable: false)
            
            let usableLane = LaneView(component: usableComponent)
            let unusableLane = LaneView(component: unusableComponent)
            
            usableLane.backgroundColor = .white
            unusableLane.backgroundColor = .white
            
            usableLane.frame = CGRect(origin: CGPoint(x: size.width * CGFloat(i) + padding * CGFloat(i + 1),
                                                      y: padding), size: size)
            unusableLane.frame = CGRect(origin: CGPoint(x: size.width * CGFloat(i)  + padding * CGFloat(i + 1),
                                                        y: size.height + padding * 2), size: size)
            
            view.addSubview(usableLane)
            view.addSubview(unusableLane)
        }
        
        verify(view, overallTolerance: 0)
    }
}

extension LaneIndication: CaseIterable {
    
    public static var allCases: [LaneIndication] {
        return [LaneIndication.straightAhead,
                LaneIndication.uTurn,
                LaneIndication.left,
                LaneIndication.slightLeft,
                LaneIndication.sharpLeft,
                LaneIndication.right,
                LaneIndication.slightRight,
                LaneIndication.sharpRight]
    }
}
