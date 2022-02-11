import XCTest
@testable import TestHelper
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class SpriteRepositoryTests: TestCase {
    lazy var repository: SpriteRepository = {
        let repo = SpriteRepository.shared
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
    
    func testDownLoadingSprite() {
        let fakeURL = URL(string: "http://an.image.url/sprite.png")!
        ImageLoadingURLProtocolSpy.registerData(ShieldImage.i280.image.pngData()!, forURL: fakeURL)
        XCTAssertNil(repository.imageCache.image(forKey: "Sprite"))
        
        let semaphore = DispatchSemaphore(value: 0)
        var sprite: UIImage?
        
        repository.downloadSprite(fakeURL) { (image) in
            sprite = image
            semaphore.signal()
        }

        let semaphoreResult = semaphore.wait(timeout: XCTestCase.NavigationTests.timeout)
        XCTAssert(semaphoreResult == .success, "Semaphore timed out.")
        
        XCTAssertNotNil(sprite)
        XCTAssertTrue((sprite?.isKind(of: UIImage.self))!)
    }
    
    func testGettingLegacyShield() {
        let fakeBaseURL = "http://an.image.url/legacyShield"
        ImageLoadingURLProtocolSpy.registerData(ShieldImage.i280.image.pngData()!, forURL: URL(string: fakeBaseURL + "@2x.png")!)
        
        let semaphore = DispatchSemaphore(value: 0)
        var shield: UIImage?
        
        repository.getLegacyShield(imageBaseUrl: fakeBaseURL) { (image) in
            shield = image
            semaphore.signal()
        }

        let semaphoreResult = semaphore.wait(timeout: XCTestCase.NavigationTests.timeout)
        XCTAssert(semaphoreResult == .success, "Semaphore timed out.")
        
        XCTAssertNotNil(shield)
        XCTAssertTrue((shield?.isKind(of: UIImage.self))!)
    }
    
    func testDownLoadingSpriteInfo() {
        let fakeURL = URL(string: "http://an.image.url/spriteInfo.json")!
        ImageLoadingURLProtocolSpy.registerData(Fixture.JSONFromFileNamed(name: "sprite-info"), forURL: fakeURL)
        
        let dataKey = "default-3"
        XCTAssertNil(repository.infoCache.spriteInfo(forKey:dataKey))
        
        let semaphore = DispatchSemaphore(value: 0)
        var requestedData: Data?
        repository.downloadInfo(fakeURL) { (data) in
            requestedData = data
            semaphore.signal()
        }

        let semaphoreResult = semaphore.wait(timeout: XCTestCase.NavigationTests.timeout)
        XCTAssert(semaphoreResult == .success, "Semaphore timed out.")

        guard let data = requestedData else {
            XCTFail("Failed to download Sprite Info.")
            return
        }
        
        repository.infoCache.store(data)
        let expectedInfo = SpriteInfo(width: 156, height: 84, x: 1710, y: 1992, pixelRatio: 2, placeholder: [0,8,52,20], visible: true)
        let spriteInfo = repository.infoCache.spriteInfo(forKey: dataKey)
        XCTAssertEqual(expectedInfo, spriteInfo, "Failed to retrieve Sprite info from cache.")
    }
    
    func testGeneratingSpriteURL() {
        guard let styleID = repository.styleURI.rawValue.components(separatedBy: "styles")[safe: 1],
              let accessToken = NavigationSettings.shared.directions.credentials.accessToken else {
            XCTFail("Failed to form request URL from SpriteRepository.")
            return
        }
        
        let baseURLstring = repository.baseURL.absoluteString
        let spriteRequestURL = URL(string: baseURLstring + styleID + "/sprite@2x.png?access_token=" + accessToken)
        let infoRequestURL = URL(string: baseURLstring + styleID + "/sprite@2x?access_token=" + accessToken)
        
        let expetecSpriteRequestURL = repository.spriteURL(isImage: true, baseURL: repository.baseURL, styleID: styleID)
        let expectedInfoRequestURL = repository.spriteURL(isImage: false, baseURL: repository.baseURL, styleID: styleID)
        XCTAssertEqual(spriteRequestURL, expetecSpriteRequestURL, "Failed to generate Sprite request URL from SpriteRepository.")
        XCTAssertEqual(infoRequestURL, expectedInfoRequestURL, "Failed to generate Sprite info request URL from SpriteRepository.")
    }
    
    func testUpdateRepository() {
        guard let styleID = repository.styleURI.rawValue.components(separatedBy: "styles")[safe: 1],
              let spriteRequestURL = repository.spriteURL(isImage: true, baseURL: repository.baseURL, styleID: styleID),
              let infoRequestURL = repository.spriteURL(isImage: false, baseURL: repository.baseURL, styleID: styleID) else {
                  XCTFail("Failed to form request to update SpriteRepository.")
                  return
              }
        
        ImageLoadingURLProtocolSpy.registerData(ShieldImage.i280.image.pngData()!, forURL: spriteRequestURL)
        ImageLoadingURLProtocolSpy.registerData(Fixture.JSONFromFileNamed(name: "sprite-info"), forURL: infoRequestURL)
        
        let dataKey = "default-3"
        XCTAssertNil(repository.infoCache.spriteInfo(forKey:dataKey))
        XCTAssertNil(repository.imageCache.image(forKey:"Sprite"))

        let expectation = expectation(description: "Image Downloaded")
        repository.updateRepository() {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
        
        let sprite = repository.imageCache.image(forKey:"Sprite")
        XCTAssertNotNil(sprite)
        XCTAssertTrue((sprite?.isKind(of: UIImage.self))!, "Failed to update the Sprite.")
        
        let spriteInfo = repository.infoCache.spriteInfo(forKey: dataKey)
        let expectedInfo = SpriteInfo(width: 156, height: 84, x: 1710, y: 1992, pixelRatio: 2, placeholder: [0,8,52,20], visible: true)
        XCTAssertEqual(spriteInfo, expectedInfo, "Failed to update the Sprite Info.")
    }

}
