import XCTest
@testable import MapboxNavigation

class MapboxVoiceControllerTests: XCTestCase {

    let speechAPIClientSpy: SpeechAPIClientSpy = SpeechAPIClientSpy(accessToken: "deadbeef")
    var controller = MapboxVoiceController()

    override func setUp() {
        super.setUp()

//        speechAPIClientSpy.reset()
        controller.speech = speechAPIClientSpy
    }
    
    func testControllerPrefersCachedData() {
    }

    func testControllerAddsDataToCacheWhenDownloaded() {

    }
    
}
