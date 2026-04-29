@testable import MapboxNavigationUIKit
import TestHelper
import XCTest

class ImageRepositoryTests: TestCase {
    lazy var repository: ImageRepository = {
        let config = URLSessionConfiguration.default
        config.protocolClasses = [ImageLoadingURLProtocolSpy.self]
        let downloader = LegacyImageDownloader(configuration: config)

        return ImageRepository(withDownloader: downloader)
    }()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        ImageLoadingURLProtocolSpy.reset()

        let semaphore = DispatchSemaphore(value: 0)
        repository.resetImageCache {
            semaphore.signal()
        }
        let semaphoreResult = semaphore.wait(timeout: XCTestCase.NavigationTests.timeout)
        XCTAssert(semaphoreResult == .success, "Semaphore timed out")
    }

    override func tearDown() {
        ImageLoadingURLProtocolSpy.reset()

        super.tearDown()
    }

    func test_imageWithURL_downloadsImageWhenNotCached() {
        let imageName = "1.png"
        let fakeURL = URL(string: "http://an.image.url/\(imageName)")!

        ImageLoadingURLProtocolSpy.registerData(ShieldImage.i280.image.pngData()!, forURL: fakeURL)
        XCTAssertNil(repository.cachedImageForKey(imageName))

        var imageReturned: UIImage? = nil
        let semaphore = DispatchSemaphore(value: 0)

        repository.imageWithURL(fakeURL, cacheKey: imageName) { image in
            imageReturned = image
            semaphore.signal()
        }
        let semaphoreResult = semaphore.wait(timeout: XCTestCase.NavigationTests.timeout)
        XCTAssert(semaphoreResult == .success, "Semaphore timed out")

        XCTAssertNotNil(imageReturned)
        // round-trip through UIImagePNGRepresentation results in changes in data due to metadata stripping, thus direct
        // image comparison is not always possible.
        XCTAssertTrue((imageReturned?.isKind(of: UIImage.self))!)
    }

    func test_imageWithURL_prefersCachedImageWhenAvailable() {
        let imageName = "1.png"
        let fakeURL = URL(string: "http://an.image.url/\(imageName)")!

        repository.storeImage(ShieldImage.i280.image, forKey: imageName, toDisk: false)

        var imageReturned: UIImage? = nil
        let semaphore = DispatchSemaphore(value: 0)

        repository.imageWithURL(fakeURL, cacheKey: imageName) { image in
            imageReturned = image
            semaphore.signal()
        }
        let semaphoreResult = semaphore.wait(timeout: XCTestCase.NavigationTests.timeout)
        XCTAssert(semaphoreResult == .success, "Semaphore timed out")

        XCTAssertNil(ImageLoadingURLProtocolSpy.pastRequestForURL(fakeURL))
        XCTAssertNotNil(imageReturned)
    }
}

class LegacyImageDownloader: ImageDownloaderProtocol {
    private let urlSession: URLSession

    init(configuration: URLSessionConfiguration? = nil) {
        let defaultConfiguration = URLSessionConfiguration.default
        defaultConfiguration.urlCache = URLCache(
            memoryCapacity: 5 * 1024 * 1024,
            diskCapacity: 20 * 1024 * 1024,
            diskPath: nil
        )
        self.urlSession = URLSession(configuration: configuration ?? defaultConfiguration)
    }

    func download(with url: URL, completion: @escaping (Result<CachedURLResponse, Error>) -> Void) {
        urlSession.dataTask(with: URLRequest(url)) { data, response, error in
            if let response, let data {
                completion(.success(CachedURLResponse(response: response, data: data)))
            } else if let error {
                completion(.failure(error))
            }
        }.resume()
    }
}
