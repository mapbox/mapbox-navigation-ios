import XCTest
import FBSnapshotTestCase
import MapboxDirections
@testable import MapboxNavigation
@testable import MapboxCoreNavigation



func instructionsView(size: CGSize = .iPhone6Plus) -> InstructionsBannerView {
    let bannerHeight: CGFloat = 96
    return InstructionsBannerView(frame: CGRect(origin: .zero, size: CGSize(width: size.width, height: bannerHeight)))
}

func makeVisualInstruction(_ maneuverType: ManeuverType = .arrive,
                           _ maneuverDirection: ManeuverDirection = .left,
                           primaryInstruction: [VisualInstructionComponent],
                           secondaryInstruction: [VisualInstructionComponent]?) -> VisualInstructionBanner {
    
    let primary = VisualInstruction(text: "Instruction", maneuverType: maneuverType, maneuverDirection: maneuverDirection, textComponents: primaryInstruction)
    var secondary: VisualInstruction? = nil
    if let secondaryInstruction = secondaryInstruction {
        secondary = VisualInstruction(text: "Instruction", maneuverType: maneuverType, maneuverDirection: maneuverDirection, textComponents: secondaryInstruction)
    }
    
    return VisualInstructionBanner(distanceAlongStep: 482.803, primaryInstruction: primary, secondaryInstruction: secondary, drivingSide: .right)
}

class InstructionsBannerViewIntegrationTests: XCTestCase {

    lazy var imageRepository: ImageRepository = {
        let repo = ImageRepository.shared
        repo.sessionConfiguration = URLSessionConfiguration.default
        return repo
    }()

    lazy var instructions: [VisualInstructionComponent] = {
         let components =  [
            VisualInstructionComponent(type: .image, text: "US 101", imageURL: ShieldImage.us101.url, abbreviation: nil, abbreviationPriority: 0),
            VisualInstructionComponent(type: .delimiter, text: "/", imageURL: nil, abbreviation: nil, abbreviationPriority: 0),
            VisualInstructionComponent(type: .text, text: "I 280", imageURL: ShieldImage.i280.url, abbreviation: nil, abbreviationPriority: 0)
        ]
        return components
    }()

    private func resetImageCache() {
        let semaphore = DispatchSemaphore(value: 0)
        imageRepository.resetImageCache {
            semaphore.signal()
        }
        let semaphoreResult = semaphore.wait(timeout: XCTestCase.NavigationTests.timeout)
        XCTAssert(semaphoreResult == .success, "Semaphore timed out")
    }

    override func setUp() {
        super.setUp()

        imageRepository.disableDiskCache()
        resetImageCache()

        ImageDownloadOperationSpy.reset()
        imageRepository.imageDownloader.setOperationType(ImageDownloadOperationSpy.self)
    }

    override func tearDown() {
        imageRepository.imageDownloader.setOperationType(nil)

        super.tearDown()
    }

    func testDelimiterIsShownWhenShieldsNotLoaded() {
        let view = instructionsView()

        view.set(makeVisualInstruction(primaryInstruction: instructions, secondaryInstruction: nil))

        XCTAssertNotNil(view.primaryLabel.text!.index(of: "/"))
    }

    func testDelimiterIsHiddenWhenAllShieldsAreAlreadyLoaded() {
        //prime the cache to simulate images having already been loaded
        let instruction1 = VisualInstructionComponent(type: .text, text: nil, imageURL: ShieldImage.i280.url, abbreviation: nil, abbreviationPriority: 0)
        let instruction2 = VisualInstructionComponent(type: .text, text: nil, imageURL: ShieldImage.us101.url, abbreviation: nil, abbreviationPriority: 0)

        imageRepository.storeImage(ShieldImage.i280.image, forKey: instruction1.shieldKey()!, toDisk: false)
        imageRepository.storeImage(ShieldImage.i280.image, forKey: instruction2.shieldKey()!, toDisk: false)

        let view = instructionsView()
        view.set(makeVisualInstruction(primaryInstruction: instructions, secondaryInstruction: nil))

        //the delimiter should NOT be present since both shields are already in the cache
        XCTAssertNil(view.primaryLabel.text!.index(of: "/"))

        //explicitly reset the cache
        resetImageCache()
    }

