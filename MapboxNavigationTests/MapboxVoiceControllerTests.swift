import XCTest
@testable import MapboxNavigation

class MapboxVoiceControllerTests: XCTestCase {

    let speechAPISpy: SpeechAPISpy = SpeechAPISpy(accessToken: "deadbeef")
    var controller: MapboxVoiceController?

    override func setUp() {
        super.setUp()

        controller = MapboxVoiceController(speechClient: speechAPISpy)
//        speechAPISpy.reset()
    }

    func testControllerPrefersCachedData() {
    }

    func testControllerAddsDataToCacheWhenDownloaded() {

    }

}
