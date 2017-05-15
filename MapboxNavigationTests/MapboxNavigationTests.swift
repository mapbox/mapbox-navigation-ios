import XCTest
import FBSnapshotTestCase
import MapboxDirections
@testable import MapboxNavigation

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
        controller.streetLabel.text = "This should be multiple lines"
        controller.turnArrowView.isEnd = true
        controller.shieldImage = shieldImage
        
        FBSnapshotVerifyView(controller.view)
    }
    
    func testManeuverViewSingleLine() {
        let controller = storyboard().instantiateViewController(withIdentifier: "RouteManeuverViewController") as! RouteManeuverViewController
        XCTAssert(controller.view != nil)
        
        controller.distance = 1000
        controller.streetLabel.text = "This text should shrink"
        controller.turnArrowView.isEnd = true
        controller.shieldImage = shieldImage
        
        FBSnapshotVerifyView(controller.view)
    }
}
