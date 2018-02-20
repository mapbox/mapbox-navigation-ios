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

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false

        URLProtocol.registerClass(TestImageLoadingURLProtocol.self)
        TestImageLoadingURLProtocol.reset()

        let clearImageCacheExpectation = self.expectation(description: "Clear Image Cache")
        repository.resetImageCache {
            clearImageCacheExpectation.fulfill()
        }
        wait(for: [clearImageCacheExpectation], timeout: 1)
    }

    func test_imageWithURL_downloadsImageWhenNotCached() {
        let imageName = "1.png"
        let fakeURL = URL(string: "http://an.image.url/\(imageName)")!

        TestImageLoadingURLProtocol.registerData(UIImagePNGRepresentation(shieldImage)!, forURL: fakeURL)
        XCTAssertNil(repository.cachedImageForKey(imageName))

        var imageReturned: UIImage? = nil
        let asyncExpectation = self.expectation(description: "Waiting for image to download")

        repository.imageWithURL(fakeURL, cacheKey: imageName) { (image) in
            imageReturned = image
            asyncExpectation.fulfill()
        }
        wait(for: [asyncExpectation], timeout: 1)

        XCTAssertNotNil(imageReturned)
        // round-trip through UIImagePNGRepresentation results in changes in data due to metadata stripping, thus direct image comparison is not always possible.
        XCTAssertTrue((imageReturned?.isKind(of: UIImage.self))!)
    }

    func test_imageWithURL_prefersCachedImageWhenAvailable() {
        let imageName = "1.png"
        let fakeURL = URL(string: "http://an.image.url/\(imageName)")!

        repository.storeImage(shieldImage, forKey: imageName, toDisk: false)

        var imageReturned: UIImage? = nil
        let asyncExpectation = self.expectation(description: "Waiting for image to download")

        repository.imageWithURL(fakeURL, cacheKey: imageName) { (image) in
            imageReturned = image
            asyncExpectation.fulfill()
        }
        wait(for: [asyncExpectation], timeout: 1)

        XCTAssertFalse(TestImageLoadingURLProtocol.hasRequestForURL(fakeURL))
        XCTAssertNotNil(imageReturned)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(TestImageLoadingURLProtocol.self)
        super.tearDown()
    }
}
