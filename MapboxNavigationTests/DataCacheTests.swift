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
        let threeMileInstruction = "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">Continue on <say-as interpret-as=\"address\">I-80</say-as> East for 3 miles</prosody></amazon:effect></speak>"
        let sixMileInstruction = "<speak><amazon:effect name=\"drc\"><prosody rate=\"1.08\">Continue on <say-as interpret-as=\"address\">I-80</say-as> East for 6 miles</prosody></amazon:effect></speak>"
        XCTAssertNotEqual(cache.fileCache.cacheKeyForKey(threeMileInstruction), cache.fileCache.cacheKeyForKey(sixMileInstruction))
    }
}
