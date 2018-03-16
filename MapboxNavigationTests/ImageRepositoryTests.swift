import XCTest
@testable import MapboxNavigation

class ImageRepositoryTests: XCTestCase {

    lazy var repository: ImageRepository = {
        let repo = ImageRepository.shared
        let config = URLSessionConfiguration.default
        config.protocolClasses = [TestImageLoadingURLProtocol.self]
        repo.sessionConfiguration = config

        return repo
    }()

    let asyncTimeout: TimeInterval = 2.0

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false

        URLProtocol.registerClass(TestImageLoadingURLProtocol.self)
        TestImageLoadingURLProtocol.reset()

        let clearImageCacheExpectation = self.expectation(description: "Clear Image Cache")
        repository.resetImageCache {
            clearImageCacheExpectation.fulfill()
        }
        wait(for: [clearImageCacheExpectation], timeout: asyncTimeout)
    }

    func test_imageWithURL_downloadsImageWhenNotCached() {
        let imageName = "1.png"
        let fakeURL = URL(string: "http://an.image.url/\(imageName)")!

        TestImageLoadingURLProtocol.registerData(UIImagePNGRepresentation(ShieldImage.i280.image)!, forURL: fakeURL)
        XCTAssertNil(repository.cachedImageForKey(imageName))

        var imageReturned: UIImage? = nil
        let asyncExpectation = self.expectation(description: "Waiting for image to download")

        repository.imageWithURL(fakeURL, cacheKey: imageName) { (image) in
            imageReturned = image
            asyncExpectation.fulfill()
        }
        wait(for: [asyncExpectation], timeout: asyncTimeout)

        XCTAssertNotNil(imageReturned)
        // round-trip through UIImagePNGRepresentation results in changes in data due to metadata stripping, thus direct image comparison is not always possible.
        XCTAssertTrue((imageReturned?.isKind(of: UIImage.self))!)
    }

    func test_imageWithURL_prefersCachedImageWhenAvailable() {
        let imageName = "1.png"
        let fakeURL = URL(string: "http://an.image.url/\(imageName)")!

        repository.storeImage(ShieldImage.i280.image, forKey: imageName, toDisk: false)

        var imageReturned: UIImage? = nil
        let asyncExpectation = self.expectation(description: "Waiting for image to download")

        repository.imageWithURL(fakeURL, cacheKey: imageName) { (image) in
            imageReturned = image
            asyncExpectation.fulfill()
        }
        wait(for: [asyncExpectation], timeout: asyncTimeout)

        XCTAssertNil(TestImageLoadingURLProtocol.pastRequestForURL(fakeURL))
        XCTAssertNotNil(imageReturned)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(TestImageLoadingURLProtocol.self)
        super.tearDown()
    }
}
