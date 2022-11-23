import XCTest
import TestHelper
import MapboxDirections
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class InstructionsBannerViewIntegrationTests: InstructionBannerTest {
    private var reverseDelegate: TextReversingDelegate!
    private var silentDelegate: DefaultBehaviorDelegate!

    lazy var instructions: [VisualInstruction.Component] = {
        let components: [VisualInstruction.Component] =  [
            .image(image: .init(imageBaseURL: ShieldImage.us101.baseURL), alternativeText: .init(text: "US 101", abbreviation: nil, abbreviationPriority: 0)),
            .delimiter(text: .init(text: "/", abbreviation: nil, abbreviationPriority: 0)),
            .image(image: .init(imageBaseURL: ShieldImage.i280.baseURL), alternativeText: .init(text: "I 280", abbreviation: nil, abbreviationPriority: 0)),
        ]
        return components
    }()
    
    lazy var genericInstructions: [VisualInstruction.Component] = [
        .image(image: .init(imageBaseURL: nil), alternativeText: .init(text: "ANK 1", abbreviation: nil, abbreviationPriority: nil)),
        .text(text: .init(text: "Ankh-Morpork Highway 1", abbreviation: nil, abbreviationPriority: nil)),
    ]
    
    lazy var typicalInstruction: VisualInstructionBanner = makeVisualInstruction(primaryInstruction: [.text(text: .init(text: "Main Street", abbreviation: "Main St", abbreviationPriority: 0))], secondaryInstruction: nil)

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        cacheSprite()
        reverseDelegate = TextReversingDelegate()
        silentDelegate = DefaultBehaviorDelegate()
        spriteRepository.imageDownloader.setOperationType(ImageDownloadOperationSpy.self)
    }

    override func tearDown() {
        super.tearDown()

        clearDiskCache()
        spriteRepository.imageDownloader.setOperationType(nil)
        ImageDownloadOperationSpy.reset()
    }
    
    func testCustomVisualInstructionDelegate() {
        let view = instructionsView()
        view.delegate = reverseDelegate
        
        view.update(for: typicalInstruction)
        
        XCTAssert(view.primaryLabel.attributedText?.string == "teertS niaM")
    }
    
    func testCustomDelegateReturningNilTriggersDefaultBehavior() {
        let view = instructionsView()
        view.delegate = silentDelegate
        
        view.update(for: typicalInstruction)
        
        XCTAssert(view.primaryLabel.attributedText?.string == "Main Street")
    }
    
    func testDelimiterIsShownWhenShieldsNotLoaded() {
        let view = instructionsView()

        view.update(for: makeVisualInstruction(primaryInstruction: instructions, secondaryInstruction: nil))

        XCTAssertNotNil(view.primaryLabel.text!.firstIndex(of: "/"))
    }

    func testDelimiterIsHiddenWhenAllShieldsAreAlreadyLoaded() {
        //prime the cache to simulate images having already been loaded
        let representation1 = VisualInstruction.Component.ImageRepresentation(imageBaseURL: ShieldImage.i280.baseURL)
        let representation2 = VisualInstruction.Component.ImageRepresentation(imageBaseURL: ShieldImage.us101.baseURL)

        cacheLegacyIcon(with: representation1, shieldImage: .i280)
        cacheLegacyIcon(with: representation2, shieldImage: .us101)

        let view = instructionsView()
        view.update(for: makeVisualInstruction(primaryInstruction: instructions, secondaryInstruction: nil))

        //the delimiter should NOT be present since both shields are already in the cache
        XCTAssertNil(view.primaryLabel.text!.firstIndex(of: "/"))

        //explicitly reset the cache
        spriteRepository.requestCache.clearCache()
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
        view.update(for: makeVisualInstruction(primaryInstruction: instructions, secondaryInstruction: nil))

        //Slash should be present until an adjacent shield is downloaded
        XCTAssertNotNil(view.primaryLabel.text!.firstIndex(of: "/"))

        //simulate the downloads
        let firstDestinationComponent: VisualInstruction.Component = instructions[0]
        simulateDownloadingShieldForComponent(firstDestinationComponent)

        //ensure that first callback fires
        wait(for: [firstExpectation], timeout: 1)

        //change the callback to track the second shield component
        view.primaryLabel.imageDownloadCompletion = secondExpectation.fulfill
        
        let secondDestinationComponent = instructions[2]
        simulateDownloadingShieldForComponent(secondDestinationComponent)

        //ensure that second callback fires
        wait(for: [secondExpectation], timeout: 1)
        
        //Slash should no longer be present
        XCTAssertNil(view.primaryLabel.text!.firstIndex(of: "/"), "Expected instruction text not to contain a slash: \(view.primaryLabel.text!)")
    }
    
    func testGenericRouteShieldInstructionsArePresentedProperly() {
        let view = instructionsView()
        let instruction = makeVisualInstruction(primaryInstruction: genericInstructions, secondaryInstruction: nil)
        //set the instruction, triggering the generic shield generation
        view.update(for: instruction)
        
        guard let attributed = view.primaryLabel.attributedText else { return XCTFail("No attributed string") }
        let stringRange = NSRange(location: 0, length: attributed.length)
        let foundAttachment = XCTestExpectation(description: "Attachment found")
        attributed.enumerateAttribute(.attachment, in: stringRange, options: []) { (value, range, stop) in
            guard let attachment = value else { return }
            foundAttachment.fulfill()
            XCTAssert(range == NSRange(location: 0, length: 1), "Unexpected Range:" + String(describing: range))
            XCTAssert(type(of: attachment) == GenericShieldAttachment.self, "Unexpected Attachment type:" + String(describing: attachment))
        }
        wait(for: [foundAttachment], timeout: 0)
    }
    
    func testRouteShieldsAreGenericUntilTheyLoad() {
        let view = instructionsView()
        
        let firstExpectation = XCTestExpectation(description: "First Component Callback")
        let secondExpectation = XCTestExpectation(description: "Second Component Callback")
        let firstRunHasAttachments = XCTestExpectation(description: "First Run - Ensuring attachments exist")
        let firstGeneric = XCTestExpectation(description: "First Run - First Instruction Generic")
        let secondGeneric = XCTestExpectation(description: "First Run - Second Instruction Generic")
        let secondRunHasAttachments = XCTestExpectation(description: "Second Run - Ensuring attachments exist")
        let firstNowLoaded = XCTestExpectation(description: "Second Run - First Should now be loaded")
        let secondStillGeneric = XCTestExpectation(description: "Second Run - Second should still be generic ")
        let thirdRunHasAttachments = XCTestExpectation(description: "Third Run - Ensuring attachments exist")
        let firstStillLoaded = XCTestExpectation(description: "Third Run - First should still be loaded")
        let secondNowLoaded = XCTestExpectation(description: "Third Run - Second should now be loaded")
        
        view.primaryLabel.imageDownloadCompletion = firstExpectation.fulfill
        
        view.secondaryLabel.imageDownloadCompletion = {
            XCTFail("ImageDownloadCompletion should not have been called on the secondary label.")
        }
        
        //set visual instructions on the view, which triggers the instruction image fetch
        view.update(for: makeVisualInstruction(primaryInstruction: instructions, secondaryInstruction: nil))
        
        let firstAttachmentRange = NSRange(location: 0, length: 1)
        let secondAttachmentRange = NSRange(location: 4, length: 1)
        
        //instructions should contain generic shields
        
        let firstStringRange = NSRange(location: 0, length: view.primaryLabel.attributedText!.length)
        view.primaryLabel.attributedText!.enumerateAttribute(.attachment,
                                                             in: firstStringRange, options: [],
                                                             using: { (value, range, stop) in
            guard let attachment = value else { return }
            firstRunHasAttachments.fulfill()
            
            if attachment is GenericShieldAttachment {
                if range == firstAttachmentRange {
                    return firstGeneric.fulfill()
                } else if range == secondAttachmentRange {
                    return secondGeneric.fulfill()
                }
            }
            XCTFail("First run: Unexpected attachment encountered at:" + String(describing: range) + " value: " + String(describing: value))
        })
        
        //simulate the downloads
        let firstDestinationComponent: VisualInstruction.Component = instructions[0]
        simulateDownloadingShieldForComponent(firstDestinationComponent)
        
        //ensure that first callback fires
        wait(for: [firstExpectation], timeout: 1)
        
        //This range has to be recomputed because the string changes on download
        let secondStringRange = NSRange(location: 0, length: view.primaryLabel.attributedText!.length)
        
        //check that the first component is now loaded
        view.primaryLabel.attributedText!.enumerateAttribute(.attachment, in: secondStringRange,
                                                             options: [], using: { (value, range, stop) in
            guard let attachment = value else { return }
            secondRunHasAttachments.fulfill()
            
            if attachment is GenericShieldAttachment, range == secondAttachmentRange {
                return secondStillGeneric.fulfill()
            } else if attachment is ShieldAttachment, range == firstAttachmentRange {
                return firstNowLoaded.fulfill()
            }
            XCTFail("Second Run: Unexpected attachment encountered at:" + String(describing: range) + " value: " + String(describing: value))
        })
        
        //change the callback to track the second shield component
        view.primaryLabel.imageDownloadCompletion = secondExpectation.fulfill
        
        let secondDestinationComponent = instructions[2]
        simulateDownloadingShieldForComponent(secondDestinationComponent)
        
        //ensure that second callback fires
        wait(for: [secondExpectation], timeout: 1)
        
        //we recompute this again because the string once again changes
        let thirdStringRange = NSRange(location: 0, length: view.primaryLabel.attributedText!.length)
        let noDelimiterSecondAttachmentRange = NSRange(location: 2, length: 1)
        
        //check that all attachments are now loaded
        view.primaryLabel.attributedText!.enumerateAttribute(.attachment, in: thirdStringRange, options: [], using: { (value, range, stop) in
            guard let attachment = value else { return }
            thirdRunHasAttachments.fulfill()
            
            if attachment is GenericShieldAttachment {
                return XCTFail("No attachments should be generic at this point.")
            } else if attachment is ShieldAttachment, [firstAttachmentRange, noDelimiterSecondAttachmentRange].contains(range) {
                return range == firstAttachmentRange ? firstStillLoaded.fulfill() : secondNowLoaded.fulfill()
            }
            XCTFail("Third run: Unexpected attachment encountered at:" + String(describing: range) + " value: " + String(describing: value))
        })
        
        //make sure everything happened as expected
        let expectations = [firstRunHasAttachments, firstGeneric, secondGeneric,
                            secondRunHasAttachments, firstNowLoaded, secondStillGeneric,
                            thirdRunHasAttachments, firstStillLoaded, secondNowLoaded]
        wait(for: expectations, timeout: 0)
    }
    
    func testExitBannerIntegration() {
        let exitAttribute = VisualInstruction.Component.exit(text: .init(text: "Exit", abbreviation: nil, abbreviationPriority: 0))
        let exitCodeAttribute = VisualInstruction.Component.exitCode(text: .init(text: "123A", abbreviation: nil, abbreviationPriority: 0))
        let mainStreetString = VisualInstruction.Component.text(text: .init(text: "Main Street", abbreviation: "Main St", abbreviationPriority: 0))
        let exitInstruction = VisualInstruction(text: nil, maneuverType: .takeOffRamp, maneuverDirection: .right, components: [exitAttribute, exitCodeAttribute, mainStreetString])
        
        let label = InstructionLabel(frame: CGRect(origin: .zero, size:CGSize(width: 375, height: 100)))
        
        label.availableBounds = { return label.frame }
        
        let traitCollection = UITraitCollection(userInterfaceIdiom: .phone)
        
        let presenter = InstructionPresenter(exitInstruction,
                                             dataSource: label,
                                             spriteRepository: spriteRepository,
                                             traitCollection: traitCollection,
                                             downloadCompletion: nil)
        
        let attributed = presenter.attributedText()
        
        let cacheKey = [
            exitCodeAttribute.cacheKey!,
            ExitView.criticalHash(side: .right,
                                  styleID: spriteRepository.styleID(for: .phone),
                                  dataSource: label,
                                  traitCollection: traitCollection)
        ].joined(separator: "-")
        XCTAssertNotNil(spriteRepository.derivedCache.image(forKey: cacheKey), "Expected cached image")
        
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

    private func simulateDownloadingShieldForComponent(_ component: VisualInstruction.Component) {
        guard case let VisualInstruction.Component.image(image: imageRepresentation, alternativeText: _) = component,
              let imageURL = imageRepresentation.imageURL(scale: VisualInstruction.Component.scale, format: .png)  else { return }
        let operation: ImageDownloadOperationSpy = ImageDownloadOperationSpy.operationForURL(imageURL)!
        let data = ShieldImage.i280.image.pngData()!
        let response = URLResponse(url: imageURL, mimeType: nil, expectedContentLength: data.count, textEncodingName: nil)
        operation.fireAllCompletions(CachedURLResponse(response: response, data: data), error: nil)

        XCTAssertNotNil(spriteRepository.getLegacyShield(with: imageRepresentation))
    }
}

private class TextReversingDelegate: InstructionsBannerViewDelegate {
    func label(_ label: InstructionLabel, willPresent instruction: VisualInstruction, as presented: NSAttributedString) -> NSAttributedString? {
        let forwards = Array(presented.string)
        let reverse = String(forwards.reversed())
        var range = NSRange(location: 0, length: presented.string.count)
        let attributes = presented.attributes(at: 0, effectiveRange: &range)
        return NSAttributedString(string: reverse, attributes: attributes)
    }
}

private class DefaultBehaviorDelegate: InstructionsBannerViewDelegate {
    func label(_ label: InstructionLabel, willPresent instruction: VisualInstruction, as presented: NSAttributedString) -> NSAttributedString? {
        return nil
    }
}
