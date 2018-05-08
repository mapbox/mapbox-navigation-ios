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
        var operation: ImageDownload

        downloader.downloadImage(with: imageURL) { (image, data, error) in
            firstCallbackCalled = true
        }
        operation = downloader.activeOperationWithURL(imageURL)!

        downloader.downloadImage(with: imageURL) { (image, data, error) in
            secondCallbackCalled = true
        }

        XCTAssertTrue(operation === downloader.activeOperationWithURL(imageURL)!,
                      "Expected \(String(describing: operation)) to be identical to \(String(describing: downloader.activeOperationWithURL(imageURL)))")

        var spinCount = 0
        runUntil(condition: {
            spinCount += 1
            return operation.isFinished
        }, pollingInterval: 0.1, until: XCTestCase.NavigationTests.timeout)

        print("Succeeded after evaluating condition \(spinCount) times.")

        XCTAssertTrue(firstCallbackCalled)
        XCTAssertTrue(secondCallbackCalled)
    }

    func testDownloadingImageAgainAfterFirstDownloadCompletes() {
        guard let downloader = downloader else {
            XCTFail()
            return
        }
        var callbackCalled = false
        var spinCount = 0

        downloader.downloadImage(with: imageURL) { (image, data, error) in
            callbackCalled = true
        }
        var operation = downloader.activeOperationWithURL(imageURL)!

        runUntil(condition: {
            spinCount += 1
            return operation.isFinished
        }, pollingInterval: 0.1, until: XCTestCase.NavigationTests.timeout)

        print("Succeeded after evaluating first condition \(spinCount) times.")
        XCTAssertTrue(callbackCalled)

        callbackCalled = false
        spinCount = 0

        downloader.downloadImage(with: imageURL) { (image, data, error) in
            callbackCalled = true
        }
        operation = downloader.activeOperationWithURL(imageURL)!

        runUntil(condition: {
            spinCount += 1
            return operation.isFinished
        }, pollingInterval: 0.1, until: XCTestCase.NavigationTests.timeout)

        print("Succeeded after evaluating second condition \(spinCount) times.")
        XCTAssertTrue(callbackCalled)
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
