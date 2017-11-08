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
    
    let bannerHeight: CGFloat = 96
    
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
    
    func instructionsView() -> InstructionsBannerView {
        return InstructionsBannerView(frame: CGRect(origin: .zero, size: CGSize(width: CGSize.iPhone6Plus.width, height: bannerHeight)))
    }
    
    func testSinglelinePrimary() {
        let view = instructionsView()
        styleInstructionsView(view)
        
        view.maneuverView.isStart = true
        view.distance = 482
        
        view.set(Instruction([Instruction.Component("US-45 / Chicago")]),
                                              secondaryInstruction: nil)
        
        verifyView(view, size: view.bounds.size)
    }
    
    func testMultilinePrimary() {
        let view = instructionsView()
        styleInstructionsView(view)
        
        view.maneuverView.isStart = true
        view.distance = 482
        
        view.set(Instruction([Instruction.Component("I 280 / South", roadCode: "I 280"),
                                                           Instruction.Component("US-45 / Chicago / US-45 / Chicago")]),
                                              secondaryInstruction: nil)
        
        verifyView(view, size: view.bounds.size)
    }
    
    func testSinglelinePrimaryAndSecondary() {
        let view = instructionsView()
        styleInstructionsView(view)
        
        view.maneuverView.isStart = true
        view.distance = 482
        
        view.set(Instruction([Instruction.Component("I 280 / South", roadCode: "I 280"),
                                                           Instruction.Component("South")]),
                                              secondaryInstruction: Instruction([Instruction.Component("US-45 / Chicago")]))
        
        verifyView(view, size: view.bounds.size)
    }
    
    func testPrimaryShieldAndSecondary() {
        let view = instructionsView()
        styleInstructionsView(view)
        
        view.maneuverView.isStart = true
        view.distance = 482
        
        view.set(Instruction([Instruction.Component("I 280 / South", roadCode: "I 280")]),
                                              secondaryInstruction: Instruction([Instruction.Component("Mountain View Test")]))
        
        verifyView(view, size: view.bounds.size)
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
        view._separatorView.backgroundColor = .red
        
        view.distanceLabel.valueFont = UIFont.systemFont(ofSize: 24)
        view.distanceLabel.unitFont = UIFont.systemFont(ofSize: 14)
        view.primaryLabel.font = UIFont.systemFont(ofSize: 30, weight: UIFontWeightMedium)
        view.secondaryLabel.font = UIFont.systemFont(ofSize: 26, weight: UIFontWeightMedium)
    }
}
