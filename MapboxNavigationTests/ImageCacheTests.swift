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

    let imageKey = "imageKey"

    func storeImageInMemory() {
        let expectation = self.expectation(description: "Storing image in memory cache")
        cache.store(shieldImage, forKey: imageKey, toDisk: false) {
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 1)
    }

    func storeImageOnDisk() {
        let expectation = self.expectation(description: "Storing image in disk cache")
        cache.store(shieldImage, forKey: imageKey, toDisk: true) {
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 1)
    }

    func testUsingURLStringAsCacheKey() {
        let cacheKeyURLString = "https://zombo.com/lulz/shieldKey.xyz"
        let expectation = self.expectation(description: "Storing image in disk cache")
        cache.store(shieldImage, forKey: cacheKeyURLString, toDisk: true) {
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 1)

        let returnedImage = cache.imageFromCache(forKey: cacheKeyURLString)
        XCTAssertTrue((returnedImage?.isKind(of: UIImage.self))!)
    }

    func testStoringImageInMemoryOnly() {
        storeImageInMemory()

        let returnedImage = cache.imageFromCache(forKey: imageKey)
        XCTAssertTrue((returnedImage?.isKind(of: UIImage.self))!)
    }

    func testResettingCache() {
        storeImageInMemory()

        cache.clearMemory()

        XCTAssertNil(cache.imageFromCache(forKey: imageKey))

        storeImageOnDisk()

        cache.clearMemory()

        let expectation = self.expectation(description: "Clearing Disk Cache")
        cache.clearDisk {
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 1)

        XCTAssertNil(cache.imageFromCache(forKey: imageKey))
    }

    func testStoringImageOnDisk() {
        storeImageOnDisk()

        var returnedImage = cache.imageFromCache(forKey: imageKey)
        XCTAssertTrue((returnedImage?.isKind(of: UIImage.self))!)

        cache.clearMemory()

        returnedImage = cache.imageFromCache(forKey: imageKey)
        XCTAssertNotNil(returnedImage)
        XCTAssertTrue((returnedImage?.isKind(of: UIImage.self))!)
    }

    func testClearingMemoryCacheOnMemoryWarning() {
        storeImageInMemory()

        NotificationCenter.default.post(name: .UIApplicationDidReceiveMemoryWarning, object: nil)

        XCTAssertNil(cache.imageFromCache(forKey: imageKey))
    }
}
