import XCTest
@testable import MapboxNavigation


class DataCacheTests: XCTestCase {

    let cache: DataCache = DataCache()
    let asyncTimeout: TimeInterval = 2.0

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false

        cache.clearMemory()
        let expectation = self.expectation(description: "Clearing Disk Cache")
        cache.clearDisk {
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: asyncTimeout)
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
        let expectation = self.expectation(description: "Storing data in memory cache")
        cache.store(exampleData!, forKey: dataKey, toDisk: false) {
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: asyncTimeout)
    }

    private func storeDataOnDisk() {
        let expectation = self.expectation(description: "Storing data in disk cache")
        cache.store(exampleData!, forKey: dataKey, toDisk: true) {
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: asyncTimeout)
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

        let expectation = self.expectation(description: "Clearing Disk Cache")
        cache.clearDisk {
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: asyncTimeout)

        XCTAssertNil(cache.data(forKey: dataKey))
    }

    func testClearingMemoryCacheOnMemoryWarning() {
        storeDataInMemory()

        NotificationCenter.default.post(name: .UIApplicationDidReceiveMemoryWarning, object: nil)

        XCTAssertNil(cache.data(forKey: dataKey))
    }
}
