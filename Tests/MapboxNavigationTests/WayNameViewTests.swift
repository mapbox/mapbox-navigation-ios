import XCTest
import MapboxDirections
import TestHelper
import MapboxMaps
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class WayNameViewTests: TestCase {
    var wayNameView: WayNameView!
    var imageDownloader: ReentrantImageDownloaderSpy!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        wayNameView = .forAutoLayout()
        wayNameView.containerView.isHidden = true
        wayNameView.containerView.clipsToBounds = true
        
        imageDownloader = ReentrantImageDownloaderSpy()
        wayNameView.label.spriteRepository = SpriteRepository(imageDownloader: imageDownloader,
                                                              requestCache: URLCacheSpy(),
                                                              derivedCache: BimodalImageCacheSpy())
    }

    override func tearDown() {
        super.tearDown()

        wayNameView.label.representation = nil
    }
    
    func storeData(style: StyleType) {
        let scale = Int(VisualInstruction.Component.scale)
        let styleID = (style == .day) ? "/mapbox/navigation-day-v1" : "/mapbox/navigation-night-v1"
        let spriteImage = (style == .day) ? ShieldImage.shieldDay.image : ShieldImage.shieldNight.image
        guard let spriteRequestURL = wayNameView.label.spriteRepository.spriteURL(isImage: true, styleID: styleID),
              let infoRequestURL = wayNameView.label.spriteRepository.spriteURL(isImage: false, styleID: styleID),
              let legacyRequestURL = URL(string: ShieldImage.i280.baseURL.absoluteString + "@\(scale)x.png") else {
                  XCTFail("Failed to form request URL.")
                  return
              }
        imageDownloader.returnedDownloadResults[spriteRequestURL] = spriteImage.pngData()
        imageDownloader.returnedDownloadResults[legacyRequestURL] = ShieldImage.i280.image.pngData()
        imageDownloader.returnedDownloadResults[infoRequestURL] = Fixture.JSONFromFileNamed(name: "sprite-info")
    }
    
    func testUpdateStyle() {
        let baseURL = wayNameView.label.spriteRepository.baseURL
        storeData(style: .night)
        
        let shield = VisualInstruction.Component.ShieldRepresentation(baseURL: baseURL, name: "us-interstate", textColor: "white", text: "280")
        let representation = VisualInstruction.Component.ImageRepresentation(imageBaseURL: ShieldImage.i280.baseURL, shield: shield)
        let roadName = "I 280 North"

        wayNameView.label.text = roadName
        wayNameView.label.representation = representation
        
        let styleURI = StyleURI.navigationNight
        wayNameView.label.updateStyle(styleURI: styleURI)
        
        expectation(description: "Label text updated with shield image presented.") {
            self.wayNameView.label.text != roadName
        }
        waitForExpectations(timeout: 3, handler: nil)
        
        let defaultStyleURI = wayNameView.label.spriteRepository.userInterfaceIdiomStyles[.phone]
        XCTAssertEqual(defaultStyleURI, styleURI, "Failed to update the styleURI of Sprite Repository.")
        
        guard let attributedText = wayNameView.label.attributedText else {
            XCTFail("Failed to update the label attributed string.")
            return
        }
        XCTAssertTrue(attributedText.containsAttachments(in: NSRange(location: 0, length: 1)), "Failed to update the shield images when update style.")
    }
    
    func testUpdateRoad() {
        let baseURL = wayNameView.label.spriteRepository.baseURL
        storeData(style: .day)
        
        var roadName = "I 280 North"
        let shield = VisualInstruction.Component.ShieldRepresentation(baseURL: baseURL, name: "us-interstate", textColor: "white", text: "280")
        let representation = VisualInstruction.Component.ImageRepresentation(imageBaseURL: ShieldImage.i280.baseURL, shield: shield)
        
        wayNameView.label.updateRoad(roadName: roadName, representation: representation)
        expectation(description: "Road label updated.") {
            self.wayNameView.label.text != nil
        }
        waitForExpectations(timeout: 3, handler: nil)
        
        XCTAssertEqual(wayNameView.label.representation, representation, "Failed to update the imageRepresentation of WayNameView label.")
        
        guard let attributedText = wayNameView.label.attributedText else {
            XCTFail("Failed to update the label attributed string.")
            return
        }
        XCTAssertTrue(attributedText.containsAttachments(in: NSRange(location: 0, length: 1)), "Failed to update the shield images when update style.")
        
        roadName = "101"
        wayNameView.label.updateRoad(roadName: roadName, representation: nil)
        expectation(description: "Road label updated with the new imageRepresentation.") {
            self.wayNameView.label.representation == nil
        }
        waitForExpectations(timeout: 3, handler: nil)
    
        XCTAssertEqual(wayNameView.label.text, roadName, "Failed to set up the WayNameView label with road name text only.")
    }
}
