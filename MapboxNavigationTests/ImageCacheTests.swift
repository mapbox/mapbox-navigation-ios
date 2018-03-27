import XCTest
@testable import MapboxNavigation


class ImageCacheTests: XCTestCase {

    let cache: ImageCache = ImageCache()
    let asyncTimeout: TimeInterval = 2.0

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false

        cache.clearMemory()
        let expectation = self.expectation(description: "Clearing Disk Cache")
        cache.clearDisk {
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: asyncTimeout)
    }

    let imageKey = "imageKey"

    private func storeImageInMemory() {
        let expectation = self.expectation(description: "Storing image in memory cache")
        cache.store(ShieldImage.i280.image, forKey: imageKey, toDisk: false) {
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: asyncTimeout)
    }

    private func storeImageOnDisk() {
        let expectation = self.expectation(description: "Storing image in disk cache")
        cache.store(ShieldImage.i280.image, forKey: imageKey, toDisk: true) {
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: asyncTimeout)
    }

    // MARK: Tests

    func testUsingURLStringAsCacheKey() {
        let cacheKeyURLString = "https://zombo.com/lulz/shieldKey.xyz"
        let expectation = self.expectation(description: "Storing image in disk cache")
        cache.store(ShieldImage.i280.image, forKey: cacheKeyURLString, toDisk: true) {
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: asyncTimeout)

        let returnedImage = cache.image(forKey: cacheKeyURLString)
        XCTAssertTrue((returnedImage?.isKind(of: UIImage.self))!)
    }

    func testUsingPathStringAsCacheKey() {
        let cacheKeyURLString = "/path/to/something.xyz"
        let expectation = self.expectation(description: "Storing image in disk cache")
        cache.store(ShieldImage.i280.image, forKey: cacheKeyURLString, toDisk: true) {
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: asyncTimeout)

        let returnedImage = cache.image(forKey: cacheKeyURLString)
        XCTAssertTrue((returnedImage?.isKind(of: UIImage.self))!)
    }

    func testStoringImageInMemoryOnly() {
        storeImageInMemory()

        let returnedImage = cache.image(forKey: imageKey)
        XCTAssertTrue((returnedImage?.isKind(of: UIImage.self))!)
    }

    func testStoringImageOnDisk() {
        storeImageOnDisk()

        var returnedImage = cache.image(forKey: imageKey)
        XCTAssertTrue((returnedImage?.isKind(of: UIImage.self))!)

        cache.clearMemory()

        returnedImage = cache.image(forKey: imageKey)
        XCTAssertNotNil(returnedImage)
        XCTAssertTrue((returnedImage?.isKind(of: UIImage.self))!)
    }

    func testResettingCache() {
        storeImageInMemory()

        cache.clearMemory()

        XCTAssertNil(cache.image(forKey: imageKey))

        storeImageOnDisk()

        cache.clearMemory()

        let expectation = self.expectation(description: "Clearing Disk Cache")
        cache.clearDisk {
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: asyncTimeout)

        XCTAssertNil(cache.image(forKey: imageKey))
    }

    func testClearingMemoryCacheOnMemoryWarning() {
        storeImageInMemory()
        
        NotificationCenter.default.post(name: .UIApplicationDidReceiveMemoryWarning, object: nil)

        XCTAssertNil(cache.image(forKey: imageKey))
    }

    func testJPEGSupport() {
        let imageJPEGData = UIImageJPEGRepresentation(ShieldImage.i280.image, 9.0)!
        let image = UIImage.init(data: imageJPEGData)!

        let expectation = self.expectation(description: "Storing image in disk cache")
        cache.store(image, forKey: "JPEG Test", toDisk: true) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: asyncTimeout)

        let retrievedImage = cache.image(forKey: "JPEG Test")!
        XCTAssertTrue(retrievedImage.isKind(of: UIImage.self))
    }

    func testNotificationObserverDoesNotCrash() {
        var tempCache: ImageCache? = ImageCache()
        tempCache?.clearMemory()
        tempCache = nil

        NotificationCenter.default.post(name: .UIApplicationDidReceiveMemoryWarning, object: nil)
    }
}
