import XCTest
@testable import MapboxNavigation


class ImageDownloaderTests: XCTestCase {

    lazy var sessionConfig: URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.protocolClasses = [ImageLoadingURLProtocolSpy.self]
        return config
    }()

    var downloader: ReentrantImageDownloader?

    let imageURL = URL(fileURLWithPath: Bundle(for: ImageDownloaderTests.self).path(forResource: "image", ofType: "png")!)

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

    func testDownloadingImageWhileAlreadyInProgressAddsCallbacksWithoutAddingAnotherRequest() {
        guard let downloader = downloader else {
            XCTFail()
            return
        }
        var firstCallbackCalled = false
        var secondCallbackCalled = false
        var operation: ImageDownload

        // URL loading is delayed in order to simulate conditions under which multiple requests for the same asset would be made
        ImageLoadingURLProtocolSpy.delayImageLoading()

        downloader.downloadImage(with: imageURL) { (image, data, error) in
            firstCallbackCalled = true
        }
        operation = downloader.activeOperation(with: imageURL)!

        downloader.downloadImage(with: imageURL) { (image, data, error) in
            secondCallbackCalled = true
        }

        ImageLoadingURLProtocolSpy.resumeImageLoading()

        XCTAssertTrue(operation === downloader.activeOperation(with: imageURL)!,
                      "Expected \(String(describing: operation)) to be identical to \(String(describing: downloader.activeOperation(with: imageURL)))")

        var spinCount = 0

        runUntil({
            spinCount += 1
            return operation.isFinished
        })

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
        var operation = downloader.activeOperation(with: imageURL)!

        runUntil({
            spinCount += 1
            return operation.isFinished
        })

        print("Succeeded after evaluating first condition \(spinCount) times.")
        XCTAssertTrue(callbackCalled)

        callbackCalled = false
        spinCount = 0

        downloader.downloadImage(with: imageURL) { (image, data, error) in
            callbackCalled = true
        }
        operation = downloader.activeOperation(with: imageURL)!

        runUntil({
            spinCount += 1
            return operation.isFinished
        })

        print("Succeeded after evaluating second condition \(spinCount) times.")
        XCTAssertTrue(callbackCalled)
    }

    private func runUntil(_ condition: () -> Bool, testCase: String = #function) {
        runUntil(condition: condition, testCase: testCase, pollingInterval: NavigationTests.pollingInterval, until: NavigationTests.timeout)
    }

    private func runUntil(condition: () -> Bool, testCase: String, pollingInterval: TimeInterval, until timeout: DispatchTime) {
        guard (timeout >= DispatchTime.now()) else {
            XCTFail("Timeout occurred in \(testCase)")
            return
        }
        
        if condition() == false {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: pollingInterval))
            runUntil(condition: condition, testCase: testCase, pollingInterval: pollingInterval, until: timeout)
        }
    }
}
