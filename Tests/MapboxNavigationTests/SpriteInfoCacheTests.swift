import XCTest
import TestHelper
@testable import MapboxNavigation

class SpriteInfoCacheTests: TestCase {
    let cache: SpriteInfoCache = SpriteInfoCache()
    let spriteKey = "SpriteKey"
    var dataKey = "us-interstate-3"

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false

        cache.clearMemory()
    }

    func storeData() {
        let data = Fixture.JSONFromFileNamed(name: "sprite-info")
        cache.store(data, spriteKey: spriteKey)
        // The cached Sprite info object attaches spriteKey to its key.
        dataKey += "-\(spriteKey)"
    }

    func testStoringAndRetrievingData() {
        storeData()
        let spriteInfo = cache.spriteInfo(forKey: dataKey)
        XCTAssertNotNil(spriteInfo)
        
        let expectedInfo = SpriteInfo(width: 156, height: 132, x: 0, y: 0, pixelRatio: 2, placeholder: [0,8,52,20], visible: true)
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
