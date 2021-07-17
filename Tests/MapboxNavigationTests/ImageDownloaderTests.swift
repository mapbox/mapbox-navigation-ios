import XCTest
@testable import MapboxNavigation
import TestHelper

class ImageDownloaderTests: TestCase {
    lazy var sessionConfig: URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.protocolClasses = [ImageLoadingURLProtocolSpy.self]
        return config
    }()

    var downloader: ReentrantImageDownloader!

    let imageURL = URL(string: "https://github.com/mapbox/mapbox-navigation-ios/blob/main/docs/img/navigation.png")!

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false

        ImageLoadingURLProtocolSpy.reset()

        let imageData = ShieldImage.i280.image.pngData()!
        ImageLoadingURLProtocolSpy.registerData(imageData, forURL: imageURL)

        downloader = ImageDownloader(sessionConfiguration: sessionConfig)
    }

    override func tearDown() {
        downloader = nil

        super.tearDown()
    }

    func testDownloadingAnImage() {
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

    func testDownloadImageWithIncorrectUrl() {
        var imageReturned: UIImage?
        var dataReturned: Data?
        var errorReturned: Error?
        let imageDownloaded = expectation(description: "Image Downloaded")

        let incorrectUrl = URL(fileURLWithPath: "/incorrect_url")
        downloader.downloadImage(with: incorrectUrl) { (image, data, error) in
            imageReturned = image
            dataReturned = data
            errorReturned = error
            imageDownloaded.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)

        XCTAssertNil(imageReturned)
        XCTAssertNil(dataReturned)
        XCTAssertNotNil(errorReturned)
    }

    func testDownloadWith400StatusCode() {
        var imageReturned: UIImage?
        var dataReturned: Data?
        var errorReturned: Error?
        let imageDownloaded = expectation(description: "Image Downloaded")

        let faultyUrl = URL(string: "https://www.mapbox.com")!
        ImageLoadingURLProtocolSpy.registerHttpStatusCodeError(404, for: faultyUrl)
        downloader.downloadImage(with: faultyUrl) { (image, data, error) in
            imageReturned = image
            dataReturned = data
            errorReturned = error
            imageDownloaded.fulfill()
        }
        let operation = (downloader.activeOperation(with: faultyUrl) as! ImageDownloadOperation)

        waitForExpectations(timeout: 10, handler: nil)
        XCTAssertTrue(operation.isFinished)
        XCTAssertFalse(operation.isExecuting)
        XCTAssertNil(imageReturned)
        XCTAssertNil(dataReturned)
        XCTAssertNotNil(errorReturned)
        guard let downloadError = errorReturned as? DownloadError else {
            XCTFail("Incorrect error returned"); return
        }
        XCTAssertEqual(downloadError, DownloadError.serverError)
    }

    func testDownloadWithImmidiateCancel() {
        let incorrectUrl = URL(fileURLWithPath: "/incorrect_url")
        downloader.downloadImage(with: incorrectUrl, completion: nil)
        let operation = (downloader.activeOperation(with: incorrectUrl) as! ImageDownloadOperation)
        operation.cancel()
        
        XCTAssertFalse(operation.isReady)
        XCTAssertFalse(operation.isExecuting)
        XCTAssertTrue(operation.isCancelled)
        XCTAssertTrue(operation.isFinished)
    }

    func testDownloadWithImmidiateCancelFromAnotherThread() {
        let incorrectUrl = URL(fileURLWithPath: "/incorrect_url")
        downloader.downloadImage(with: incorrectUrl, completion: nil)
        let operation = (downloader.activeOperation(with: incorrectUrl) as! ImageDownloadOperation)
        DispatchQueue.global().sync {
            operation.cancel()
        }

        XCTAssertFalse(operation.isReady)
        XCTAssertFalse(operation.isExecuting)
        XCTAssertTrue(operation.isCancelled)
        XCTAssertTrue(operation.isFinished)
    }

    func testThreadSafetyStressTests() {
        let numberOfTests: Int = 100
        let imageData = ShieldImage.i280.image.pngData()!

        let imageUrls: [URL] = (0..<numberOfTests).map { idx in
            URL(string: "https://mapbox.com/image/\(idx)")!
        }

        imageUrls.forEach {
            ImageLoadingURLProtocolSpy.registerData(imageData, forURL: $0)
        }

        let concurrentOvercommitQueue = DispatchQueue(label: "queue", attributes: .concurrent)

        let lock: NSLock = .init()
        var downloadedImages: [URL: UIImage?] = .init()
        func addDownloadedImage(_ image: UIImage?, for url: URL) {
            lock.lock(); defer {
                lock.unlock()
            }
            downloadedImages[url] = image
        }

        let allImagesDownloaded = expectation(description: "All Images Downloaded")
        allImagesDownloaded.expectedFulfillmentCount = imageUrls.count

        for imageUrl in imageUrls {
            concurrentOvercommitQueue.async {
                self.downloader.downloadImage(with: imageUrl) { image, data, error in
                    addDownloadedImage(image, for: imageUrl)
                    allImagesDownloaded.fulfill()
                }
            }
        }

        for imageUrl in imageUrls {
            concurrentOvercommitQueue.async {
                /// `activeOperation(with:)` should be thread safe
                _ = self.downloader.activeOperation(with: imageUrl)
            }
        }

        waitForExpectations(timeout: 10, handler: nil)

        XCTAssertEqual(downloadedImages.values.compactMap({$0}).count, imageUrls.count)
    }

    @available(iOS 13.0, *)
    func testPerformance() {
        measure(metrics: [
            XCTCPUMetric(),
            XCTMemoryMetric(),
        ]) {
            testThreadSafetyStressTests()
        }
    }
}
