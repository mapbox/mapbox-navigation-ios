import XCTest
import MapboxDirections
import MapboxMaps
@testable import TestHelper
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class SpriteRepositoryTests: TestCase {
    var repository: SpriteRepository!
    
    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
        generateRepository()
    }

    override func tearDown() {
        super.tearDown()
        ImageLoadingURLProtocolSpy.reset()
        repository = nil
    }
    
    func generateRepository() {
        repository = SpriteRepository()
        let config = URLSessionConfiguration.default
        config.protocolClasses = [ImageLoadingURLProtocolSpy.self]
        repository.sessionConfiguration = config
    }
    
    func storeData() {
        let scale = Int(VisualInstruction.Component.scale)
        guard let styleID = repository.styleID,
              let spriteRequestURL = repository.spriteURL(isImage: true, styleID: styleID),
              let infoRequestURL = repository.spriteURL(isImage: false, styleID: styleID),
              let legacyRequestURL = URL(string: ShieldImage.i280.baseURL.absoluteString + "@\(scale)x.png") else {
                  XCTFail("Failed to form request URL.")
                  return
              }
        ImageLoadingURLProtocolSpy.registerData(ShieldImage.shieldDay.image.pngData()!, forURL: spriteRequestURL)
        ImageLoadingURLProtocolSpy.registerData(Fixture.JSONFromFileNamed(name: "sprite-info"), forURL: infoRequestURL)
        ImageLoadingURLProtocolSpy.registerData(ShieldImage.i280.image.pngData()!, forURL: legacyRequestURL)
    }
    
    func testDownLoadingSpriteInfo() {
        let fakeURL = URL(string: "http://an.image.url/spriteInfo.json")!
        ImageLoadingURLProtocolSpy.registerData(Fixture.JSONFromFileNamed(name: "sprite-info"), forURL: fakeURL)
        
        guard let styleID = repository.styleID else {
            XCTFail("Failed to generate spriteKey.")
            return
        }
        
        let dataKey = "us-interstate-3" + "-\(styleID)"
        XCTAssertNil(repository.infoCache.spriteInfo(forKey: dataKey))
        
        let semaphore = DispatchSemaphore(value: 0)
        var requestedData: Data?
        repository.downloadInfo(fakeURL, spriteKey: styleID) { (data) in
            requestedData = data
            semaphore.signal()
        }

        let semaphoreResult = semaphore.wait(timeout: XCTestCase.NavigationTests.timeout)
        XCTAssert(semaphoreResult == .success, "Semaphore timed out.")

        guard let data = requestedData else {
            XCTFail("Failed to download Sprite Info.")
            return
        }
        
        repository.infoCache.store(data, spriteKey: styleID)
        let expectedInfo = SpriteInfo(width: 156, height: 132, x: 0, y: 0, pixelRatio: 2, placeholder: [0,8,52,20], visible: true)
        let spriteInfo = repository.infoCache.spriteInfo(forKey: dataKey)
        XCTAssertEqual(expectedInfo, spriteInfo, "Failed to retrieve Sprite info from cache.")
    }
    
    func testDownLoadingSprite() {
        let fakeURL = URL(string: "http://an.image.url/sprite.png")!
        ImageLoadingURLProtocolSpy.registerData(ShieldImage.i280.image.pngData()!, forURL: fakeURL)
        XCTAssertNil(repository.getSpriteImage())
        
        guard let styleID = repository.styleID else {
            XCTFail("Failed to generate spriteKey.")
            return
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        var sprite: UIImage?
        
        repository.downloadSprite(fakeURL, spriteKey: styleID) { (image) in
            sprite = image
            semaphore.signal()
        }

        let semaphoreResult = semaphore.wait(timeout: XCTestCase.NavigationTests.timeout)
        XCTAssert(semaphoreResult == .success, "Semaphore timed out.")
        
        XCTAssertNotNil(sprite)
        XCTAssertTrue((sprite?.isKind(of: UIImage.self))!)
    }
    
    func testDownLoadingLegacyShield() {
        let fakeBaseURL = "http://an.image.url/legacyShield"
        let scale = Int(VisualInstruction.Component.scale)
        ImageLoadingURLProtocolSpy.registerData(ShieldImage.i280.image.pngData()!, forURL: URL(string: fakeBaseURL + "@\(scale)x.png")!)
        
        let semaphore = DispatchSemaphore(value: 0)
        var legacyShield: UIImage?
        
        let representation = VisualInstruction.Component.ImageRepresentation(imageBaseURL: URL(string: fakeBaseURL))
        
        repository.downloadLegacyShield(representation: representation) { (image) in
            legacyShield = image
            semaphore.signal()
        }

        let semaphoreResult = semaphore.wait(timeout: XCTestCase.NavigationTests.timeout)
        XCTAssert(semaphoreResult == .success, "Semaphore timed out.")
        
        XCTAssertNotNil(legacyShield)
        XCTAssertTrue((legacyShield?.isKind(of: UIImage.self))!)
    }
    
    func testGeneratingSpriteURL() {
        guard let styleID = repository.styleID,
              let accessToken = NavigationSettings.shared.directions.credentials.accessToken else {
            XCTFail("Failed to form request URL from SpriteRepository.")
            return
        }
        
        let scale = Int(VisualInstruction.Component.scale)
        let baseURLstring = repository.baseURL.absoluteString
        let spriteRequestURL = URL(string: baseURLstring + styleID + "/sprite@\(scale)x.png?access_token=" + accessToken)
        let infoRequestURL = URL(string: baseURLstring + styleID + "/sprite@\(scale)x?access_token=" + accessToken)
        
        let expetecSpriteRequestURL = repository.spriteURL(isImage: true, styleID: styleID)
        let expectedInfoRequestURL = repository.spriteURL(isImage: false, styleID: styleID)
        XCTAssertEqual(spriteRequestURL, expetecSpriteRequestURL, "Failed to generate Sprite request URL from SpriteRepository.")
        XCTAssertEqual(infoRequestURL, expectedInfoRequestURL, "Failed to generate Sprite info request URL from SpriteRepository.")
    }
    
    func testUpdateRepresentation() {
        storeData()
        guard let styleID = repository.styleID else {
            XCTFail("Failed to form request to update SpriteRepository.")
            return
        }
        
        let shield = VisualInstruction.Component.ShieldRepresentation(baseURL: repository.baseURL, name: "us-interstate", textColor: "white", text: "280")
        let representation = VisualInstruction.Component.ImageRepresentation(imageBaseURL: ShieldImage.i280.baseURL, shield: shield)
        let cacheKey = representation.legacyCacheKey
        let dataKey = "us-interstate-3" + "-\(styleID)"
        
        XCTAssertNil(repository.infoCache.spriteInfo(forKey:dataKey))
        XCTAssertNil(repository.getSpriteImage())
        XCTAssertNil(repository.legacyCache.image(forKey: cacheKey))
        
        let expectation = expectation(description: "Image Downloaded.")
        repository.updateRepresentation(for: representation) { _ in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
        
        let spriteInfo = repository.infoCache.spriteInfo(forKey: dataKey)
        let expectedInfo = SpriteInfo(width: 156, height: 132, x: 0, y: 0, pixelRatio: 2, placeholder: [0,8,52,20], visible: true)
        XCTAssertEqual(spriteInfo, expectedInfo, "Failed to update the Sprite Info.")
        
        let sprite = repository.getSpriteImage()
        XCTAssertNotNil(sprite)
        XCTAssertTrue((sprite?.isKind(of: UIImage.self))!, "Failed to update the Sprite.")
        
        let legacyShield = repository.legacyRoadShieldImage(from: cacheKey)
        XCTAssertNotNil(legacyShield)
        XCTAssertTrue((legacyShield?.isKind(of: UIImage.self))!, "Failed to download the legacy shield.")
        
        let shieldIcon = repository.roadShieldImage(from: shield)
        XCTAssertNotNil(shieldIcon)
        XCTAssertTrue((shieldIcon?.isKind(of: UIImage.self))!, "Failed to cut the shield icon.")
    }
    
    func testUpdateStyle() {
        let styleURI = StyleURI.navigationNight
        
        let expectation = expectation(description: "Style updated.")
        repository.updateStyle(styleURI: styleURI) { _ in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
        
        XCTAssertEqual(styleURI, repository.styleURI, "Failed to update the styleURI.")
    }
    
    func testPartiallySpriteUpdate() {
        storeData()
        guard let styleID = repository.styleID else {
            XCTFail("Failed to form request to update SpriteRepository.")
            return
        }
        
        // Update representation of the repository and fully downloaded Sprite image and metadata.
        let representation = VisualInstruction.Component.ImageRepresentation(imageBaseURL: ShieldImage.i280.baseURL)
        var dataKey = "us-interstate-3" + "-\(styleID)"
        
        var downloadExpectation = expectation(description: "Representation updated.")
        repository.updateRepresentation(for: representation) { _ in
            downloadExpectation.fulfill()
        }
        wait(for: [downloadExpectation], timeout: 3.0)
        var spriteInfo = repository.infoCache.spriteInfo(forKey: dataKey)
        let expectedInfo = SpriteInfo(width: 156, height: 132, x: 0, y: 0, pixelRatio: 2, placeholder: [0,8,52,20], visible: true)
        XCTAssertEqual(spriteInfo, expectedInfo, "Failed to update the Sprite Info.")
        
        // Partially update style of the repository after the representation update.
        let newStyleURI = StyleURI.navigationNight
        repository.styleURI = newStyleURI
        guard let newStyleID = repository.styleID,
              let infoRequestURL = repository.spriteURL(isImage: false, styleID: newStyleID) else {
                  XCTFail("Failed to form request to update SpriteRepository.")
                  return
        }
        ImageLoadingURLProtocolSpy.registerData(Fixture.JSONFromFileNamed(name: "sprite-info"), forURL: infoRequestURL)
        
        // Downloaded Sprite metadata without Sprite image to test the shield icon retrieval under poor network condition.
        downloadExpectation = expectation(description: "Sprite info updated.")
        repository.downloadInfo(infoRequestURL, spriteKey: newStyleID) { (_) in
            downloadExpectation.fulfill()
        }
        wait(for: [downloadExpectation], timeout: 3.0)
        
        // The Sprite info should be ready for current Sprite repository without matched Sprite image.
        dataKey = "us-interstate-3" + "-\(newStyleID)"
        spriteInfo = repository.infoCache.spriteInfo(forKey: dataKey)
        XCTAssertEqual(spriteInfo, expectedInfo, "Failed to update the Sprite Info.")
        XCTAssertNil(repository.getSpriteImage(), "Failed to match the Sprite image with the spriteKey.")
    }

}
