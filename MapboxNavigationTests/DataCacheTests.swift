import XCTest
@testable import MapboxNavigation


class DataCacheTests: XCTestCase {

    let cache: DataCache = DataCache()

    private func clearDisk() {
        let semaphore = DispatchSemaphore(value: 0)
        cache.clearDisk {
            semaphore.signal()
        }
        let semaphoreResult = semaphore.wait(timeout: XCTestCase.NavigationTests.timeout)
        XCTAssert(semaphoreResult == .success, "Semaphore timed out")
    }

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false

        cache.clearMemory()
        clearDisk()
    }

    let dataKey = "dataKey"

    var exampleData: Data? {
        get {
            let bundle = Bundle(for: InstructionsBannerViewIntegrationTests.self)
            do {
                return try NSData.init(contentsOf: bundle.url(forResource: "route", withExtension: ".json")!) as Data
            } catch {
                XCTFail("Failed to create data")
                return nil
            }
        }
    }

    private func storeDataInMemory() {
        let semaphore = DispatchSemaphore(value: 0)
        cache.store(exampleData!, forKey: dataKey, toDisk: false) {
            semaphore.signal()
        }
        let semaphoreResult = semaphore.wait(timeout: XCTestCase.NavigationTests.timeout)
        XCTAssert(semaphoreResult == .success, "Semaphore timed out")
    }

    private func storeDataOnDisk() {
        let semaphore = DispatchSemaphore(value: 0)
        cache.store(exampleData!, forKey: dataKey, toDisk: true) {
            semaphore.signal()
        }
        let semaphoreResult = semaphore.wait(timeout: XCTestCase.NavigationTests.timeout)
        XCTAssert(semaphoreResult == .success, "Semaphore timed out")
    }

    // MARK: Tests

    func testStoringDataInMemoryOnly() {
        storeDataInMemory()

        let returnedData = cache.data(forKey: dataKey)
        XCTAssertNotNil(returnedData)
    }

    func testStoringDataOnDisk() {
        storeDataOnDisk()

        var returnedData = cache.data(forKey: dataKey)
        XCTAssertNotNil(returnedData)

        cache.clearMemory()

        returnedData = cache.data(forKey: dataKey)
        XCTAssertNotNil(returnedData)
    }

    func testResettingCache() {
        storeDataInMemory()

        cache.clearMemory()

        XCTAssertNil(cache.data(forKey: dataKey))

        storeDataOnDisk()

        cache.clearMemory()
        clearDisk()

        XCTAssertNil(cache.data(forKey: dataKey))
    }

    func testClearingMemoryCacheOnMemoryWarning() {
        storeDataInMemory()

        NotificationCenter.default.post(name: .UIApplicationDidReceiveMemoryWarning, object: nil)

        XCTAssertNil(cache.data(forKey: dataKey))
    }

    func testNotificationObserverDoesNotCrash() {
        var tempCache: DataCache? = DataCache()
        tempCache?.clearMemory()
        tempCache = nil

        NotificationCenter.default.post(name: .UIApplicationDidReceiveMemoryWarning, object: nil)
    }
    
    func testCacheKeyForKey() {
        XCTAssertNotEqual(cache.fileCache.cacheKeyForKey("foo"), cache.fileCache.cacheKeyForKey("foo?nope"))
        
        let voiceInstruction = "/<speak><mb%3Aeffect%20name%3D\"drc\"><prosody%20rate%3D\"1.08\">Continue%20on%20<say-as%20interpret-as%3D\"address\">3rd<%2Fprosody><%2Fmb%3Aeffect><%2Fspeak>"
        
        XCTAssertNotEqual(cache.fileCache.cacheKeyForKey(voiceInstruction), cache.fileCache.cacheKeyForKey("http://foo.com?nope"))
    }
}
