import XCTest
import MapboxDirections
import MapboxMaps
@testable import TestHelper
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class SpriteRepositoryTests: TestCase {
    lazy var repository: SpriteRepository = {
        let repo = SpriteRepository()
        let config = URLSessionConfiguration.default
        config.protocolClasses = [ImageLoadingURLProtocolSpy.self]
        repo.sessionConfiguration = config
        return repo
    }()
    
    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false

        ImageLoadingURLProtocolSpy.reset()
        repository.resetCache()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func testDownLoadingSpriteInfo() {
        let fakeURL = URL(string: "http://an.image.url/spriteInfo.json")!
        ImageLoadingURLProtocolSpy.registerData(Fixture.JSONFromFileNamed(name: "sprite-info"), forURL: fakeURL)
        
        guard let styleID = repository.styleURI.rawValue.components(separatedBy: "styles")[safe: 1] else {
            XCTFail("Failed to generate spriteKey.")
            return
        }
        
        let dataKey = "us-interstate-3" + "-\(styleID)"
        XCTAssertNil(repository.infoCache.spriteInfo(forKey:dataKey))
        
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
        
        guard let styleID = repository.styleURI.rawValue.components(separatedBy: "styles")[safe: 1] else {
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
        repository.storeLegacy(image: .i280)
        let representation = VisualInstruction.Component.ImageRepresentation(imageBaseURL: ShieldImage.i280.baseURL)
        let semaphore = DispatchSemaphore(value: 0)
        var legacyShield: UIImage?
        
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
        guard let styleID = repository.styleURI.rawValue.components(separatedBy: "styles")[safe: 1],
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
        repository.storeSpriteData(styleType: .day)
        repository.storeLegacy(image: .i280)
        guard let styleID = repository.styleURI.rawValue.components(separatedBy: "styles")[safe: 1] else {
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
        repository.updateRepresentation(for: representation) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
        
        let spriteInfo = repository.infoCache.spriteInfo(forKey: dataKey)
        let expectedInfo = SpriteInfo(width: 156, height: 132, x: 0, y: 0, pixelRatio: 2, placeholder: [0,8,52,20], visible: true)
        XCTAssertEqual(spriteInfo, expectedInfo, "Failed to update the Sprite Info.")
        
        let sprite = repository.getSpriteImage()
        XCTAssertNotNil(sprite)
        XCTAssertTrue((sprite?.isKind(of: UIImage.self))!, "Failed to update the Sprite.")
        
        let legacyShield = repository.getLegacyShield(with: cacheKey)
        XCTAssertNotNil(legacyShield)
        XCTAssertTrue((legacyShield?.isKind(of: UIImage.self))!, "Failed to download the legacy shield.")
        
        let shieldIcon = repository.getShieldIcon(shield: shield)
        XCTAssertNotNil(shieldIcon)
        XCTAssertTrue((shieldIcon?.isKind(of: UIImage.self))!, "Failed to cut the shield icon.")
    }
    
    func testUpdateStyle() {
        let styleURI = StyleURI.navigationNight
        
        let expectation = expectation(description: "Style updated.")
        repository.updateStyle(styleURI: styleURI) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
        
        XCTAssertEqual(styleURI, repository.styleURI, "Failed to update the styleURI.")
    }
    
    func testPartiallySpriteUpdate() {
        repository.storeSpriteData(styleType: .day)
        repository.storeLegacy(image: .i280)
        guard let styleID = repository.styleURI.rawValue.components(separatedBy: "styles")[safe: 1] else {
            XCTFail("Failed to form request to update SpriteRepository.")
            return
        }
        
        // Update representation of the repository and fully downloaded Sprite image and metadata.
        let representation = VisualInstruction.Component.ImageRepresentation(imageBaseURL: ShieldImage.i280.baseURL)
        var dataKey = "us-interstate-3" + "-\(styleID)"
        
        var downloadExpectation = expectation(description: "Representation updated.")
        repository.updateRepresentation(for: representation) {
            downloadExpectation.fulfill()
        }
        wait(for: [downloadExpectation], timeout: 3.0)
        var spriteInfo = repository.infoCache.spriteInfo(forKey: dataKey)
        let expectedInfo = SpriteInfo(width: 156, height: 132, x: 0, y: 0, pixelRatio: 2, placeholder: [0,8,52,20], visible: true)
        XCTAssertEqual(spriteInfo, expectedInfo, "Failed to update the Sprite Info.")
        
        // Partially update style of the repository after the representation update.
        let newStyleURI = StyleURI.navigationNight
        repository.styleURI = newStyleURI
        guard let newStyleID = newStyleURI.rawValue.components(separatedBy: "styles")[safe: 1],
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

extension SpriteRepository {
    func storeSpriteData(styleType: StyleType) {
        let styleID = (styleType == .day) ? "/mapbox/navigation-day-v1" : "/mapbox/navigation-night-v1"
        let shieldImage = (styleType == .day) ? ShieldImage.shieldDay : ShieldImage.shieldNight
        guard let shieldData = shieldImage.image.pngData(),
              let spriteRequestURL = spriteURL(isImage: true, styleID: styleID),
              let metadataRequestURL = spriteURL(isImage: false, styleID: styleID) else {
                  XCTFail("Failed to update SpriteRepository.")
                  return
              }
        ImageLoadingURLProtocolSpy.registerData(shieldData, forURL: spriteRequestURL)
        ImageLoadingURLProtocolSpy.registerData(Fixture.JSONFromFileNamed(name: "sprite-info"), forURL: metadataRequestURL)
    }
    
    func storeLegacy(image: ShieldImage) {
        let scale = Int(VisualInstruction.Component.scale)
        guard let legacyShieldData = image.image.pngData(),
              let imageBaseURL = URL(string: image.baseURL.absoluteString + "@\(scale)x.png") else {
            XCTFail("No data or URL found for legacy image.")
            return
        }
        ImageLoadingURLProtocolSpy.registerData(legacyShieldData, forURL: imageBaseURL)
    }
}
