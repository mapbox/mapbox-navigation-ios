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
    
    func storeData(styleURI: StyleURI, baseURL: URL, imageBaseURL: String) {
        let scale = Int(VisualInstruction.Component.scale)
        
        guard let styleID = styleURI.rawValue.components(separatedBy: "styles")[safe: 1],
              let spriteRequestURL = repository.spriteURL(isImage: true, baseURL: baseURL, styleID: styleID),
              let infoRequestURL = repository.spriteURL(isImage: false, baseURL: baseURL, styleID: styleID) else {
                  XCTFail("Failed to form request to update SpriteRepository.")
                  return
              }
        
        ImageLoadingURLProtocolSpy.registerData(ShieldImage.i280.image.pngData()!, forURL: spriteRequestURL)
        ImageLoadingURLProtocolSpy.registerData(Fixture.JSONFromFileNamed(name: "sprite-info"), forURL: infoRequestURL)
        ImageLoadingURLProtocolSpy.registerData(ShieldImage.i280.image.pngData()!, forURL: URL(string: imageBaseURL + "@\(scale)x.png")!)
    }
    
    func testDownLoadingSpriteInfo() {
        let fakeURL = URL(string: "http://an.image.url/spriteInfo.json")!
        ImageLoadingURLProtocolSpy.registerData(Fixture.JSONFromFileNamed(name: "sprite-info"), forURL: fakeURL)
        
        guard let styleID = repository.styleURI.rawValue.components(separatedBy: "styles")[safe: 1] else {
            XCTFail("Failed to generate spriteKey.")
            return
        }
        let spriteKey = "\(styleID)-\(repository.baseURL.absoluteString)"
        
        let dataKey = "default-3" + "-\(spriteKey)"
        XCTAssertNil(repository.infoCache.spriteInfo(forKey:dataKey))
        
        let semaphore = DispatchSemaphore(value: 0)
        var requestedData: Data?
        repository.downloadInfo(fakeURL, spriteKey: spriteKey) { (data) in
            requestedData = data
            semaphore.signal()
        }

        let semaphoreResult = semaphore.wait(timeout: XCTestCase.NavigationTests.timeout)
        XCTAssert(semaphoreResult == .success, "Semaphore timed out.")

        guard let data = requestedData else {
            XCTFail("Failed to download Sprite Info.")
            return
        }
        
        repository.infoCache.store(data, spriteKey: spriteKey)
        let expectedInfo = SpriteInfo(width: 156, height: 84, x: 1710, y: 1992, pixelRatio: 2, placeholder: [0,8,52,20], visible: true)
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
        let spriteKey = "\(styleID)-\(repository.baseURL.absoluteString)"
        
        let semaphore = DispatchSemaphore(value: 0)
        var sprite: UIImage?
        
        repository.downloadSprite(fakeURL, spriteKey: spriteKey) { (image) in
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
        guard let styleID = repository.styleURI.rawValue.components(separatedBy: "styles")[safe: 1],
              let accessToken = NavigationSettings.shared.directions.credentials.accessToken else {
            XCTFail("Failed to form request URL from SpriteRepository.")
            return
        }
        
        let scale = Int(VisualInstruction.Component.scale)
        let baseURLstring = repository.baseURL.absoluteString
        let spriteRequestURL = URL(string: baseURLstring + styleID + "/sprite@\(scale)x.png?access_token=" + accessToken)
        let infoRequestURL = URL(string: baseURLstring + styleID + "/sprite@\(scale)x?access_token=" + accessToken)
        
        let expetecSpriteRequestURL = repository.spriteURL(isImage: true, baseURL: repository.baseURL, styleID: styleID)
        let expectedInfoRequestURL = repository.spriteURL(isImage: false, baseURL: repository.baseURL, styleID: styleID)
        XCTAssertEqual(spriteRequestURL, expetecSpriteRequestURL, "Failed to generate Sprite request URL from SpriteRepository.")
        XCTAssertEqual(infoRequestURL, expectedInfoRequestURL, "Failed to generate Sprite info request URL from SpriteRepository.")
    }
    
    func testUpdateRepresentation() {
        let imageBaseURL = "http://an.image.url/legacyShield"
        storeData(styleURI: repository.styleURI, baseURL: repository.baseURL, imageBaseURL: imageBaseURL)
        guard let styleID = repository.styleURI.rawValue.components(separatedBy: "styles")[safe: 1] else {
            XCTFail("Failed to form request to update SpriteRepository.")
            return
        }
        
        let representation = VisualInstruction.Component.ImageRepresentation(imageBaseURL: URL(string: imageBaseURL)!)
        let cacheKey = representation.legacyCacheKey
        let spriteKey = "\(styleID)-\(repository.baseURL.absoluteString)"
        let dataKey = "default-3" + "-\(spriteKey)"
        
        XCTAssertNil(repository.infoCache.spriteInfo(forKey:dataKey))
        XCTAssertNil(repository.getSpriteImage())
        XCTAssertNil(repository.legacyCache.image(forKey: cacheKey))
        
        let expectation = expectation(description: "Image Downloaded.")
        repository.updateRepresentation(for: representation) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
        
        let spriteInfo = repository.infoCache.spriteInfo(forKey: dataKey)
        let expectedInfo = SpriteInfo(width: 156, height: 84, x: 1710, y: 1992, pixelRatio: 2, placeholder: [0,8,52,20], visible: true)
        XCTAssertEqual(spriteInfo, expectedInfo, "Failed to update the Sprite Info.")
        
        let sprite = repository.getSpriteImage()
        XCTAssertNotNil(sprite)
        XCTAssertTrue((sprite?.isKind(of: UIImage.self))!, "Failed to update the Sprite.")
        
        let legacyShield = repository.getLegacyShield(with: cacheKey)
        XCTAssertNotNil(legacyShield)
        XCTAssertTrue((legacyShield?.isKind(of: UIImage.self))!, "Failed to download the legacy shield.")
    }
    
    func testUpdateStyle() {
        let styleURI = StyleURI.navigationNight
        
        let expectation = expectation(description: "Style updated.")
        repository.updateRepresentationStyle(styleURI: styleURI) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
        
        XCTAssertEqual(styleURI, repository.styleURI, "Failed to update the styleURI.")
    }
    
    func testPartiallySpriteUpdate() {
        let imageBaseURL = "http://an.image.url/legacyShield"
        storeData(styleURI: repository.styleURI, baseURL: repository.baseURL, imageBaseURL: imageBaseURL)
        guard let styleID = repository.styleURI.rawValue.components(separatedBy: "styles")[safe: 1] else {
            XCTFail("Failed to form request to update SpriteRepository.")
            return
        }
        
        // Update representation of the repository and fully downloaded Sprite image and metadata.
        let representation = VisualInstruction.Component.ImageRepresentation(imageBaseURL: URL(string: imageBaseURL)!)
        var spriteKey = "\(styleID)-\(repository.baseURL.absoluteString)"
        var dataKey = "default-3" + "-\(spriteKey)"
        
        var downloadExpectation = expectation(description: "Representation updated.")
        repository.updateRepresentation(for: representation) {
            downloadExpectation.fulfill()
        }
        wait(for: [downloadExpectation], timeout: 3.0)
        var spriteInfo = repository.infoCache.spriteInfo(forKey: dataKey)
        var expectedInfo = SpriteInfo(width: 156, height: 84, x: 1710, y: 1992, pixelRatio: 2, placeholder: [0,8,52,20], visible: true)
        XCTAssertEqual(spriteInfo, expectedInfo, "Failed to update the Sprite Info.")
        
        // Partially update style of the repository after the representation update.
        let newStyleURI = StyleURI.navigationNight
        repository.styleURI = newStyleURI
        guard let newStyleID = newStyleURI.rawValue.components(separatedBy: "styles")[safe: 1],
              let infoRequestURL = repository.spriteURL(isImage: false, baseURL: repository.baseURL, styleID: newStyleID) else {
                  XCTFail("Failed to form request to update SpriteRepository.")
                  return
        }
        ImageLoadingURLProtocolSpy.registerData(Fixture.JSONFromFileNamed(name: "sprite-info"), forURL: infoRequestURL)
        
        // Downloaded Sprite metadata without Sprite image to test the shield icon retrieval under poor network condition.
        downloadExpectation = expectation(description: "Sprite info updated.")
        spriteKey = "\(newStyleID)-\(repository.baseURL.absoluteString)"
        repository.downloadInfo(infoRequestURL, spriteKey: spriteKey) { (_) in
            downloadExpectation.fulfill()
        }
        wait(for: [downloadExpectation], timeout: 3.0)
        
        // The Sprite info should be ready for current Sprite repository without matched Sprite image.
        dataKey = "default-3" + "-\(spriteKey)"
        spriteInfo = repository.infoCache.spriteInfo(forKey: dataKey)
        expectedInfo = SpriteInfo(width: 156, height: 84, x: 1710, y: 1992, pixelRatio: 2, placeholder: [0,8,52,20], visible: true)
        XCTAssertEqual(spriteInfo, expectedInfo, "Failed to update the Sprite Info.")
        XCTAssertNil(repository.getSpriteImage(), "Failed to match the Sprite image with the spriteKey.")
    }

}
