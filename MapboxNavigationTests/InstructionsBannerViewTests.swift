import XCTest
import FBSnapshotTestCase
import MapboxDirections
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

extension CGSize {
    static let iPhone5      : CGSize    = CGSize(width: 320, height: 568)
    static let iPhone6Plus  : CGSize    = CGSize(width: 414, height: 736)
    static let iPhoneX      : CGSize    = CGSize(width: 375, height: 812)
}

class InstructionsBannerViewTests: FBSnapshotTestCase {
    
    var shieldImage: UIImage {
        get {
            let bundle = Bundle(for: MapboxNavigationTests.self)
            return UIImage(named: "80px-I-280", in: bundle, compatibleWith: nil)!
        }
    }
    
    override func setUp() {
        super.setUp()
        recordMode = false
        
        UIImage.shieldImageCache.setObject(shieldImage, forKey: "I280")
    }
    
    func storyboard() -> UIStoryboard {
        return UIStoryboard(name: "Navigation", bundle: .mapboxNavigation)
    }
    
    func testSinglelinePrimary() {
        let controller = storyboard().instantiateViewController(withIdentifier: "RouteManeuverViewController") as! RouteManeuverViewController
        XCTAssert(controller.view != nil)
        styleInstructionsView(controller.instructionsBannerView)
        
        controller.instructionsBannerView.maneuverView.isStart = true
        controller.distance = 482
        
        controller.instructionsBannerView.set(Instruction([Instruction.Component("US-45 / Chicago")]),
                                              secondaryInstruction: nil)
        
        verifyView(controller.instructionsBannerView, size: .iPhone5)
    }
    
    func testMultilinePrimary() {
        let controller = storyboard().instantiateViewController(withIdentifier: "RouteManeuverViewController") as! RouteManeuverViewController
        XCTAssert(controller.view != nil)
        styleInstructionsView(controller.instructionsBannerView)
        
        controller.instructionsBannerView.maneuverView.isStart = true
        controller.distance = 482
        
        controller.instructionsBannerView.set(Instruction([Instruction.Component("I 280 / South", roadCode: "I 280"),
                                                           Instruction.Component("US-45 / Chicago / US-45 / Chicago")]),
                                              secondaryInstruction: nil)
        
        verifyView(controller.instructionsBannerView, size: .iPhone5)
    }
    
    func testSinglelinePrimaryAndSecondary() {
        let controller = storyboard().instantiateViewController(withIdentifier: "RouteManeuverViewController") as! RouteManeuverViewController
        XCTAssert(controller.view != nil)
        styleInstructionsView(controller.instructionsBannerView)
        
        controller.instructionsBannerView.maneuverView.isStart = true
        controller.distance = 482
        
        controller.instructionsBannerView.set(Instruction([Instruction.Component("I 280 / South", roadCode: "I 280"),
                                                           Instruction.Component("South")]),
                                              secondaryInstruction: Instruction([Instruction.Component("US-45 / Chicago")]))
        
        verifyView(controller.instructionsBannerView, size: .iPhone5)
    }
    
    func testPrimaryShieldAndSecondary() {
        let controller = storyboard().instantiateViewController(withIdentifier: "RouteManeuverViewController") as! RouteManeuverViewController
        XCTAssert(controller.view != nil)
        styleInstructionsView(controller.instructionsBannerView)
        
        controller.instructionsBannerView.maneuverView.isStart = true
        controller.distance = 482
        
        controller.instructionsBannerView.set(Instruction([Instruction.Component("I 280 / South", roadCode: "I 280")]),
                                              secondaryInstruction: Instruction([Instruction.Component("Mountain View Test")]))
        
        verifyView(controller.instructionsBannerView, size: .iPhone5)
    }
    
}

extension InstructionsBannerViewTests {
    
    func verifyView(_ view: UIView, size: CGSize) {
        view.frame.size = size
        FBSnapshotVerifyView(view)
    }
    
    // UIAppearance proxy do not work in unit test environment so we have to style manually
    func styleInstructionsView(_ view: InstructionsBannerView) {
        view.backgroundColor = .white
        view.maneuverView.backgroundColor = #colorLiteral(red: 0.5882352941, green: 0.5882352941, blue: 0.5882352941, alpha: 0.5)
        view.distanceLabel.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 0.5)
        view.primaryLabel.backgroundColor = #colorLiteral(red: 0.5882352941, green: 0.5882352941, blue: 0.5882352941, alpha: 0.5)
        view.secondaryLabel.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 0.5)
        view.dividerView.backgroundColor = .red
        view.separatorView.backgroundColor = .red
        
        view.distanceLabel.valueFont = UIFont.systemFont(ofSize: 24)
        view.distanceLabel.unitFont = UIFont.systemFont(ofSize: 14)
        view.primaryLabel.font = UIFont.systemFont(ofSize: 30, weight: UIFontWeightMedium)
        view.secondaryLabel.font = UIFont.systemFont(ofSize: 26, weight: UIFontWeightMedium)
    }
}
