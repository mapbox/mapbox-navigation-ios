import XCTest
import MapboxDirections
import TestHelper
import MapboxMaps
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class WayNameViewTests: TestCase {
    lazy var wayNameView: WayNameView = {
        let view: WayNameView = .forAutoLayout()
        view.containerView.isHidden = true
        view.containerView.clipsToBounds = true
        
        let config = URLSessionConfiguration.default
        config.protocolClasses = [ImageLoadingURLProtocolSpy.self]
        view.label.spriteRepository = SpriteRepositoryStub.init()
        view.label.spriteRepository.sessionConfiguration = config
        return view
    }()
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        ImageLoadingURLProtocolSpy.reset()
        wayNameView.label.spriteRepository.resetCache()
        wayNameView.label.representation = nil
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func loadingURL(baseURL: URL, styleID: String) {
        guard let spriteRequestURL = wayNameView.label.spriteRepository.spriteURL(isImage: true, baseURL: baseURL, styleID: styleID),
              let metadataRequestURL = wayNameView.label.spriteRepository.spriteURL(isImage: false, baseURL: baseURL, styleID: styleID) else {
                  XCTFail("Failed to form request to update SpriteRepository.")
                  return
              }
        
        let scale = Int(VisualInstruction.Component.scale)
        guard let shieldData = ShieldImage.shield.image.pngData(),
              let scaleShieldImageURL = URL(string: ShieldImage.i280.baseURL.absoluteString + "@\(scale)x.png") else {
                  XCTFail("No data or URL found for shield image.")
                  return
              }
        
        ImageLoadingURLProtocolSpy.registerData(shieldData, forURL: spriteRequestURL)
        ImageLoadingURLProtocolSpy.registerData(Fixture.JSONFromFileNamed(name: "sprite-info"), forURL: metadataRequestURL)
        ImageLoadingURLProtocolSpy.registerData(shieldData, forURL: scaleShieldImageURL)
    }
    
    func testUpdateStyle() {
        let baseURL = wayNameView.label.spriteRepository.baseURL
        let styleID = "/mapbox/navigation-night-v1"
        loadingURL(baseURL: baseURL, styleID: styleID)
        
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
        
        XCTAssertEqual(wayNameView.label.spriteRepository.styleURI, styleURI, "Failed to update the styleURI of Sprite Repository.")
        
        guard let attributedText = wayNameView.label.attributedText else {
            XCTFail("Failed to update the label attributed string.")
            return
        }
        XCTAssertTrue(attributedText.containsAttachments(in: NSRange(location: 0, length: 1)), "Failed to update the shield images when update style.")
    }
    
    func testUpdateRoad() {
        let baseURL = wayNameView.label.spriteRepository.baseURL
        let styleID = "/mapbox/navigation-day-v1"
        loadingURL(baseURL: baseURL, styleID: styleID)
        
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

class SpriteRepositoryStub: SpriteRepository {    
    override func getShield(displayRef: String, name: String) -> UIImage? {
        return displayRef == "280" ? ShieldImage.shield.image : nil
    }
}
