import XCTest
import FBSnapshotTestCase
import MapboxDirections
@testable import MapboxNavigation
@testable import MapboxCoreNavigation


class ManeuverViewTests: FBSnapshotTestCase {
    
    let route = Fixture.route(from: "route-with-straight-roundabout", waypoints: [Waypoint(coordinate: CLLocationCoordinate2D(latitude: 59.215, longitude: 17.6334)), Waypoint(coordinate: CLLocationCoordinate2D(latitude: 59.2164, longitude: 17.6353))])
    let maneuverView = ManeuverView(frame: CGRect(origin: .zero, size: CGSize(width: 50, height: 50)))
    
    override func setUp() {
        super.setUp()
        maneuverView.backgroundColor = .white
        route.accessToken = bogusToken
        recordMode = false
        isDeviceAgnostic = false
    }
    
    func maneuverInstruction(_ maneuverType: ManeuverType, _ maneuverDirection: ManeuverDirection, _ drivingSide: DrivingSide) -> VisualInstruction {
        let primaryInstruction = VisualInstructionComponent(type: .delimiter, text: "", imageURL: nil) // Placeholder
        return VisualInstruction(distanceAlongStep: 0, primaryText: "", primaryTextComponents: [primaryInstruction], secondaryText: nil, secondaryTextComponents: nil, maneuverType: maneuverType, maneuverDirection: maneuverDirection, drivingSide: drivingSide)
    }
    
    func testStraightRoundabout() {
        let instruction = maneuverInstruction(.takeRoundabout, .straightAhead, .right)
        maneuverView.visualInstruction = instruction
        FBSnapshotVerifyView(maneuverView)
    }
}

