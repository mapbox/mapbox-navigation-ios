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

func instructionsView() -> InstructionsBannerView {
    let bannerHeight: CGFloat = 96
    return InstructionsBannerView(frame: CGRect(origin: .zero, size: CGSize(width: CGSize.iPhone6Plus.width, height: bannerHeight)))
}

var shieldImage: UIImage {
    get {
        let bundle = Bundle(for: MapboxNavigationTests.self)
        return UIImage(named: "i-280", in: bundle, compatibleWith: nil)!
    }
}

class InstructionsBannerViewIntegrationTests: XCTestCase {

    let shieldURL1 = URL(string: "https://s3.amazonaws.com/mapbox/shields/v3/us-41@3x.png")!
    let shieldURL2 = URL(string: "https://s3.amazonaws.com/mapbox/shields/v3/i-94@3x.png")!

    lazy var imageRepository: ImageRepository = {
        let repo = ImageRepository.shared
        repo.sessionConfiguration = URLSessionConfiguration.default
        return repo
    }()

    lazy var instructions = {
        return [
            VisualInstructionComponent(type: .destination, text: "US 41", imageURL: shieldURL1),
            VisualInstructionComponent(type: .delimiter, text: "/", imageURL: nil),
            VisualInstructionComponent(type: .destination, text: "I 94", imageURL: shieldURL2)
        ]
    }()

    override func setUp() {
        super.setUp()

        imageRepository.disableDiskCache()
        let clearImageCacheExpectation = self.expectation(description: "Clear Image Cache")
        imageRepository.resetImageCache {
            clearImageCacheExpectation.fulfill()
        }
        self.wait(for: [clearImageCacheExpectation], timeout: 1)


        TestImageDownloadOperation.reset()
        imageRepository.imageDownloader.setOperationClass(TestImageDownloadOperation.self)
    }

    override func tearDown() {
        super.tearDown()

        imageRepository.imageDownloader.setOperationClass(nil)
    }

    func testDelimiterIsShownWhenShieldsNotLoaded() {
        let view = instructionsView()
        view.set(instructions, secondaryInstruction: nil)

        XCTAssertNotNil(view.primaryLabel.text!.index(of: "/"))
    }

    func testDelimiterIsHiddenWhenAllShieldsAreAlreadyLoaded() {
        //prime the cache to simulate images having already been loaded
        let instruction1 = VisualInstructionComponent(type: .destination, text: nil, imageURL: shieldURL1)
        let instruction2 = VisualInstructionComponent(type: .destination, text: nil, imageURL: shieldURL2)

        imageRepository.storeImage(shieldImage, forKey: instruction1.shieldKey(), toDisk: false)
        imageRepository.storeImage(shieldImage, forKey: instruction2.shieldKey(), toDisk: false)

        let view = instructionsView()
        view.set(instructions, secondaryInstruction: nil)

        //the delimiter should NOT be present since both shields are already in the cache
        XCTAssertNil(view.primaryLabel.text!.index(of: "/"))

        //explicitly reset the cache
        let clearImageCacheExpectation = self.expectation(description: "Clear Image Cache")
        imageRepository.resetImageCache {
            clearImageCacheExpectation.fulfill()
        }
        self.wait(for: [clearImageCacheExpectation], timeout: 1)
    }

    func testDelimiterDisappearsOnlyWhenAllShieldsHaveLoaded() {
        let view = instructionsView()
        view.set(instructions, secondaryInstruction: nil)

        let firstDestinationComponent: VisualInstructionComponent = instructions[0]
        simulateDownloadingShieldForComponent(firstDestinationComponent)

        //Slash should be present until all shields are downloaded
        XCTAssertNotNil(view.primaryLabel.text!.index(of: "/"))

        let secondDestinationComponent = instructions[2]
        simulateDownloadingShieldForComponent(secondDestinationComponent)

        //Slash should no longer be present
        XCTAssertNil(view.primaryLabel.text!.index(of: "/"), "Expected instruction text not to contain a slash: \(view.primaryLabel.text!)")
    }

