import XCTest
import TestHelper
@testable import MapboxNavigation

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
        
        repository.downLoadSprite(fakeURL) { (image) in
            sprite = image
            semaphore.signal()
        }

        let semaphoreResult = semaphore.wait(timeout: XCTestCase.NavigationTests.timeout)
        XCTAssert(semaphoreResult == .success, "Semaphore timed out")
        
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
        XCTAssert(semaphoreResult == .success, "Semaphore timed out")
        
        XCTAssertNotNil(shield)
        XCTAssertTrue((shield?.isKind(of: UIImage.self))!)
    }
    
    func testDownLoadingSpriteMetaData() {
        let fakeURL = URL(string: "http://an.image.url/spriteMetaData.json")!
        ImageLoadingURLProtocolSpy.registerData(Fixture.JSONFromFileNamed(name: "sprite-metadata"), forURL: fakeURL)
        
        let dataKey = "default-3"
        XCTAssertNil(repository.metadataCache.spriteMetaData(forKey:dataKey))
        
        let semaphore = DispatchSemaphore(value: 0)
        var requestedData: Data?
        repository.downloadMetadata(fakeURL) { (data) in
            requestedData = data
            semaphore.signal()
        }

        let semaphoreResult = semaphore.wait(timeout: XCTestCase.NavigationTests.timeout)
        XCTAssert(semaphoreResult == .success, "Semaphore timed out")

        guard let data = requestedData else {
            XCTFail("Failed to download sprite metadata.")
            return
        }
        
        repository.metadataCache.store(data)
        let expectedMetaData = SpriteMetaData(width: 156, height: 84, x: 1710, y: 1992, pixelRatio: 2, placeholder: [0,8,52,20], visible: true)
        let spriteMetaData = repository.metadataCache.spriteMetaData(forKey: dataKey)
        XCTAssertEqual(expectedMetaData, spriteMetaData, "Failed to retrieve metadata from cache.")
    }

}
