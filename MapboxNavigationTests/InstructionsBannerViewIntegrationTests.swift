import XCTest
import FBSnapshotTestCase
import MapboxDirections
@testable import MapboxNavigation
@testable import MapboxCoreNavigation



func instructionsView(size: CGSize = .iPhone6Plus) -> InstructionsBannerView {
    let bannerHeight: CGFloat = 96
    return InstructionsBannerView(frame: CGRect(origin: .zero, size: CGSize(width: size.width, height: bannerHeight)))
}

func makeVisualInstruction(primaryInstruction: [VisualInstructionComponent], secondaryInstruction: [VisualInstructionComponent]?) -> VisualInstruction {
    return VisualInstruction(distanceAlongStep: 482.803, primaryText: "Instruction", primaryTextComponents: primaryInstruction, secondaryText: "Instruction", secondaryTextComponents: secondaryInstruction, drivingSide: .right)
}

class InstructionsBannerViewIntegrationTests: XCTestCase {

    let shieldURL1 = URL(string: "https://s3.amazonaws.com/mapbox/shields/v3/us-41@3x.png")!
    let shieldURL2 = URL(string: "https://s3.amazonaws.com/mapbox/shields/v3/i-94@3x.png")!

    let asyncTimeout: TimeInterval = 2.0

    lazy var imageRepository: ImageRepository = {
        let repo = ImageRepository.shared
        repo.sessionConfiguration = URLSessionConfiguration.default
        return repo
    }()

    lazy var instructions = {
        return [
            VisualInstructionComponent(type: .image, text: "US 41", imageURL: shieldURL1, maneuverType: .none, maneuverDirection: .none, abbreviation: nil, abbreviationPriority: 0),
            VisualInstructionComponent(type: .delimiter, text: "/", imageURL: nil, maneuverType: .none, maneuverDirection: .none, abbreviation: nil, abbreviationPriority: 0),
            VisualInstructionComponent(type: .text, text: "I 94", imageURL: shieldURL2, maneuverType: .none, maneuverDirection: .none, abbreviation: nil, abbreviationPriority: 0)
        ]
    }()

    override func setUp() {
        super.setUp()

        imageRepository.disableDiskCache()
        let clearImageCacheExpectation = self.expectation(description: "Clear Image Cache")
        imageRepository.resetImageCache {
            clearImageCacheExpectation.fulfill()
        }
        self.wait(for: [clearImageCacheExpectation], timeout: asyncTimeout)

        TestImageDownloadOperation.reset()
        imageRepository.imageDownloader.setOperationType(TestImageDownloadOperation.self)
    }

    override func tearDown() {
        super.tearDown()

        imageRepository.imageDownloader.setOperationType(nil)
    }

    func testDelimiterIsShownWhenShieldsNotLoaded() {
        let view = instructionsView()

        view.set(makeVisualInstruction(primaryInstruction: instructions, secondaryInstruction: nil))

        XCTAssertNotNil(view.primaryLabel.text!.index(of: "/"))
    }

    func testDelimiterIsHiddenWhenAllShieldsAreAlreadyLoaded() {
        //prime the cache to simulate images having already been loaded
        let instruction1 = VisualInstructionComponent(type: .text, text: nil, imageURL: shieldURL1, maneuverType: .none, maneuverDirection: .none, abbreviation: nil, abbreviationPriority: 0)
        let instruction2 = VisualInstructionComponent(type: .text, text: nil, imageURL: shieldURL2, maneuverType: .none, maneuverDirection: .none, abbreviation: nil, abbreviationPriority: 0)

        imageRepository.storeImage(ShieldImage.i280.image, forKey: instruction1.shieldKey()!, toDisk: false)
        imageRepository.storeImage(ShieldImage.i280.image, forKey: instruction2.shieldKey()!, toDisk: false)

        let view = instructionsView()
        view.set(makeVisualInstruction(primaryInstruction: instructions, secondaryInstruction: nil))

        //the delimiter should NOT be present since both shields are already in the cache
        XCTAssertNil(view.primaryLabel.text!.index(of: "/"))

        //explicitly reset the cache
        let clearImageCacheExpectation = self.expectation(description: "Clear Image Cache")
        imageRepository.resetImageCache {
            clearImageCacheExpectation.fulfill()
        }
        self.wait(for: [clearImageCacheExpectation], timeout: asyncTimeout)
    }

    func testDelimiterDisappearsOnlyWhenAllShieldsHaveLoaded() {
        let view = instructionsView()
        view.set(makeVisualInstruction(primaryInstruction: instructions, secondaryInstruction: nil))

        //Slash should be present until an adjacent shield is downloaded
        XCTAssertNotNil(view.primaryLabel.text!.index(of: "/"))
        
        let firstDestinationComponent: VisualInstructionComponent = instructions[0]
        simulateDownloadingShieldForComponent(firstDestinationComponent)

        let secondDestinationComponent = instructions[2]
        simulateDownloadingShieldForComponent(secondDestinationComponent)

        //Slash should no longer be present
        XCTAssertNil(view.primaryLabel.text!.index(of: "/"), "Expected instruction text not to contain a slash: \(view.primaryLabel.text!)")
    }

    private func simulateDownloadingShieldForComponent(_ component: VisualInstructionComponent) {
        let operation: TestImageDownloadOperation = TestImageDownloadOperation.operationForURL(component.imageURL!)!
        operation.fireAllCompletions(ShieldImage.i280.image, data: UIImagePNGRepresentation(ShieldImage.i280.image), error: nil)

        XCTAssertNotNil(imageRepository.cachedImageForKey(component.shieldKey()!))
    }

}
