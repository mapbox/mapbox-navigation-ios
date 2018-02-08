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

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false

        URLProtocol.registerClass(TestImageLoadingURLProtocol.self)
        TestImageLoadingURLProtocol.reset()
    }

    override func tearDown() {
        URLProtocol.unregisterClass(TestImageLoadingURLProtocol.self)

        super.tearDown()
    }

    func testDownloadingAnImage() {
        let originalImageData = UIImagePNGRepresentation(shieldImage)!
        let imageURL = URL(string: "https://zombo.com/lulz/selfie.png")!
        TestImageLoadingURLProtocol.registerData(originalImageData, forURL: imageURL)

        var imageReturned: UIImage?
        var dataReturned: Data?
        var errorReturned: Error?
        var downloadSuccess = false

        let async = self.expectation(description: "Image Download")
        downloader.downloadImage(with: imageURL) { (image, data, error, success) in
            imageReturned = image
            dataReturned = data
            errorReturned = error
            downloadSuccess = success
            async.fulfill()
        }
        wait(for: [async], timeout: 1)

        XCTAssertTrue(downloadSuccess)
        XCTAssertNotNil(imageReturned)
        XCTAssertTrue(imageReturned!.isKind(of: UIImage.self))
        XCTAssertNotNil(dataReturned)
        XCTAssertEqual(dataReturned!, UIImagePNGRepresentation(imageReturned!))
        XCTAssertNil(errorReturned)
    }

//    func testDownloadingSameImageWhileInProgressAddsCallbacks() {
//
//    }

//    func testDownloadingImageAgainAfterFirstDownloadCompletes() {
//
//    }

//    func testIgnoresURLCache() {
//
//    }
}
