import XCTest
import TestHelper
@testable import MapboxNavigation

class SpriteInfoCacheTests: TestCase {
    let cache: SpriteInfoCache = SpriteInfoCache()

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false

        cache.clearMemory()
    }

    let dataKey = "default-3"

    func storeData() {
        let data = Fixture.JSONFromFileNamed(name: "sprite-info")
        cache.store(data)
    }

    func testStoringAndRetrievingData() {
        storeData()
        let spriteInfo = cache.spriteInfo(forKey: dataKey)
        XCTAssertNotNil(spriteInfo)
        
        let expectedInfo = SpriteInfo(width: 156, height: 84, x: 1710, y: 1992, pixelRatio: 2, placeholder: [0,8,52,20], visible: true)
        XCTAssertEqual(expectedInfo, spriteInfo, "Failed to retrieve Sprite info from cache.")
        
    }

    func testClearingMemory() {
        storeData()
        cache.clearMemory()

        XCTAssertNil(cache.spriteInfo(forKey: dataKey))
    }

    func testClearingMemoryCacheOnMemoryWarning() {
        storeData()
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)

        XCTAssertNil(cache.spriteInfo(forKey: dataKey))
    }

    func testNotificationObserverDoesNotCrash() {
        var tempCache: SpriteInfoCache? = SpriteInfoCache()
        tempCache?.clearMemory()
        tempCache = nil

        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }

}
