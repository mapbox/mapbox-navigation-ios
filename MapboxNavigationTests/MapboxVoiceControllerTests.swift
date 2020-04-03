import XCTest
import MapboxDirections
import MapboxCoreNavigation
import MapboxSpeech
import AVKit
@testable import TestHelper
@testable import MapboxNavigation

class MapboxVoiceControllerTests: XCTestCase {
    var speechAPISpy: SpeechAPISpy!

    var route: Route {
        get {
            return Fixture.route(from: "route-with-instructions", options: routeOptions)
        }
    }
    
    let routeOptions: RouteOptions = NavigationRouteOptions(coordinates: [
        CLLocationCoordinate2D(latitude: 40.311012, longitude: -112.47926),
        CLLocationCoordinate2D(latitude: 29.99908, longitude: -102.828197),
    ])

    override func setUp() {
        super.setUp()
        let semaphore = DispatchSemaphore.init(value: 0)
        let signal = { _ = semaphore.signal() }
        FileCache().clearDisk(completion: signal)
        self.speechAPISpy = SpeechAPISpy(accessToken: "deadbeef")
        
        XCTAssert(semaphore.wait(timeout: .now() + 5) == .success)
    }
    
    override func tearDown() {
        speechAPISpy.reset()
        speechAPISpy = nil
        super.tearDown()
    }

    func testControllerDownloadsAndCachesInstructionDataWhenNotified() {
        let service = MapboxNavigationService(route: route, routeOptions: routeOptions)
        let subject = MapboxVoiceController(navigationService: service, speechClient: speechAPISpy, audioPlayerType: AudioPlayerDummy.self)
        let userInfo = [
            RouteController.NotificationUserInfoKey.routeProgressKey: service.routeProgress,
        ]
        let notification = Notification.init(name: .routeControllerDidPassSpokenInstructionPoint, object: service.router, userInfo: userInfo)

        NotificationCenter.default.post(notification)

        XCTAssertGreaterThan(speechAPISpy.audioDataCalls.count, 0)

        let call: SpeechAPISpy.AudioDataCall = speechAPISpy.audioDataCalls.first!
        let cacheKey = call.options.text
        let completion: SpeechSynthesizer.CompletionHandler = call.completion

        let data = "Here is some data".data(using: .utf8)
        completion(data, nil)

        XCTAssertTrue(subject.hasCachedSpokenInstructionForKey(cacheKey))
    }
    
    func testVoiceDeinit() {
        let dummyService = MapboxNavigationService(route: route, routeOptions: routeOptions)
        var voiceController: MockMapboxVoiceController? = MockMapboxVoiceController(navigationService: dummyService)
        let deinitExpectation = expectation(description: "Voice Controller should deinitialize")
        voiceController!.deinitExpectation = deinitExpectation
        voiceController = nil
        wait(for: [deinitExpectation], timeout: 3)
    }
    
    func testAudioCalls() {
        typealias Note = Notification.Name.MapboxVoiceTests
        let service = MapboxNavigationService(route: route, routeOptions: routeOptions)
        service.routeProgress.currentLegProgress.currentStepProgress.spokenInstructionIndex = 1
        
        let routeProgress = service.routeProgress
        let subject = MapboxVoiceController(navigationService: service, speechClient: speechAPISpy, audioPlayerType: AudioPlayerDummy.self)
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
    
    func testAccessTokenPropagatesFromNavigationViewController() {
        let directions = DirectionsSpy()
        let service = MapboxNavigationService(route: route, routeOptions: routeOptions, directions: directions)
        
        let options = NavigationOptions(navigationService: service)
        let nvc = NavigationViewController(for: route, routeOptions: routeOptions, navigationOptions: options)
        
        let voiceController = nvc.voiceController as! MapboxVoiceController
        XCTAssertEqual(voiceController.speech.accessToken, "deadbeef",
                       "Access token should propagate from NavigationViewController to SpeechSynthesizer")
    }
}

class MockMapboxVoiceController: MapboxVoiceController {
    var deinitExpectation: XCTestExpectation?
    
    deinit {
        deinitExpectation?.fulfill()
    }
}

