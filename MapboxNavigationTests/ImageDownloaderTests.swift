import XCTest
@testable import MapboxNavigation


class ImageDownloaderTests: XCTestCase {

    lazy var sessionConfig: URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.protocolClasses = [TestImageLoadingURLProtocol.self]
        return config
    }()

    lazy var downloader: ReentrantImageDownloader = {
        return ImageDownloader(sessionConfiguration: sessionConfig)
    }()

    let imageURL = URL(string: "https://zombo.com/lulz/selfie.png")!

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false

        URLProtocol.registerClass(TestImageLoadingURLProtocol.self)
        TestImageLoadingURLProtocol.reset()

        let originalImageData = UIImagePNGRepresentation(shieldImage)!
        TestImageLoadingURLProtocol.registerData(originalImageData, forURL: imageURL)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(TestImageLoadingURLProtocol.self)

        super.tearDown()
    }

    func testDownloadingAnImage() {
        var imageReturned: UIImage?
        var dataReturned: Data?
        var errorReturned: Error?

        let async = self.expectation(description: "Image Download")
        downloader.downloadImage(with: imageURL) { (image, data, error) in
            imageReturned = image
            dataReturned = data
            errorReturned = error
            async.fulfill()
        }
        wait(for: [async], timeout: 1)

        XCTAssertNotNil(imageReturned)
        XCTAssertTrue(imageReturned!.isKind(of: UIImage.self))
        XCTAssertNotNil(dataReturned)
        XCTAssertNil(errorReturned)
    }

    func testDownloadingSameImageWhileInProgressAddsCallbacksWithoutAddingAnotherRequest() {
        let firstDownload = self.expectation(description: "First Image Download")
        let secondDownload = self.expectation(description: "Second Image Download")
        var firstCallbackCalled = false
        var secondCallbackCalled = false
        downloader.downloadImage(with: imageURL) { (image, data, error) in
            firstCallbackCalled = true
            firstDownload.fulfill()
        }
        downloader.downloadImage(with: imageURL) { (image, data, error) in
            secondCallbackCalled = true
            secondDownload.fulfill()
        }
        wait(for: [firstDownload, secondDownload], timeout: 1)

        //These flags might seem redundant, but it's good to be explicit sometimes
        XCTAssertTrue(firstCallbackCalled)
        XCTAssertTrue(secondCallbackCalled)
    }

    func testDownloadingImageAgainAfterFirstDownloadCompletes() {
        let firstDownload = self.expectation(description: "First Image Download")
        var firstCallbackCalled = false
        downloader.downloadImage(with: imageURL) { (image, data, error) in
            firstCallbackCalled = true
            firstDownload.fulfill()
        }
        wait(for: [firstDownload], timeout: 1)

        let secondDownload = self.expectation(description: "Second Image Download")
        var secondCallbackCalled = false
        downloader.downloadImage(with: imageURL) { (image, data, error) in
            secondCallbackCalled = true
            secondDownload.fulfill()
        }
        wait(for: [secondDownload], timeout: 1)

        //These flags might seem redundant, but it's good to be explicit sometimes
        XCTAssertTrue(firstCallbackCalled)
        XCTAssertTrue(secondCallbackCalled)
    }

}
