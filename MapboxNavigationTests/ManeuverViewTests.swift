import XCTest
import FBSnapshotTestCase
import MapboxDirections
@testable import MapboxNavigation
@testable import MapboxCoreNavigation


class ManeuverViewTests: FBSnapshotTestCase {
    
    let maneuverView = ManeuverView(frame: CGRect(origin: .zero, size: CGSize(width: 50, height: 50)))
    
    override func setUp() {
        super.setUp()
        maneuverView.backgroundColor = .white
        recordMode = false
        isDeviceAgnostic = false
        usesDrawViewHierarchyInRect = true
        
        let window = UIWindow(frame: maneuverView.bounds)
        window.addSubview(maneuverView)
    }
    
    func maneuverInstruction(_ maneuverType: ManeuverType, _ maneuverDirection: ManeuverDirection, _ drivingSide: DrivingSide, _ degrees: CLLocationDegrees = 180) -> VisualInstruction {
        let primaryInstruction = VisualInstructionComponent(type: .delimiter, text: "", imageURL: nil, maneuverType: maneuverType, maneuverDirection: maneuverDirection, abbreviation: nil, abbreviationPriority: 0)
        return VisualInstruction(distanceAlongStep: 0, primaryText: "", primaryTextComponents: [primaryInstruction], secondaryText: nil, secondaryTextComponents: nil, drivingSide: drivingSide, degrees: degrees)
    }
    
    func testStraightRoundabout() {
        maneuverView.visualInstruction = maneuverInstruction(.takeRoundabout, .straightAhead, .right)
        FBSnapshotVerifyLayer(maneuverView.layer)
    }
    
    func testTurnRight() {
        maneuverView.visualInstruction = maneuverInstruction(.turn, .right, .right)
        FBSnapshotVerifyLayer(maneuverView.layer)
    }
    
    func testTurnSlightRight() {
        maneuverView.visualInstruction = maneuverInstruction(.turn, .slightRight, .right)
        FBSnapshotVerifyLayer(maneuverView.layer)
    }
    
    func testMergeRight() {
        maneuverView.visualInstruction = maneuverInstruction(.merge, .right, .right)
        FBSnapshotVerifyLayer(maneuverView.layer)
    }
    
    func testRoundabout45() {
        maneuverView.visualInstruction = maneuverInstruction(.takeRoundabout, .right, .right, 45)
        FBSnapshotVerifyLayer(maneuverView.layer)
    }
    
    func testRoundabout90() {
        maneuverView.visualInstruction = maneuverInstruction(.takeRoundabout, .right, .right, 90)
        FBSnapshotVerifyLayer(maneuverView.layer)
    }
    
    func testRoundabout135() {
        maneuverView.visualInstruction = maneuverInstruction(.takeRoundabout, .right, .right, 135)
        FBSnapshotVerifyLayer(maneuverView.layer)
    }
    
    func testRoundabout180() {
        maneuverView.visualInstruction = maneuverInstruction(.takeRoundabout, .right, .right, 180)
        FBSnapshotVerifyLayer(maneuverView.layer)
    }
    
    func testRoundabout225() {
        maneuverView.visualInstruction = maneuverInstruction(.takeRoundabout, .right, .right, 225)
        FBSnapshotVerifyLayer(maneuverView.layer)
    }
    
    func testRoundabout315() {
        maneuverView.visualInstruction = maneuverInstruction(.takeRoundabout, .right, .right, 315)
        FBSnapshotVerifyLayer(maneuverView.layer)
    }
    
    func testRoundabout360() {
        maneuverView.visualInstruction = maneuverInstruction(.takeRoundabout, .right, .right, 360)
        FBSnapshotVerifyLayer(maneuverView.layer)
    }
    
    // TODO: Figure out why the flip transformation do not render in a snapshot so we can test left turns and left side rule of the road.
}

