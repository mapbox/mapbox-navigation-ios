import XCTest
import FBSnapshotTestCase
@testable import MapboxDirections
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class MapboxNavigationTests: FBSnapshotTestCase {
    
    var shieldImage: UIImage {
        get {
            let bundle = Bundle(for: MapboxNavigationTests.self)
            return UIImage(named: "80px-I-280", in: bundle, compatibleWith: nil)!
        }
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        recordMode = false
        isDeviceAgnostic = true
    }
    
    func storyboard() -> UIStoryboard {
        return UIStoryboard(name: "Navigation", bundle: Bundle.navigationUI)
    }
    
    func testManeuverViewMultipleLines() {
        let controller = storyboard().instantiateViewController(withIdentifier: "RouteManeuverViewController") as! RouteManeuverViewController
        XCTAssert(controller.view != nil)
        
        controller.distance = nil
        controller.turnArrowView.isEnd = true
        controller.shieldImage = shieldImage
        controller.streetLabel.unabridgedText = "This should be multiple lines"
        controller.streetLabel.backgroundColor = .red
        
        FBSnapshotVerifyView(controller.view)
    }
    
    func testManeuverViewSingleLine() {
        let controller = storyboard().instantiateViewController(withIdentifier: "RouteManeuverViewController") as! RouteManeuverViewController
        XCTAssert(controller.view != nil)
        
        controller.distance = 1000
        controller.turnArrowView.isEnd = true
        controller.shieldImage = shieldImage
        controller.streetLabel.unabridgedText = "Single line"
        controller.streetLabel.backgroundColor = .red
        
        FBSnapshotVerifyView(controller.view)
    }
    
    func testManeuverViewNotAbbreviated() {
        let controller = storyboard().instantiateViewController(withIdentifier: "RouteManeuverViewController") as! RouteManeuverViewController
        XCTAssert(controller.view != nil)
        
        controller.turnArrowView.isEnd = true
        controller.distance = nil
        controller.shieldImage = shieldImage
        controller.streetLabel.unabridgedText = "Spell out Avenue multiple lines"
        controller.streetLabel.backgroundColor = .red
        
        FBSnapshotVerifyView(controller.view)
    }
    
    func testManeuverViewAbbreviated() {
        let controller = storyboard().instantiateViewController(withIdentifier: "RouteManeuverViewController") as! RouteManeuverViewController
        XCTAssert(controller.view != nil)
        
        controller.turnArrowView.isEnd = true
        controller.shieldImage = shieldImage
        controller.distance = 100
        controller.streetLabel.unabridgedText = "This Drive Avenue should be abbreviated."
        controller.streetLabel.backgroundColor = .red
        
        FBSnapshotVerifyView(controller.view)
    }
    
    func testManeuverViewNotAbbreviatedMultipleLines() {
        let controller = storyboard().instantiateViewController(withIdentifier: "RouteManeuverViewController") as! RouteManeuverViewController
        XCTAssert(controller.view != nil)
        
        controller.turnArrowView.isEnd = true
        controller.shieldImage = shieldImage
        controller.distance = nil
        controller.streetLabel.unabridgedText = "This Drive Avenue should be abbreviated on multiple lines...................."
        controller.streetLabel.backgroundColor = .red
        
        FBSnapshotVerifyView(controller.view)
    }
}
