import XCTest
import MapboxDirections
import MapboxCoreNavigation
import MapboxSpeech
import AVKit
@testable import MapboxNavigation

class MapboxVoiceControllerTests: XCTestCase {

    var speechAPISpy: SpeechAPISpy!
    var controller: MapboxVoiceController?

    var route: Route {
        get {
            //TODO: these waypoints have nothing to do with this route. Not sure if it matters.
            return Fixture.route(from: "route-with-instructions", waypoints: [Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165)), Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))])
        }
    }

    override func setUp() {
        super.setUp()
        let semaphore = DispatchSemaphore.init(value: 0)
        let signal = { _ = semaphore.signal() }
        FileCache().clearDisk(completion: signal)
        self.speechAPISpy = SpeechAPISpy(accessToken: "deadbeef")
        controller = MapboxVoiceController(speechClient: speechAPISpy, audioPlayerType: AudioPlayerDummy.self)
        
        XCTAssert(semaphore.wait(timeout: .now() + 5) == .success)
    }
    
    override func tearDown() {
        speechAPISpy.reset()
        controller = nil
        speechAPISpy = nil
    }

    func testControllerDownloadsAndCachesInstructionDataWhenNotified() {
        let routeProgress = RouteProgress.init(route: route, legIndex: 0, spokenInstructionIndex: 0)
        let userInfo = [RouteControllerNotificationUserInfoKey.routeProgressKey : routeProgress]
        let notification = Notification.init(name: .routeControllerDidPassSpokenInstructionPoint, object: nil, userInfo: userInfo)

        NotificationCenter.default.post(notification)

        XCTAssertGreaterThan(speechAPISpy.audioDataCalls.count, 0)

        let call: SpeechAPISpy.AudioDataCall = speechAPISpy.audioDataCalls.first!
        let cacheKey = call.options.text
        let completion: SpeechSynthesizer.CompletionHandler = call.completion

        let data = "Here is some data".data(using: .utf8)
        completion(data, nil)

        XCTAssertTrue(controller!.hasCachedSpokenInstructionForKey(cacheKey))
    }
    
    func testVoiceDeinit() {
        var voiceController: MockMapboxVoiceController? = MockMapboxVoiceController()
        let deinitExpectation = expectation(description: "Voice Controller should deinitialize")
        voiceController!.deinitExpectation = deinitExpectation
        voiceController = nil
        wait(for: [deinitExpectation], timeout: 3)
    }
    
    func testAudioCalls() {
        typealias Note = Notification.Name.MapboxVoiceTests
        let routeProgress = RouteProgress.init(route: route, legIndex: 0, spokenInstructionIndex: 1)
        let subject = MapboxVoiceController(speechClient: speechAPISpy, audioPlayerType: AudioPlayerDummy.self)
        subject.routeProgress = routeProgress
        
        let instruction = routeProgress.currentLegProgress.currentStepProgress.currentSpokenInstruction
        
        
        let handler: XCTNSNotificationExpectation.Handler = { note in
            return true
        }
        let prepare = XCTNSNotificationExpectation(name: Note.prepareToPlay, object: nil, notificationCenter: .default)
        prepare.handler = handler
        let play = XCTNSNotificationExpectation(name: Note.play, object: nil, notificationCenter: .default)
        play.handler = handler

        subject.speak(instruction!)
        let firstCall = speechAPISpy.audioDataCalls.first!
        firstCall.fulfill()
        
        
        wait(for: [play, prepare], timeout: 4)
    }
}

class MockMapboxVoiceController: MapboxVoiceController {
    var deinitExpectation: XCTestExpectation?
    
    deinit {
        deinitExpectation?.fulfill()
    }
}

fileprivate extension Notification.Name {
    enum MapboxVoiceTests {
        static let prepareToPlay = NSNotification.Name("MapboxVoiceTests.prepareToPlay")
        static let play = NSNotification.Name("MapboxVoiceTests.play")
    }
}
class AudioPlayerDummy: AVAudioPlayer {
    public let sound = NSDataAsset(name: "reroute-sound", bundle: .mapboxNavigation)!
    
    lazy var notifier: NotificationCenter = .default
    fileprivate typealias Note = Notification.Name.MapboxVoiceTests
    
    override func prepareToPlay() -> Bool {
        notifier.post(name: Note.prepareToPlay, object: self)
        return true
    }
    override func play() -> Bool {
        notifier.post(name: Note.play, object: self)
        return true
    }
}
