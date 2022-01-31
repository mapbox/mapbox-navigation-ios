import XCTest
import TestHelper
@testable import MapboxNavigation

class SpriteMetaDataCacheTests: TestCase {
    let cache: SpriteMetaDataCache = SpriteMetaDataCache()

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false

        cache.clearMemory()
    }

    let dataKey = "default-3"

    func storeData() {
        let data = Fixture.JSONFromFileNamed(name: "sprite-metadata")
        cache.store(data)
    }

    func testStoringAndRetrievingData() {
        storeData()
        let spriteMetaData = cache.spriteMetaData(forKey: dataKey)
        XCTAssertNotNil(spriteMetaData)
        
        let expectedMetaData = SpriteMetaData(width: 156, height: 84, x: 1710, y: 1992, pixelRatio: 2, placeholder: [0,8,52,20], visible: true)
        XCTAssertEqual(expectedMetaData, spriteMetaData, "Failed to retrieve metadata from cache.")
        
    }

    func testClearingMemory() {
        storeData()
        cache.clearMemory()

        XCTAssertNil(cache.spriteMetaData(forKey: dataKey))
    }

    func testClearingMemoryCacheOnMemoryWarning() {
        storeData()
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)

        XCTAssertNil(cache.spriteMetaData(forKey: dataKey))
    }

    func testNotificationObserverDoesNotCrash() {
        var tempCache: SpriteMetaDataCache? = SpriteMetaDataCache()
        tempCache?.clearMemory()
        tempCache = nil

        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }

}
