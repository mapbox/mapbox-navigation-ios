import XCTest
import FBSnapshotTestCase
import MapboxDirections
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class InstructionsBannerViewSnapshotTests: FBSnapshotTestCase {
    
    let imageRepository: ImageRepository = ImageRepository.shared
    
    let asyncTimeout: TimeInterval = 2.0
    
    override func setUp() {
        super.setUp()
        recordMode = false
        
        let i280Instruction = VisualInstructionComponent(type: .text, text: nil, imageURL: ShieldImage.i280.url, maneuverType: .turn, maneuverDirection: .right, abbreviation: nil, abbreviationPriority: 0)
        let us101Instruction = VisualInstructionComponent(type: .text, text: nil, imageURL: ShieldImage.us101.url, maneuverType: .turn, maneuverDirection: .right, abbreviation: nil, abbreviationPriority: 0)
        
        imageRepository.storeImage(ShieldImage.i280.image, forKey: i280Instruction.shieldKey()!, toDisk: false)
        imageRepository.storeImage(ShieldImage.us101.image, forKey: us101Instruction.shieldKey()!, toDisk: false)
        
        NavigationSettings.shared.distanceUnit = .mile
    }
    
    override func tearDown() {
        super.tearDown()
        
        let clearImageCacheExpectation = self.expectation(description: "Clear Image Cache")
        imageRepository.resetImageCache {
            clearImageCacheExpectation.fulfill()
        }
        self.wait(for: [clearImageCacheExpectation], timeout: asyncTimeout)
    }
    
    func testSinglelinePrimary() {
        let view = instructionsView()
        styleInstructionsView(view)
        
        view.maneuverView.isStart = true
        view.distance = 482
        
        let instructions = [
            VisualInstructionComponent(type: .text, text: "US 45", imageURL: nil, maneuverType: .turn, maneuverDirection: .right, abbreviation: nil, abbreviationPriority: 0),
            VisualInstructionComponent(type: .text, text: "/", imageURL: nil, maneuverType: .turn, maneuverDirection: .right, abbreviation: nil, abbreviationPriority: 0),
            VisualInstructionComponent(type: .text, text: "Chicago", imageURL: nil, maneuverType: .turn, maneuverDirection: .right, abbreviation: nil, abbreviationPriority: 0)
        ]
        
        view.set(makeVisualInstruction(primaryInstruction: instructions, secondaryInstruction: nil))
        
        verifyView(view, size: view.bounds.size)
    }
    
    func testMultilinePrimary() {
        let view = instructionsView()
        styleInstructionsView(view)
        
        view.maneuverView.isStart = true
        view.distance = 482
        
        let instructions = [
            VisualInstructionComponent(type: .text, text: "I 280", imageURL: ShieldImage.i280.url, maneuverType: .turn, maneuverDirection: .right, abbreviation: nil, abbreviationPriority: 0),
            VisualInstructionComponent(type: .text, text: "US 45 / Chicago / US 45 / Chicago", imageURL: nil, maneuverType: .turn, maneuverDirection: .right, abbreviation: nil, abbreviationPriority: 0)
        ]
        
        view.set(makeVisualInstruction(primaryInstruction: instructions, secondaryInstruction: nil))
        
        verifyView(view, size: view.bounds.size)
    }
    
    func testSinglelinePrimaryAndSecondary() {
        let view = instructionsView()
        styleInstructionsView(view)
        
        view.maneuverView.isStart = true
        view.distance = 482
        
        let primary = [
            VisualInstructionComponent(type: .text, text: "I 280", imageURL: ShieldImage.i280.url, maneuverType: .turn, maneuverDirection: .right, abbreviation: nil, abbreviationPriority: 0),
            VisualInstructionComponent(type: .text, text: "South", imageURL: nil, maneuverType: .turn, maneuverDirection: .right, abbreviation: nil, abbreviationPriority: 0)
        ]
        let secondary = [VisualInstructionComponent(type: .text, text: "US 45 / Chicago", imageURL: nil, maneuverType: .turn, maneuverDirection: .right, abbreviation: nil, abbreviationPriority: 0)]
        
        view.set(makeVisualInstruction(primaryInstruction: primary, secondaryInstruction: secondary))
        
        verifyView(view, size: view.bounds.size)
    }
    
    func testPrimaryShieldAndSecondary() {
        let view = instructionsView()
        styleInstructionsView(view)
        
        view.maneuverView.isStart = true
        view.distance = 482
        
        let primary = [
            VisualInstructionComponent(type: .text, text: "I 280", imageURL: ShieldImage.i280.url, maneuverType: .turn, maneuverDirection: .right, abbreviation: nil, abbreviationPriority: 0)
        ]
        let secondary = [VisualInstructionComponent(type: .text, text: "Mountain View Test", imageURL: nil, maneuverType: .turn, maneuverDirection: .right, abbreviation: nil, abbreviationPriority: 0)]
        
        view.set(makeVisualInstruction(primaryInstruction: primary, secondaryInstruction: secondary))
        
        verifyView(view, size: view.bounds.size)
    }
    
    func testAbbreviateInstructions() {
        let view = instructionsView()
        styleInstructionsView(view)
        
        view.maneuverView.isStart = true
        view.distance = 482
        
        let primary = [VisualInstructionComponent(type: .image, text: "I-280", imageURL: ShieldImage.i280.url, maneuverType: .none, maneuverDirection: .none, abbreviation: nil, abbreviationPriority: NSNotFound),
                       VisualInstructionComponent(type: .text, text: "Drive", imageURL: nil, maneuverType: .none, maneuverDirection: .none, abbreviation: "Dr", abbreviationPriority: 0),
                       VisualInstructionComponent(type: .text, text: "Avenue", imageURL: nil, maneuverType: .none, maneuverDirection: .none, abbreviation: "Ave", abbreviationPriority: 5),
                       VisualInstructionComponent(type: .text, text: "West", imageURL: nil, maneuverType: .none, maneuverDirection: .none, abbreviation: "W", abbreviationPriority: 4),
                       VisualInstructionComponent(type: .text, text: "South", imageURL: nil, maneuverType: .none, maneuverDirection: .none, abbreviation: "S", abbreviationPriority: 3),
                       VisualInstructionComponent(type: .text, text: "East", imageURL: nil, maneuverType: .none, maneuverDirection: .none, abbreviation: "E", abbreviationPriority: 2),
                       VisualInstructionComponent(type: .text, text: "North", imageURL: nil, maneuverType: .none, maneuverDirection: .none, abbreviation: "N", abbreviationPriority: 1)]
        
        view.set(makeVisualInstruction(primaryInstruction: primary, secondaryInstruction: nil))
        
        verifyView(view, size: view.bounds.size)
    }
    
    func testAbbreviateInstructionsIncludingDelimiter() {
        let view = instructionsView()
        styleInstructionsView(view)
        
        view.maneuverView.isStart = true
        view.distance = 482
        
        let primary = [VisualInstructionComponent(type: .image, text: "I-280", imageURL: ShieldImage.i280.url, maneuverType: .none, maneuverDirection: .none, abbreviation: nil, abbreviationPriority: NSNotFound),
                       VisualInstructionComponent(type: .delimiter, text: "/", imageURL: nil, maneuverType: .none, maneuverDirection: .none, abbreviation: nil, abbreviationPriority: NSNotFound),
                       VisualInstructionComponent(type: .text, text: "10", imageURL: nil, maneuverType: .none, maneuverDirection: .none, abbreviation: nil, abbreviationPriority: NSNotFound),
                       VisualInstructionComponent(type: .delimiter, text: "/", imageURL: nil, maneuverType: .none, maneuverDirection: .none, abbreviation: nil, abbreviationPriority: NSNotFound),
                       VisualInstructionComponent(type: .text, text: "15 North", imageURL: nil, maneuverType: .none, maneuverDirection: .none, abbreviation: "15 N", abbreviationPriority: 0),
                       VisualInstructionComponent(type: .delimiter, text: "/", imageURL: nil, maneuverType: .none, maneuverDirection: .none, abbreviation: nil, abbreviationPriority: NSNotFound),
                       VisualInstructionComponent(type: .text, text: "20 West", imageURL: nil, maneuverType: .none, maneuverDirection: .none, abbreviation: "20 W", abbreviationPriority: 1)]
        view.set(makeVisualInstruction(primaryInstruction: primary, secondaryInstruction: nil))
        
        verifyView(view, size: view.bounds.size)
    }
    
    func testAbbreviateWestFremontAvenue() {
        let view = instructionsView(size: .iPhoneX)
        styleInstructionsView(view)
        
        view.maneuverView.isStart = true
        view.distance = 482
        
        let primary = [
                       VisualInstructionComponent(type: .text, text: "West", imageURL: nil, maneuverType: .none, maneuverDirection: .none, abbreviation: "W", abbreviationPriority: 0),
                       VisualInstructionComponent(type: .text, text: "Fremont", imageURL: nil, maneuverType: .none, maneuverDirection: .none, abbreviation: nil, abbreviationPriority: NSNotFound),
                       VisualInstructionComponent(type: .text, text: "Avenue", imageURL: nil, maneuverType: .none, maneuverDirection: .none, abbreviation: "Ave", abbreviationPriority: 1)
        ]
        
        view.set(makeVisualInstruction(primaryInstruction: primary, secondaryInstruction: nil))
        
        verifyView(view, size: view.bounds.size)
    }
    
    func testAdjacentShields() {
        let view = instructionsView(size: .iPhoneX)
        styleInstructionsView(view)
        view.maneuverView.isStart = true
        view.distance = 482
        
        let primary = [
            VisualInstructionComponent(type: .text, text: "I-280", imageURL: ShieldImage.i280.url, maneuverType: .none, maneuverDirection: .none, abbreviation: nil, abbreviationPriority: NSNotFound),
            VisualInstructionComponent(type: .delimiter, text: "/", imageURL: nil, maneuverType: .none, maneuverDirection: .none, abbreviation: nil, abbreviationPriority: NSNotFound),
            VisualInstructionComponent(type: .text, text: "US-101", imageURL: ShieldImage.us101.url, maneuverType: .none, maneuverDirection: .none, abbreviation: nil, abbreviationPriority: NSNotFound)
        ]
        
        view.set(makeVisualInstruction(primaryInstruction: primary, secondaryInstruction: nil))
        
        verifyView(view, size: view.bounds.size)
    }
    
    func testInstructionsAndNextInstructions() {
        let view = UIView()
        view.backgroundColor = .white
        let instructionsBannerView = instructionsView()
        let nextBannerViewFrame = CGRect(x: 0, y: instructionsBannerView.frame.maxY, width: instructionsBannerView.bounds.width, height: 44)
        let nextBannerView = NextBannerView(frame: nextBannerViewFrame)
        nextBannerView.translatesAutoresizingMaskIntoConstraints = true
        view.addSubview(instructionsBannerView)
        view.addSubview(nextBannerView)
        view.frame = CGRect(origin: .zero, size: CGSize(width: nextBannerViewFrame.width, height: nextBannerViewFrame.maxY))
        
        instructionsBannerView.maneuverView.isStart = true
        instructionsBannerView.distance = 482
        
        let primary = [
            VisualInstructionComponent(type: .text, text: "I 280", imageURL: ShieldImage.i280.url, maneuverType: .turn, maneuverDirection: .right, abbreviation: nil, abbreviationPriority: 0)
        ]
        let secondary = [VisualInstructionComponent(type: .text, text: "US 45 / Chicago", imageURL: nil, maneuverType: .turn, maneuverDirection: .right, abbreviation: nil, abbreviationPriority: 0)]
        
        instructionsBannerView.set(makeVisualInstruction(primaryInstruction: primary, secondaryInstruction: secondary))
        
        let primaryThen = [
            VisualInstructionComponent(type: .text, text: "I 280", imageURL: ShieldImage.i280.url, maneuverType: .turn, maneuverDirection: .right, abbreviation: nil, abbreviationPriority: 0)
        ]
        
        nextBannerView.instructionLabel.instruction = primaryThen
        nextBannerView.maneuverView.backgroundColor = .clear
        nextBannerView.maneuverView.isEnd = true
        
        verifyView(view, size: view.bounds.size)
    }
    
    func testLongDistance() {
        let view = instructionsView(size: .iPhoneX)
        styleInstructionsView(view)
        
        view.maneuverView.isStart = true
        NavigationSettings.shared.distanceUnit = .kilometer
        view.distanceFormatter.numberFormatter.locale = Locale(identifier: "zh-Hans")
        view.distance = 1000 * 999
        
        let primary = [VisualInstructionComponent(type: .text, text: "中国 安徽省 宣城市 郎溪县", imageURL: nil, maneuverType: .none, maneuverDirection: .none, abbreviation: nil, abbreviationPriority: NSNotFound)]
        view.set(makeVisualInstruction(primaryInstruction: primary, secondaryInstruction: nil))
        
        verifyView(view, size: view.bounds.size)
    }
}

extension InstructionsBannerViewSnapshotTests {
    
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
        view.primaryLabel.font = UIFont.systemFont(ofSize: 30, weight: .medium)
        view.secondaryLabel.font = UIFont.systemFont(ofSize: 26, weight: .medium)
    }
}
