import XCTest
import TestHelper
@testable import MapboxNavigation

class URLDataCacheTest: TestCase {
    let url = ShieldImage.i280.baseURL
    var cache: URLDataCache!

    override func setUp() {
        super.setUp()

        self.continueAfterFailure = false
        cache = URLDataCache()
        cache.urlCache.diskCapacity = 0
    }

    private func exampleResponse(with storagePolicy: URLCache.StoragePolicy) -> CachedURLResponse {
        let data = Fixture.JSONFromFileNamed(name: "sprite-info")
        let response = URLResponse(url: url, mimeType: nil, expectedContentLength: data.count, textEncodingName: nil)
        let cachedResponse = CachedURLResponse(response: response, data: data, storagePolicy: storagePolicy)
        return cachedResponse
    }

    func testStoreCache() {
        let response = exampleResponse(with: .allowed)
        
        cache.store(response, for: url)
        
        let cachedResponse = cache.response(for: url)
        XCTAssertNotNil(cachedResponse)
        XCTAssertEqual(cachedResponse, response)
    }
    
    func testClearCache() {
        let response = exampleResponse(with: .allowed)

        cache.store(response, for: url)
        XCTAssertEqual(cache.response(for: url), response)

        cache.clearCache()
        XCTAssertNil(cache.response(for: url)?.data)
        XCTAssertEqual(cache.urlCache.currentMemoryUsage, 0)
    }
    
    func testRemoveRequestCache() {
        let response = exampleResponse(with: .allowed)
        
        cache.store(response, for: url)
        XCTAssertNotNil(cache.response(for: url))
        
        cache.removeCache(for: url)
        XCTAssertNil(cache.response(for: url)?.data)
    }

    func testStoreCacheInMemoryOnly() {
        let response = exampleResponse(with: .allowedInMemoryOnly)
        
        cache.store(response, for: url)
        
        let cachedResponse = cache.response(for: url)
        XCTAssertEqual(cachedResponse, response)
        XCTAssertEqual(cache.urlCache.currentMemoryUsage, response.data.count)
    }
    
    func testStoreCacheWithMemoryWarning() {
        let response = exampleResponse(with: .allowed)

        cache.store(response, for: url)
        XCTAssertEqual(cache.response(for: url), response)

        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        XCTAssertEqual(cache.response(for: url), response)
    }
    
    func testStoreCacheOutOfCapacity() {
        let response = exampleResponse(with: .allowedInMemoryOnly)
        
        let limitCapacity = 1
        let limitCache = URLDataCache(memoryCapacity: limitCapacity, diskCapacity: limitCapacity)
        XCTAssertTrue(response.data.count > limitCapacity)
        
        limitCache.store(response, for: url)
        XCTAssertNil(cache.response(for: url))
        XCTAssertEqual(limitCache.urlCache.currentMemoryUsage, 0)
        
        limitCache.urlCache.diskCapacity = 0
        limitCache.clearCache()
    }
}