    private func simulateDownloadingShieldForComponent(_ component: VisualInstructionComponent) {
        let operation: TestImageDownloadOperation = TestImageDownloadOperation.operationForURL(component.imageURL!)!
        operation.completedBlock!(shieldImage, UIImagePNGRepresentation(shieldImage), nil, true)

        XCTAssertNotNil(imageRepository.cachedImageForKey(component.shieldKey()!))
    }

}

class InstructionsBannerViewSnapshotTests: FBSnapshotTestCase {

    let shieldURL = URL(string: "https://s3.amazonaws.com/mapbox/shields/v3/i-280@3x.png")!
    let imageRepository: ImageRepository = ImageRepository.shared

    override func setUp() {
        super.setUp()
        recordMode = false

        let instruction = VisualInstructionComponent(type: .destination, text: nil, imageURL: shieldURL)
        let shieldKey = instruction.shieldKey()
        imageRepository.storeImage(shieldImage, forKey: shieldKey, toDisk: false)
    }

    override func tearDown() {
        super.tearDown()

        let clearImageCacheExpectation = self.expectation(description: "Clear Image Cache")
        imageRepository.resetImageCache {
            clearImageCacheExpectation.fulfill()
        }
        self.wait(for: [clearImageCacheExpectation], timeout: 1)
    }

    func testSinglelinePrimary() {
        let view = instructionsView()
        styleInstructionsView(view)

        view.maneuverView.isStart = true
        view.distance = 482

        let instructions = [
            VisualInstructionComponent(type: .destination, text: "US 45", imageURL: nil),
            VisualInstructionComponent(type: .delimiter, text: "/", imageURL: nil),
            VisualInstructionComponent(type: .destination, text: "Chicago", imageURL: nil)
        ]

        view.set(instructions, secondaryInstruction: nil)

        verifyView(view, size: view.bounds.size)
    }

    func testMultilinePrimary() {
        let view = instructionsView()
        styleInstructionsView(view)

        view.maneuverView.isStart = true
        view.distance = 482

        let instructions = [
            VisualInstructionComponent(type: .destination, text: "I 280", imageURL: shieldURL),
            VisualInstructionComponent(type: .destination, text: "US 45 / Chicago / US 45 / Chicago", imageURL: nil)
        ]

        view.set(instructions, secondaryInstruction: nil)

        verifyView(view, size: view.bounds.size)
    }

    func testSinglelinePrimaryAndSecondary() {
        let view = instructionsView()
        styleInstructionsView(view)

        view.maneuverView.isStart = true
        view.distance = 482

        let primary = [
            VisualInstructionComponent(type: .destination, text: "I 280", imageURL: shieldURL),
            VisualInstructionComponent(type: .destination, text: "South", imageURL: nil)
        ]
        let secondary = [VisualInstructionComponent(type: .destination, text: "US 45 / Chicago", imageURL: nil)]

        view.set(primary, secondaryInstruction: secondary)

        verifyView(view, size: view.bounds.size)
    }

    func testPrimaryShieldAndSecondary() {
        let view = instructionsView()
        styleInstructionsView(view)

        view.maneuverView.isStart = true
        view.distance = 482

        let primary = [
            VisualInstructionComponent(type: .destination, text: "I 280", imageURL: shieldURL)
        ]
        let secondary = [VisualInstructionComponent(type: .destination, text: "Mountain View Test", imageURL: nil)]

        view.set(primary, secondaryInstruction: secondary)

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
            VisualInstructionComponent(type: .destination, text: "I 280", imageURL: shieldURL)
        ]
        let secondary = [VisualInstructionComponent(type: .destination, text: "US 45 / Chicago", imageURL: nil)]

        instructionsBannerView.set(primary, secondaryInstruction: secondary)

        let primaryThen = [
            VisualInstructionComponent(type: .destination, text: "I 280", imageURL: shieldURL)
        ]

        nextBannerView.instructionLabel.instruction = primaryThen
        nextBannerView.maneuverView.backgroundColor = .clear
        nextBannerView.maneuverView.isEnd = true

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
