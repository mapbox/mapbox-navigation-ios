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
        agnosticOptions = [.OS, .device]
        usesDrawViewHierarchyInRect = true

        let window = UIWindow(frame: maneuverView.bounds)
        window.addSubview(maneuverView)
    }
    
    func maneuverInstruction(_ maneuverType: ManeuverType, _ maneuverDirection: ManeuverDirection, _ degrees: CLLocationDegrees = 180) -> VisualInstruction {
        let component = VisualInstructionComponent(type: .delimiter, text: "", imageURL: nil, abbreviation: nil, abbreviationPriority: 0)
        return VisualInstruction(text: "", maneuverType: maneuverType, maneuverDirection: maneuverDirection, components: [component], degrees: degrees)
    }

    func testStraightRoundabout() {
        maneuverView.visualInstruction = maneuverInstruction(.takeRoundabout, .straightAhead)
        verify(maneuverView.layer)
    }

    func testTurnRight() {
        maneuverView.visualInstruction = maneuverInstruction(.turn, .right)
        verify(maneuverView.layer)
    }

    func testTurnSlightRight() {
        maneuverView.visualInstruction = maneuverInstruction(.turn, .slightRight)
        verify(maneuverView.layer)
    }

    func testMergeRight() {
        maneuverView.visualInstruction = maneuverInstruction(.merge, .right)
        verify(maneuverView.layer)
    }

    func testRoundaboutTurnLeft() {
        maneuverView.visualInstruction = maneuverInstruction(.takeRoundabout, .right, CLLocationDegrees(270))
        verify(maneuverView.layer)
    }
    
    func testLeftUTurn() {
        maneuverView.drivingSide = .right
        maneuverView.visualInstruction = maneuverInstruction(.turn, .uTurn)
        // Layer transformations are not rendered when snapshotting so we
        // manually flip the U-turn for right-hand rule of the road in this test.
        let image = UIImage(view: maneuverView)!
        let flipped = UIImage(cgImage: image.cgImage!, scale: UIScreen.main.scale, orientation: .upMirrored)
        let imageView = UIImageView(image: flipped)
        verify(imageView)
    }
    
    func testRightUTurn() {
        maneuverView.drivingSide = .left
        maneuverView.visualInstruction = maneuverInstruction(.turn, .uTurn)
        verify(maneuverView.layer)
        let image = UIImage(view: maneuverView)!
        let imageView = UIImageView(image: image)
        verify(imageView)
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
        
        verify(views.layer)
    }
}

extension UIImage {
    
    convenience init?(view: UIView) {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0)
        defer { UIGraphicsEndImageContext() }
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        
        guard let image = UIGraphicsGetImageFromCurrentImageContext(),
            let cgImage = image.cgImage else { return nil }
        
        self.init(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
    }
}
