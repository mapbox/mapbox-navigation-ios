import XCTest
import SnapshotTesting
import MapboxDirections
import CoreLocation
import TestHelper
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class ManeuverViewSnapshotTests: TestCase {
    let maneuverView = ManeuverView(frame: CGRect(origin: .zero, size: CGSize(width: 50, height: 50)))

    override func setUp() {
        super.setUp()
        maneuverView.backgroundColor = .white
        isRecording = false

        let window = UIWindow(frame: maneuverView.bounds)
        window.addSubview(maneuverView)
        DayStyle().apply()
    }
    
    func maneuverInstruction(_ maneuverType: ManeuverType?,
                             _ maneuverDirection: ManeuverDirection?,
                             _ degrees: CLLocationDegrees = 180) -> VisualInstruction {
        let component = VisualInstruction.Component.delimiter(text: .init(text: "",
                                                                          abbreviation: nil,
                                                                          abbreviationPriority: nil))
        return VisualInstruction(text: "",
                                 maneuverType: maneuverType,
                                 maneuverDirection: maneuverDirection,
                                 components: [component],
                                 degrees: degrees)
    }

    func testStraightRoundabout() {
        maneuverView.visualInstruction = maneuverInstruction(.takeRoundabout, .straightAhead)
        assertImageSnapshot(matching: maneuverView.layer, as: .image(precision: 0.95))
    }

    func testTurnRight() {
        maneuverView.visualInstruction = maneuverInstruction(.turn, .right)
        assertImageSnapshot(matching: maneuverView.layer, as: .image(precision: 0.95))
    }

    func testTurnSlightRight() {
        maneuverView.visualInstruction = maneuverInstruction(.turn, .slightRight)
        assertImageSnapshot(matching: maneuverView.layer, as: .image(precision: 0.95))
    }

    func testMergeRight() {
        maneuverView.visualInstruction = maneuverInstruction(.merge, .right)
        assertImageSnapshot(matching: maneuverView.layer, as: .image(precision: 0.95))
    }

    func testRoundaboutTurnLeft() {
        maneuverView.visualInstruction = maneuverInstruction(.takeRoundabout, .right, CLLocationDegrees(270))
        assertImageSnapshot(matching: maneuverView.layer, as: .image(precision: 0.95))
    }

    func testArrive() {
        maneuverView.visualInstruction = maneuverInstruction(.arrive, .right)
        assertImageSnapshot(matching: maneuverView.layer, as: .image(precision: 0.95))
    }

    func testArriveNone() {
        maneuverView.visualInstruction = maneuverInstruction(.arrive, nil)
        assertImageSnapshot(matching: maneuverView.layer, as: .image(precision: 0.95))
    }

    func testLeftUTurn() {
        maneuverView.visualInstruction = maneuverInstruction(.turn, .uTurn)
        maneuverView.drivingSide = .right
        
        assertImageSnapshot(matching: UIImageView(image: maneuverView.imageRepresentation),
                            as: .image(precision: 0.95))
    }

    func testRightUTurn() {
        maneuverView.visualInstruction = maneuverInstruction(.turn, .uTurn)
        maneuverView.drivingSide = .left

        assertImageSnapshot(matching: UIImageView(image: maneuverView.imageRepresentation),
                            as: .image(precision: 0.95))
    }

    func testRoundabout() {
        let incrementer: CGFloat = 45
        let size = CGSize(width: maneuverView.bounds.width * (360 / incrementer), height: maneuverView.bounds.height)
        let views = UIView(frame: CGRect(origin: .zero, size: size))

        for bearing in stride(from: CGFloat(0), to: CGFloat(360), by: incrementer) {
            let position = CGPoint(x: maneuverView.bounds.width * (bearing / incrementer), y: 0)
            let view = ManeuverView(frame: CGRect(origin: position, size: maneuverView.bounds.size))
            view.backgroundColor = .white
            view.visualInstruction = maneuverInstruction(.takeRoundabout, .right, CLLocationDegrees(bearing))
            views.addSubview(view)
        }

        assertImageSnapshot(matching: views.layer, as: .image(precision: 0.95))
    }
}
