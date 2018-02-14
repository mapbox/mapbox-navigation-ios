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
        route.accessToken = bogusToken
        recordMode = false
        isDeviceAgnostic = false
        usesDrawViewHierarchyInRect = true
        
        let window = UIWindow(frame: maneuverView.bounds)
        window.addSubview(maneuverView)
    }
    
    func maneuverInstruction(_ maneuverType: ManeuverType, _ maneuverDirection: ManeuverDirection, _ drivingSide: DrivingSide) -> VisualInstruction {
        let primaryInstruction = VisualInstructionComponent(type: .delimiter, text: "", imageURL: nil) // Placeholder
        return VisualInstruction(distanceAlongStep: 0, primaryText: "", primaryTextComponents: [primaryInstruction], secondaryText: nil, secondaryTextComponents: nil, maneuverType: maneuverType, maneuverDirection: maneuverDirection, drivingSide: drivingSide)
    }
    
    func testStraightRoundabout() {
        maneuverView.visualInstruction = maneuverInstruction(.takeRoundabout, .straightAhead, .right)
        FBSnapshotVerifyLayer(maneuverView.layer)
    }
}

