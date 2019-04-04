import XCTest
@testable import MapboxNavigation


class ImageCacheTests: XCTestCase {

    let cache: ImageCache = ImageCache()
    let asyncTimeout: TimeInterval = 10.0

    private func clearDiskCache() {
        let semaphore = DispatchSemaphore(value: 0)
        cache.clearDisk {
            semaphore.signal()
        }
        let semaphoreResult = semaphore.wait(timeout: XCTestCase.NavigationTests.timeout)
        XCTAssert(semaphoreResult == .success, "Semaphore timed out")
    }

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false

        cache.clearMemory()
        clearDiskCache()
    }

    let imageKey = "imageKey"

    private func storeImageInMemory() {
        let semaphore = DispatchSemaphore(value: 0)
        cache.store(ShieldImage.i280.image, forKey: imageKey, toDisk: false) {
            semaphore.signal()
        }
        let semaphoreResult = semaphore.wait(timeout: XCTestCase.NavigationTests.timeout)
        XCTAssert(semaphoreResult == .success, "Semaphore timed out")
    }

    private func storeImageOnDisk() {
        let semaphore = DispatchSemaphore(value: 0)
        cache.store(ShieldImage.i280.image, forKey: imageKey, toDisk: true) {
            semaphore.signal()
        }
        let semaphoreResult = semaphore.wait(timeout: XCTestCase.NavigationTests.timeout)
        XCTAssert(semaphoreResult == .success, "Semaphore timed out")
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
        clearDiskCache()

        XCTAssertNil(cache.image(forKey: imageKey))
    }

    func testClearingMemoryCacheOnMemoryWarning() {
        storeImageInMemory()
        
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)

        XCTAssertNil(cache.image(forKey: imageKey))
    }

    func testJPEGSupport() {
        let imageJPEGData = ShieldImage.i280.image.jpegData(compressionQuality: 9.0)!
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

        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
}
