import XCTest
@testable import MapboxNavigation


class ImageDownloaderTests: XCTestCase {

    lazy var sessionConfig: URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.protocolClasses = [ImageLoadingURLProtocolSpy.self]
        return config
    }()

    var downloader: ReentrantImageDownloader?

    let imageURL = URL(string: "https://zombo.com/lulz/selfie.png")!

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false

        ImageLoadingURLProtocolSpy.reset()

        let imageData = UIImagePNGRepresentation(ShieldImage.i280.image)!
        ImageLoadingURLProtocolSpy.registerData(imageData, forURL: imageURL)

        downloader = ImageDownloader(sessionConfiguration: sessionConfig)
    }

    override func tearDown() {
        downloader = nil

        super.tearDown()
    }

    func testDownloadingAnImage() {
        guard let downloader = downloader else {
            XCTFail()
            return
        }
        var imageReturned: UIImage?
        var dataReturned: Data?
        var errorReturned: Error?
        let semaphore = DispatchSemaphore(value: 0)

        downloader.downloadImage(with: imageURL) { (image, data, error) in
            imageReturned = image
            dataReturned = data
            errorReturned = error
            semaphore.signal()
        }
        let semaphoreResult = semaphore.wait(timeout: XCTestCase.NavigationTests.timeout)
        XCTAssert(semaphoreResult == .success, "Semaphore timed out")

        // The ImageDownloader is meant to be used with an external caching mechanism
        let request = ImageLoadingURLProtocolSpy.pastRequestForURL(imageURL)!
        XCTAssertEqual(request.cachePolicy, .reloadIgnoringCacheData)

        XCTAssertNotNil(imageReturned)
        XCTAssertTrue(imageReturned!.isKind(of: UIImage.self))
        XCTAssertNotNil(dataReturned)
        XCTAssertNil(errorReturned)
    }

    func testDownloadingSameImageWhileInProgressAddsCallbacksWithoutAddingAnotherRequest() {
        guard let downloader = downloader else {
            XCTFail()
            return
        }
        var firstCallbackCalled = false
        var secondCallbackCalled = false
        var operation: ImageDownload?

        downloader.downloadImage(with: imageURL) { (image, data, error) in
            firstCallbackCalled = true
        }
        operation = downloader.activeOperationWithURL(imageURL)!

        downloader.downloadImage(with: imageURL) { (image, data, error) in
            secondCallbackCalled = true
        }

        XCTAssertTrue(operation! === downloader.activeOperationWithURL(imageURL)!, "Expected \(String(describing: operation)) to be identical to \(String(describing: downloader.activeOperationWithURL(imageURL)))")

        runUntil(condition: {
            return ImageLoadingURLProtocolSpy.hasActiveRequestForURL(imageURL) == false && downloader.activeOperationWithURL(imageURL) == nil
        }, pollingInterval: 0.1, until: XCTestCase.NavigationTests.timeout)

        //These flags might seem redundant, but it's good to be explicit here
        XCTAssertTrue(firstCallbackCalled)
        XCTAssertTrue(secondCallbackCalled)
    }

    func disabled_testDownloadingImageAgainAfterFirstDownloadCompletes() {
        guard let downloader = downloader else {
            XCTFail()
            return
        }
        let semaphore = DispatchSemaphore(value: 0)
        var firstCallbackCalled = false

        downloader.downloadImage(with: imageURL) { (image, data, error) in
            firstCallbackCalled = true
            semaphore.signal()
        }
        let semaphoreResult = semaphore.wait(timeout: XCTestCase.NavigationTests.timeout)
        XCTAssert(semaphoreResult == .success, "Semaphore timed out")
        
        // we are beholden to the URL loading system here... can't proceed until the URLProtocol has finished winding down its previous URL loading work
        runUntil(condition: {
            return ImageLoadingURLProtocolSpy.hasActiveRequestForURL(imageURL) == false && downloader.activeOperationWithURL(imageURL) == nil
        }, pollingInterval: 0.1, until: XCTestCase.NavigationTests.timeout)

        var secondCallbackCalled = false

        downloader.downloadImage(with: imageURL) { (image, data, error) in
            secondCallbackCalled = true
            semaphore.signal()
        }
        let secondSemaphoreResult = semaphore.wait(timeout: XCTestCase.NavigationTests.timeout)
        XCTAssert(secondSemaphoreResult == .success, "Semaphore timed out")
        
        //These flags might seem redundant, but it's good to be explicit sometimes
        XCTAssertTrue(firstCallbackCalled)
        XCTAssertTrue(secondCallbackCalled)
    }

    private func runUntil(condition: () -> Bool, pollingInterval: TimeInterval, until timeout: DispatchTime) {
        guard (timeout >= DispatchTime.now()) else {
            XCTFail("Timeout occurred on \(#function)")
            return
        }
        
        if condition() == false {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: pollingInterval))
            runUntil(condition: condition, pollingInterval: pollingInterval, until: timeout)
        }
    }
}
