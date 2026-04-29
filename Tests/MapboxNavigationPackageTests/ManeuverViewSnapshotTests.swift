import CoreLocation
import MapboxDirections
@testable import MapboxNavigationCore
@testable import MapboxNavigationUIKit
import SnapshotTesting
import TestHelper
import XCTest

class ManeuverViewSnapshotTests: TestCase {
    let maneuverView = ManeuverView(frame: CGRect(origin: .zero, size: CGSize(width: 50, height: 50)))

    override func setUp() {
        super.setUp()
        maneuverView.backgroundColor = .white

        let window = UIWindow(frame: maneuverView.bounds)
        window.addSubview(maneuverView)
        DayStyle().apply()
    }

    func maneuverInstruction(
        _ maneuverType: ManeuverType?,
        _ maneuverDirection: ManeuverDirection?,
        _ degrees: CLLocationDegrees = 180
    ) -> VisualInstruction {
        let component = VisualInstruction.Component.delimiter(text: .init(
            text: "",
            abbreviation: nil,
            abbreviationPriority: nil
        ))
        return VisualInstruction(
            text: "",
            maneuverType: maneuverType,
            maneuverDirection: maneuverDirection,
            components: [component],
            degrees: degrees
        )
    }

    func testStraightRoundabout() {
        maneuverView.visualInstruction = maneuverInstruction(.takeRoundabout, .straightAhead)
        assertImageSnapshot(matching: maneuverView.layer, as: .image(precision: 0.99))
    }

    func testTurnRight() {
        maneuverView.visualInstruction = maneuverInstruction(.turn, .right)
        assertImageSnapshot(matching: maneuverView.layer, as: .image(precision: 0.99))
    }

    func testTurnSlightRight() {
        maneuverView.visualInstruction = maneuverInstruction(.turn, .slightRight)
        assertImageSnapshot(matching: maneuverView.layer, as: .image(precision: 0.99))
    }

    func testMergeRight() {
        maneuverView.visualInstruction = maneuverInstruction(.merge, .right)
        assertImageSnapshot(matching: maneuverView.layer, as: .image(precision: 0.99))
    }

    func testRoundaboutTurnLeft() {
        maneuverView.visualInstruction = maneuverInstruction(.takeRoundabout, .right, CLLocationDegrees(270))
        assertImageSnapshot(matching: maneuverView.layer, as: .image(precision: 0.99))
    }

    func testArrive() {
        maneuverView.visualInstruction = maneuverInstruction(.arrive, .right)
        assertImageSnapshot(matching: maneuverView.layer, as: .image(precision: 0.99))
    }

    func testArriveNone() {
        maneuverView.visualInstruction = maneuverInstruction(.arrive, nil)
        assertImageSnapshot(matching: maneuverView.layer, as: .image(precision: 0.99))
    }

    func testLeftUTurn() {
        maneuverView.visualInstruction = maneuverInstruction(.turn, .uTurn)
        maneuverView.drivingSide = .right

        assertImageSnapshot(
            matching: UIImageView(image: maneuverView.imageRepresentation),
            as: .image(precision: 0.99)
        )
    }

    func testRightUTurn() {
        maneuverView.visualInstruction = maneuverInstruction(.turn, .uTurn)
        maneuverView.drivingSide = .left

        assertImageSnapshot(
            matching: UIImageView(image: maneuverView.imageRepresentation),
            as: .image(precision: 0.99)
        )
    }

    func testManeuverTypes() {
        let types: [ManeuverType] = [
            .takeRoundabout,
            .exitRoundabout,
            .takeRotary,
            .exitRotary,
            .turnAtRoundabout,
            .reachFork,
            .reachEnd,
            .useLane,
            .heedWarning,
        ]
        let size = CGSize(width: maneuverView.bounds.width * CGFloat(types.count), height: maneuverView.bounds.height)
        let views = UIView(frame: CGRect(origin: .zero, size: size))

        for (i, type) in types.enumerated() {
            let position = CGPoint(x: maneuverView.bounds.width * CGFloat(i), y: 0)
            let view = ManeuverView(frame: CGRect(origin: position, size: maneuverView.bounds.size))
            view.backgroundColor = .white
            view.visualInstruction = maneuverInstruction(type, .right, CLLocationDegrees(60))
            views.addSubview(view)
        }

        assertImageSnapshot(matching: views.layer, as: .image(precision: 0.99))
    }

    func testRoundabout() {
        let smallAngles = Array(stride(from: CGFloat(0), to: CGFloat(45), by: 15))
        let normalAngles = Array(stride(from: CGFloat(45), to: CGFloat(315), by: 45))
        let largeAngles = Array(stride(from: CGFloat(315), to: CGFloat(361), by: 15))
        let angles = smallAngles + normalAngles + largeAngles

        let size = CGSize(width: maneuverView.bounds.width * CGFloat(angles.count), height: maneuverView.bounds.height)
        let views = UIView(frame: CGRect(origin: .zero, size: size))

        for (i, bearing) in angles.enumerated() {
            let position = CGPoint(x: maneuverView.bounds.width * CGFloat(i), y: 0)
            let view = ManeuverView(frame: CGRect(origin: position, size: maneuverView.bounds.size))
            view.backgroundColor = .white
            view.visualInstruction = maneuverInstruction(.takeRoundabout, .right, CLLocationDegrees(bearing))
            views.addSubview(view)
        }

        assertImageSnapshot(matching: views.layer, as: .image(precision: 0.99))
    }
}
