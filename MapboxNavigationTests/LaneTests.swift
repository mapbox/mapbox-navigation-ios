import XCTest
import FBSnapshotTestCase
import MapboxDirections
@testable import TestHelper
@testable import MapboxNavigation
@testable import MapboxCoreNavigation


class LaneTests: FBSnapshotTestCase {
    
    override func setUp() {
        super.setUp()
        recordMode = false
        agnosticOptions = [.OS, .device]
    }
    
    func testAllLanes30x30() {
        verifyAllLanes(size: CGSize(size: 30))
    }
    
    func testAllLanes90x90() {
        verifyAllLanes(size: CGSize(size: 90))
    }
    
    func verifyAllLanes(size: CGSize) {
        
        let testableLanes = TestableLane.testableLanes(drivingSide: .right)
        let padding: CGFloat = 4
        let count = CGFloat(testableLanes.count)
        let viewSize = CGSize(width: size.width * count + padding * (count + 1),
                              height: size.height * CGFloat(2) + padding * 3)
        
        let view = UIView(frame: CGRect(origin: .zero, size: viewSize))
        view.backgroundColor = .black
        
        for (i, lane) in testableLanes.enumerated() {
            
            let usableComponent = LaneIndicationComponent(indications: lane.indications, isUsable: true)
            let unusableComponent = LaneIndicationComponent(indications: lane.indications, isUsable: false)
            
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

struct TestableLane {
    var description: String
    var indications: LaneIndication
    var drivingSide: DrivingSide
    
    static func testableLanes(drivingSide: DrivingSide) -> [TestableLane] {
        let namedIndications: [(String, LaneIndication)]
        
        namedIndications = [
            ("Left", [.left]),
            ("Slight Left", [.slightLeft]),
            ("Sharp Left", [.sharpLeft]),
            ("Straight Ahead", [.straightAhead]),
            ("u-Turn", [.uTurn]),
            ("Sharp Right", [.sharpRight]),
            ("Slight Right", [.slightRight]),
            ("Right", [.right]),
            ("Sharp Right, Straight Ahead", [.sharpRight, .straightAhead]),
            ("Straight Ahead, Sharp Right", [.straightAhead, .sharpRight]),
        ]
        
        return namedIndications.map { TestableLane(description: $0.0, indications: $0.1, drivingSide: drivingSide) }
    }
}
