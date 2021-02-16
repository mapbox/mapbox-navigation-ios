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
        let leftHandLanes = TestableLane.testableLanes(drivingSide: .left)
        let rightHandLanes = TestableLane.testableLanes(drivingSide: .right)
        
        func addLanes(lanes: [TestableLane], stackView: UIStackView) {
            let containerView = UIStackView(orientation: .vertical, spacing: 5, autoLayout: true)
            
            for lane in lanes {
                let groupView = UIStackView(orientation: .vertical, autoLayout: true)
                groupView.alignment = .center
                
                let laneView = LaneView(indications: lane.indications, isUsable: true, direction: lane.maneuverDirection)
                laneView.drivingSide = lane.drivingSide
                
                laneView.backgroundColor = .white
                laneView.bounds = CGRect(origin: .zero, size: size)
                
                let label = UILabel(frame: .zero)
                label.textColor = .white
                label.text = "\(lane.description) (\(lane.drivingSide == .left ? "L" : "R"))"
                
                groupView.addArrangedSubview(label)
                groupView.addArrangedSubview(laneView)
                
                containerView.addArrangedSubview(groupView)
            }
            
            stackView.addArrangedSubview(containerView)
        }
        
        let view = UIStackView(orientation: .vertical, spacing: 5, autoLayout: true)
        view.setBackgroundColor(.black)
        
        addLanes(lanes: rightHandLanes, stackView: view)
        addLanes(lanes: leftHandLanes, stackView: view)
        
        verify(view, overallTolerance: 0)
    }
}

struct TestableLane {
    var description: String
    var indications: LaneIndication
    var drivingSide: DrivingSide
    var maneuverDirection: ManeuverDirection
    
    static func testableLanes(drivingSide: DrivingSide) -> [TestableLane] {
        let namedIndications: [(String, LaneIndication, ManeuverDirection)]
        
        namedIndications = [
            ("Sharp Left, Straight Ahead",      [.sharpLeft, .straightAhead], .sharpLeft),
            ("Straight Ahead, Sharp Left",      [.straightAhead, .sharpLeft], .sharpLeft),
            ("Left",                            [.left], .left),
            ("Slight Left",                     [.slightLeft], .slightLeft),
            ("Sharp Left",                      [.sharpLeft], .sharpLeft),
            ("Straight Ahead",                  [.straightAhead], .straightAhead),
            ("u-Turn",                          [.uTurn], .uTurn),
            ("Sharp Right",                     [.sharpRight], .sharpRight),
            ("Slight Right",                    [.slightRight], .slightRight),
            ("Right",                           [.right], .right),
            ("Sharp Right, Straight Ahead",     [.sharpRight, .straightAhead], .sharpRight),
            ("Straight Ahead, Sharp Right",     [.straightAhead, .sharpRight], .sharpRight),
        ]
        
        return namedIndications.map { TestableLane(description: $0.0, indications: $0.1, drivingSide: drivingSide, maneuverDirection: $0.2) }
    }
}

extension UIStackView {
    func setBackgroundColor(_ color: UIColor) {
        let subview = UIView(frame: bounds)
        subview.backgroundColor = color
        subview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(subview, at: 0)
    }
}
