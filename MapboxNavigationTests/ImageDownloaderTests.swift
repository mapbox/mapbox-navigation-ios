import XCTest
@testable import MapboxNavigation


class ImageDownloaderTests: XCTestCase {

    lazy var sessionConfig: URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.protocolClasses = [ImageLoadingURLProtocolSpy.self]
        return config
    }()

    lazy var downloader: ReentrantImageDownloader = {
        return ImageDownloader(sessionConfiguration: sessionConfig)
    }()

    let imageURL = URL(string: "https://zombo.com/lulz/selfie.png")!

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false

        URLProtocol.registerClass(ImageLoadingURLProtocolSpy.self)
        ImageLoadingURLProtocolSpy.reset()

        let originalImageData = UIImagePNGRepresentation(ShieldImage.i280.image)!
        ImageLoadingURLProtocolSpy.registerData(originalImageData, forURL: imageURL)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(ImageLoadingURLProtocolSpy.self)

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
        semaphore.wait()

        // The ImageDownloader is meant to be used with an external caching mechanism
        let request = ImageLoadingURLProtocolSpy.pastRequestForURL(imageURL)!
        XCTAssertEqual(request.cachePolicy, .reloadIgnoringCacheData)

        XCTAssertNotNil(imageReturned)
        XCTAssertTrue(imageReturned!.isKind(of: UIImage.self))
        XCTAssertNotNil(dataReturned)
        XCTAssertNil(errorReturned)
    }

    func testDownloadingSameImageWhileInProgressAddsCallbacksWithoutAddingAnotherRequest() {
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
            return downloader.activeOperationWithURL(imageURL) == nil
        }, pollingInterval: 0.1)

        //These flags might seem redundant, but it's good to be explicit here
        XCTAssertTrue(firstCallbackCalled)
        XCTAssertTrue(secondCallbackCalled)
    }

    func testDownloadingImageAgainAfterFirstDownloadCompletes() {
        let semaphore = DispatchSemaphore(value: 0)
        var firstCallbackCalled = false

        downloader.downloadImage(with: imageURL) { (image, data, error) in
            firstCallbackCalled = true
            semaphore.signal()
        }
        semaphore.wait()

        // we are beholden to the URL loading system here... can't proceed until the URLProtocol has finished winding down its previous URL loading work
        runUntil(condition: {
            return downloader.activeOperationWithURL(imageURL) == nil
        }, pollingInterval: 0.1)

        var secondCallbackCalled = false

        downloader.downloadImage(with: imageURL) { (image, data, error) in
            secondCallbackCalled = true
            semaphore.signal()
        }
        semaphore.wait()

        //These flags might seem redundant, but it's good to be explicit sometimes
        XCTAssertTrue(firstCallbackCalled)
        XCTAssertTrue(secondCallbackCalled)
    }

    private func runUntil(condition: () -> Bool, pollingInterval: TimeInterval) {
        if condition() == false {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: pollingInterval))
            runUntil(condition: condition, pollingInterval: pollingInterval)
        }
    }
}
