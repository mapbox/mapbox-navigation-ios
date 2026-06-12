import XCTest
import TestHelper
@testable import MapboxNavigation

class URLDataCacheTest: TestCase {
    let url = ShieldImage.i280.baseURL
    let secondURL = URL(string: "https://www.mapbox.com/second-shield.png")!
    let data = Fixture.JSONFromFileNamed(name: "sprite-info")
    var cache: URLDataCache!
    
    private static var cacheURL: URL {
        let fileManager = FileManager.default
        let basePath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let identifier = Bundle.main.bundleIdentifier!
        return basePath.appendingPathComponent(identifier).appendingPathComponent("TestURLDataCache")
    }

    override func setUp() {
        super.setUp()

        self.continueAfterFailure = false
        cache = URLDataCache(diskCapacity: 0, diskCacheURL: Self.cacheURL)
        cache.clearCache()
    }
    
    override func tearDown() {
        cache.clearCache()
        super.tearDown()
    }

    func testStoreCache() {
        cache.store(data, for: url)
        
        let cachedData = cache.data(for: url)
        XCTAssertNotNil(cachedData)
        XCTAssertEqual(cachedData, data)
        XCTAssertGreaterThan(cache.currentMemoryUsage, 0)
    }
    
    func testClearCache() {
        cache.store(data, for: url)
        XCTAssertEqual(cache.data(for: url), data)

        cache.clearCache()
        XCTAssertNil(cache.data(for: url))
        XCTAssertEqual(cache.currentMemoryUsage, 0)
        XCTAssertEqual(cache.currentDiskUsage, 0)
    }
    
    func testRemoveRequestCache() {
        cache.store(data, for: url)
        cache.store(data, for: secondURL)
        XCTAssertNotNil(cache.data(for: url))
        XCTAssertNotNil(cache.data(for: secondURL))
        
        cache.removeCache(for: url)
        XCTAssertNil(cache.data(for: url))
        XCTAssertEqual(cache.data(for: secondURL), data)
    }

    func testStoreCacheInMemoryOnly() {
        cache.store(data, for: url)
        
        let cachedData = cache.data(for: url)
        XCTAssertEqual(cachedData, data)
        XCTAssertEqual(cache.currentMemoryUsage, data.count)
    }
    
    func testStoreCacheWithMemoryWarning() {
        cache.store(data, for: url)
        XCTAssertEqual(cache.data(for: url), data)

        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        XCTAssertEqual(cache.data(for: url), data)
    }
    
    func testStoreCacheOutOfCapacity() {
        let limitCapacity = 1
        XCTAssertTrue(data.count > limitCapacity)
        
        let limitCache = URLDataCache(
            memoryCapacity: limitCapacity,
            diskCapacity: limitCapacity,
            diskCacheURL: Self.cacheURL
        )
        limitCache.clearCache()
        
        limitCache.store(data, for: url)
        XCTAssertNil(limitCache.data(for: url))
        XCTAssertEqual(limitCache.currentMemoryUsage, 0)
        XCTAssertEqual(limitCache.currentDiskUsage, 0)
    }

    func testStoreCacheOnDisk() {
        let diskCache = URLDataCache(diskCapacity: data.count * 2, diskCacheURL: Self.cacheURL)

        diskCache.store(data, for: url)
        XCTAssertGreaterThan(diskCache.currentDiskUsage, 0)
        cache = URLDataCache(diskCapacity: 0, diskCacheURL: Self.cacheURL)

        XCTAssertEqual(cache.data(for: url), data)
    }
}

