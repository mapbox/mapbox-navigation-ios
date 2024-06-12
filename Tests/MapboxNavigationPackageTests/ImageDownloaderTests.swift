@testable import MapboxNavigationUIKit
import TestHelper
import XCTest

class ImageDownloaderTests: TestCase {
    lazy var sessionConfig: URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.protocolClasses = [ImageLoadingURLProtocolSpy.self]
        return config
    }()

    var downloader: ImageDownloaderProtocol!

    let imageURL = URL(string: "https://github.com/mapbox/mapbox-navigation-ios/blob/main/docs/img/navigation.png")!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        ImageLoadingURLProtocolSpy.reset()

        let imageData = ShieldImage.i280.image.pngData()!
        ImageLoadingURLProtocolSpy.registerData(imageData, forURL: imageURL)

        downloader = ImageDownloader(configuration: sessionConfig)
    }

    override func tearDown() {
        downloader = nil
        ImageLoadingURLProtocolSpy.reset()

        super.tearDown()
    }

    func testDownloadingAnImage() {
        var resultReturned: Result<CachedURLResponse, Error>?
        let semaphore = DispatchSemaphore(value: 0)

        downloader.download(with: imageURL) { result in
            resultReturned = result
            semaphore.signal()
        }
        let semaphoreResult = semaphore.wait(timeout: XCTestCase.NavigationTests.timeout)
        XCTAssert(semaphoreResult == .success, "Semaphore timed out")

        guard case .success(let cachedResponse) = resultReturned else {
            XCTFail("Failed to download request")
            return
        }

        let imageReturned = UIImage(data: cachedResponse.data, scale: UIScreen.main.scale)
        XCTAssertNotNil(imageReturned)
        XCTAssertTrue(imageReturned!.isKind(of: UIImage.self))
    }

    func testDownloadingImageWhileAlreadyInProgressAddsCallbacksWithoutAddingAnotherRequest() {
        var firstCallbackCalled = false
        var secondCallbackCalled = false

        // URL loading is delayed in order to simulate conditions under which multiple requests for the same asset would
        // be made
        ImageLoadingURLProtocolSpy.delayImageLoading()

        downloader.download(with: imageURL) { _ in
            firstCallbackCalled = true
        }

        downloader.download(with: imageURL) { _ in
            secondCallbackCalled = true
        }

        ImageLoadingURLProtocolSpy.resumeImageLoading()

        runUntil { firstCallbackCalled && secondCallbackCalled }

        XCTAssertTrue(firstCallbackCalled && secondCallbackCalled)
        XCTAssertEqual(ImageLoadingURLProtocolSpy.pastRequests.count, 1)
        XCTAssertEqual(ImageLoadingURLProtocolSpy.activeRequests.count, 0)
    }

    func testDownloadingImageAgainAfterFirstDownloadCompletes() {
        var callbackCalled = false

        downloader.download(with: imageURL) { _ in
            callbackCalled = true
        }

        runUntil { callbackCalled }
        XCTAssertTrue(callbackCalled)

        callbackCalled = false
        downloader.download(with: imageURL) { _ in
            callbackCalled = true
        }

        runUntil { callbackCalled }
        XCTAssertTrue(callbackCalled)
    }

    func testDownloadImageWithIncorrectUrl() {
        var resultReturned: Result<CachedURLResponse, Error>?
        let imageDownloaded = expectation(description: "Image Downloaded")

        let incorrectUrl = URL(fileURLWithPath: "/incorrect_url")
        downloader.download(with: incorrectUrl) { result in
            resultReturned = result
            imageDownloaded.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)

        XCTAssertNotNil(resultReturned)
        XCTAssertThrowsError(try resultReturned!.get())
    }

    func testDownloadWith400StatusCode() {
        var resultReturned: Result<CachedURLResponse, Error>?
        let imageDownloaded = expectation(description: "Image Downloaded")

        let faultyUrl = URL(string: "https://www.mapbox.com")!
        ImageLoadingURLProtocolSpy.registerHttpStatusCodeError(404, for: faultyUrl)
        downloader.download(with: faultyUrl) { result in
            resultReturned = result
            imageDownloaded.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
        guard case .success(let cachedResponse) = resultReturned,
              let urlResponse = cachedResponse.response as? HTTPURLResponse
        else {
            XCTFail(); return
        }
        XCTAssertEqual(urlResponse.statusCode, 404)
    }

    func testThreadSafetyStressTests() {
        let numberOfTests = 100
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
                self.downloader.download(with: imageUrl) { result in
                    var image: UIImage? = nil
                    if case .success(let cachedResponse) = result {
                        image = UIImage(data: cachedResponse.data, scale: UIScreen.main.scale)
                    }
                    addDownloadedImage(image, for: imageUrl)
                    allImagesDownloaded.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 10, handler: nil)

        XCTAssertEqual(downloadedImages.values.compactMap { $0 }.count, imageUrls.count)
    }

    func testPerformance() {
        measure(metrics: [
            XCTCPUMetric(),
            XCTMemoryMetric(),
        ]) {
            testThreadSafetyStressTests()
        }
    }
}
