import XCTest
@testable import MapboxNavigation


class ImageCacheTests: XCTestCase {

    let cache: ImageCache = ImageCache()

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false

        cache.clearMemory()
        let expectation = self.expectation(description: "Clearing Disk Cache")
        cache.clearDisk {
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 1)
    }

    override func tearDown() {

        super.tearDown()
    }

    func storeImageInMemory() {
        let expectation = self.expectation(description: "Storing image in memory cache")
        cache.store(shieldImage, forKey: "shieldKey", toDisk: false) {
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 1)
    }

    func storeImageOnDisk() {
        let expectation = self.expectation(description: "Storing image in disk cache")
        cache.store(shieldImage, forKey: "shieldKey", toDisk: true) {
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 1)
    }

    func testStoringImageInMemoryOnly() {
        storeImageInMemory()

        let returnedImage = cache.imageFromCache(forKey: "shieldKey")
        XCTAssertTrue((returnedImage?.isKind(of: UIImage.self))!)
    }

    func testResettingCache() {
        storeImageInMemory()

        cache.clearMemory()

        XCTAssertNil(cache.imageFromCache(forKey: "shieldKey"))

        storeImageOnDisk()

        cache.clearMemory()

        let expectation = self.expectation(description: "Clearing Disk Cache")
        cache.clearDisk {
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 1)

        XCTAssertNil(cache.imageFromCache(forKey: "shieldKey"))
    }

    func testStoringImageOnDisk() {
        storeImageOnDisk()

        var returnedImage = cache.imageFromCache(forKey: "shieldKey")
        XCTAssertTrue((returnedImage?.isKind(of: UIImage.self))!)

        cache.clearMemory()

        returnedImage = cache.imageFromCache(forKey: "shieldKey")
        XCTAssertNotNil(returnedImage)
        XCTAssertTrue((returnedImage?.isKind(of: UIImage.self))!)
    }

    func testClearingMemoryCacheOnMemoryWarning() {

    }
}
