import XCTest
import MapboxDirections
import MapboxCoreNavigation
import MapboxSpeech
@testable import MapboxNavigation

class MapboxVoiceControllerTests: XCTestCase {

    let speechAPISpy: SpeechAPISpy = SpeechAPISpy(accessToken: "deadbeef")
    var controller: MapboxVoiceController?

    var route: Route {
        get {
            //TODO: these waypoints have nothing to do with this route. Not sure if it matters.
            return Fixture.route(from: "route-with-instructions", waypoints: [Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165)), Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))])
        }
    }

    override func setUp() {
        super.setUp()

        controller = MapboxVoiceController(speechClient: speechAPISpy)
        speechAPISpy.reset()
    }

    func testControllerDownloadsAndCachesInstructionDataWhenNotified() {
        let routeProgress = RouteProgress.init(route: route, legIndex: 0, spokenInstructionIndex: 0)
        let userInfo = [RouteControllerNotificationUserInfoKey.routeProgressKey : routeProgress]
        let notification = Notification.init(name: .routeControllerDidPassSpokenInstructionPoint, object: nil, userInfo: userInfo)

        NotificationCenter.default.post(notification)

        XCTAssertGreaterThan(speechAPISpy.audioDataCalls.count, 0)

        let call: SpeechAPISpy.AudioDataCall = speechAPISpy.audioDataCalls.first!
        let cacheKey = call.0.text
        let completion: SpeechSynthesizer.CompletionHandler = call.1

        let data = "Here is some data".data(using: .utf8)
        completion(data, nil)

        XCTAssertTrue(controller!.hasCachedSpokenInstructionForKey(cacheKey))
    }
    
    func testVoiceDeinit() {
        var voiceController: MockMapboxVoiceController? = MockMapboxVoiceController()
        let deinitExpectation = expectation(description: "Voice Controller should deinitialize")
        voiceController?.deinitExpectation = deinitExpectation
        let bundle = Bundle(for: MapboxVoiceControllerTests.self)
        let filePath = bundle.path(forResource: "turn_left", ofType: "data")
        let filePathURL = URL(fileURLWithPath: filePath! )
        let data = try! Data(contentsOf: filePathURL)
        voiceController?.play(data)
        voiceController = nil
        XCTAssertNil(voiceController, "voiceController should be nil after nilling it.")
        
        wait(for: [deinitExpectation], timeout: 3)
    }
}

class MockMapboxVoiceController: MapboxVoiceController {
    var deinitExpectation: XCTestExpectation?
    
    deinit {
        deinitExpectation?.fulfill()
    }
}