    func testDelimiterDisappearsOnlyWhenAllShieldsHaveLoaded() {
        let view = instructionsView()
        
        let firstExpectation = XCTestExpectation(description: "First Component Callback")
        let secondExpectation = XCTestExpectation(description: "Second Component Callback")

        view.primaryLabel.imageDownloadCompletion = firstExpectation.fulfill
        
        view.secondaryLabel.imageDownloadCompletion = {
            XCTFail("ImageDownloadCompletion should not have been called on the secondary label.")
        }
        
        //set visual instructions on the view, which triggers the instruction image fetch
        view.set(makeVisualInstruction(primaryInstruction: instructions, secondaryInstruction: nil))

        //Slash should be present until an adjacent shield is downloaded
        XCTAssertNotNil(view.primaryLabel.text!.index(of: "/"))

        //simulate the downloads
        let firstDestinationComponent: VisualInstructionComponent = instructions[0]
        simulateDownloadingShieldForComponent(firstDestinationComponent)

        //ensure that first callback fires
        wait(for: [firstExpectation], timeout: 5)

        //change the callback to track the second shield component
        view.primaryLabel.imageDownloadCompletion = secondExpectation.fulfill
        
        let secondDestinationComponent = instructions[2]
        simulateDownloadingShieldForComponent(secondDestinationComponent)

        //ensure that second callback fires
        wait(for: [secondExpectation], timeout: 5)
 
        //Slash should no longer be present
        XCTAssertNil(view.primaryLabel.text!.index(of: "/"), "Expected instruction text not to contain a slash: \(view.primaryLabel.text!)")
    }
    
    func testExitBannerIntegration() {
        let exitAttribute = VisualInstructionComponent(type: .exit, text: "Exit", imageURL: nil,  abbreviation: nil, abbreviationPriority: 0)
        let exitCodeAttribute = VisualInstructionComponent(type: .exitCode, text: "123A", imageURL: nil, abbreviation: nil, abbreviationPriority: 0)
        let mainStreetString = VisualInstructionComponent(type: .text, text: "Main Street", imageURL: nil, abbreviation: "Main St", abbreviationPriority: 0)
        let exitInstruction = VisualInstruction(text: nil, maneuverType: .takeOffRamp, maneuverDirection: .right, textComponents: [exitAttribute, exitCodeAttribute, mainStreetString])
        
        let label = InstructionLabel(frame: CGRect(origin: .zero, size:CGSize(width: 375, height: 100)))
        
        label.availableBounds = { return label.frame }
        
        let presenter = InstructionPresenter(exitInstruction, dataSource: label, downloadCompletion: nil)
        let attributed = presenter.attributedText()
        
        let spaceRange = NSMakeRange(1, 1)
        let space = attributed.attributedSubstring(from: spaceRange)
        //Do we have spacing between the attachment and the road name?
        XCTAssert(space.string == " ", "Should be a space between exit attachment and name")
        
        //Road Name should be present and not abbreviated
        XCTAssert(attributed.length == 13, "Road name should not be abbreviated")
        
        let roadNameRange = NSMakeRange(2, 11)
        let roadName = attributed.attributedSubstring(from: roadNameRange)
        XCTAssert(roadName.string == "Main Street", "Banner not populating road name correctly")
    }

    private func simulateDownloadingShieldForComponent(_ component: VisualInstructionComponent) {
        let operation: ImageDownloadOperationSpy = ImageDownloadOperationSpy.operationForURL(component.imageURL!)!
        operation.fireAllCompletions(ShieldImage.i280.image, data: UIImagePNGRepresentation(ShieldImage.i280.image), error: nil)

        XCTAssertNotNil(imageRepository.cachedImageForKey(component.shieldKey()!))
    }

}
