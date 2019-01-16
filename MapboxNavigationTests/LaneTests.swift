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
            
            let horizontalStackView = UIStackView(orientation: .horizontal, spacing: 5, autoLayout: true)
            horizontalStackView.distribution = .equalCentering
            
            for lane in lanes {
                let groupView = UIStackView(orientation: .vertical, autoLayout: true)
                groupView.distribution = .equalCentering
                groupView.alignment = .center
                
                let component = LaneIndicationComponent(indications: lane.indications, isUsable: true)
                let laneView = LaneView(component: component)
                
                laneView.backgroundColor = .white
                laneView.widthAnchor.constraint(equalToConstant: size.width)
                laneView.heightAnchor.constraint(equalToConstant: size.height)
                
                let label = UILabel(frame: .zero)
                label.textColor = .white
                label.text = "\(lane.description) (\(lane.drivingSide == .left ? "L" : "R"))"
                label.widthAnchor.constraint(equalTo: laneView.widthAnchor)
                
                groupView.addArrangedSubview(label)
                groupView.addArrangedSubview(laneView)
                
                horizontalStackView.addArrangedSubview(groupView)
            }
            
            stackView.addArrangedSubview(horizontalStackView)
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
    
    static func testableLanes(drivingSide: DrivingSide) -> [TestableLane] {
        let namedIndications: [(String, LaneIndication)]
        
        namedIndications = [
            ("Sharp Left, Straight Ahead",      [.sharpLeft, .straightAhead]),
            ("Straight Ahead, Sharp Left",      [.straightAhead, .sharpLeft]),
            ("Left",                            [.left]),
            ("Slight Left",                     [.slightLeft]),
            ("Sharp Left",                      [.sharpLeft]),
            ("Straight Ahead",                  [.straightAhead]),
            ("u-Turn",                          [.uTurn]),
            ("Sharp Right",                     [.sharpRight]),
            ("Slight Right",                    [.slightRight]),
            ("Right",                           [.right]),
            ("Sharp Right, Straight Ahead",     [.sharpRight, .straightAhead]),
            ("Straight Ahead, Sharp Right",     [.straightAhead, .sharpRight]),
        ]
        
        return namedIndications.map { TestableLane(description: $0.0, indications: $0.1, drivingSide: drivingSide) }
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
