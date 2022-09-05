import XCTest
import MapboxDirections
@testable import MapboxCoreNavigation
import TestHelper
import CoreLocation
@testable import MapboxNavigation
import class MapboxSpeech.SpeechSynthesizer
import class MapboxSpeech.SpeechOptions

class FailingSpeechSynthesizerMock: SpeechSynthesizerStub {
    var failing = false
    var deinitExpectation: XCTestExpectation?
    var speakExpectation: XCTestExpectation?
    
    override func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress, locale: Locale?) {
        delegate?.speechSynthesizer(self,
                                    didSpeak: instruction,
                                    with: failing ? SpeechError.unsupportedLocale(locale: Locale.current) : nil)
        
        speakExpectation?.fulfill()
    }
    
    deinit {
        deinitExpectation?.fulfill()
    }
}

class MapboxSpeechSynthMock: MapboxSpeechSynthesizer {
    var speakExpectation: XCTestExpectation?

    init() {
        super.init(accessToken: .mockedAccessToken, host: nil)
    }
    
    override init(remoteSpeechSynthesizer: SpeechSynthesizer) {
        super.init(remoteSpeechSynthesizer: remoteSpeechSynthesizer)
    }
    
    override func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress, locale: Locale?) {
        super.speak(instruction, during: legProgress,locale: locale)
        
        speakExpectation?.fulfill()
    }
}

class SystemSpeechSynthMock: SystemSpeechSynthesizer {
    var speakExpectation: XCTestExpectation?
    
    override func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress, locale: Locale?) {
        super.speak(instruction, during: legProgress, locale: locale)
        
        speakExpectation?.fulfill()
    }
}

class SpeechSythesizerMock: SpeechSynthesizer {
    var dataExpectation: XCTestExpectation?
    
    override func audioData(with options: SpeechOptions, completionHandler: @escaping SpeechSynthesizer.CompletionHandler) -> URLSessionDataTask {
        dataExpectation?.fulfill()
        return super.audioData(with: options, completionHandler: completionHandler)
    }
}

class SpeechSynthesizersControllerTests: TestCase {
    
    var delegateErrorBlock: ((SpeechError) -> ())?
    var synthesizers: [SpeechSynthesizing] = []
    var navigationRouteOptions: NavigationRouteOptions {
        let options = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 40.311012, longitude: -112.47926),
            CLLocationCoordinate2D(latitude: 29.99908, longitude: -102.828197),
        ])
        options.shapeFormat = .polyline
        return options
    }
    var routeResponse: RouteResponse {
        return Fixture.routeResponse(from: "route-with-instructions", options: navigationRouteOptions)
    }
    var indexedRouteResponse: IndexedRouteResponse {
        IndexedRouteResponse(routeResponse: Fixture.routeResponse(from: "route-with-instructions",
                                                                  options: navigationRouteOptions),
                             routeIndex: 0)
    }
    
    override func setUp() {
        super.setUp()
        synthesizers = [
            FailingSpeechSynthesizerMock(),
            FailingSpeechSynthesizerMock()
        ]
    }

    override func tearDown() {
        super.tearDown()
        synthesizers = []
        delegateErrorBlock = nil
    }

    func testNoFallback() {
        let speakExpectation = XCTestExpectation(description: "Priority Synthesizer should be called")
        let dontSpeakExpectation = XCTestExpectation(description: "Fallback Synthesizer should not be called")
        dontSpeakExpectation.isInverted = true
        
        (synthesizers[0] as! FailingSpeechSynthesizerMock).speakExpectation = speakExpectation
        (synthesizers[1] as! FailingSpeechSynthesizerMock).speakExpectation = dontSpeakExpectation
        let speechSynthesizersController = MultiplexedSpeechSynthesizer(synthesizers)
        
        
        speechSynthesizersController.speak(SpokenInstruction(distanceAlongStep: .init(),
                                                             text: "text",
                                                             ssmlText: "text"),
                                           during: Fixture.routeLegProgress(),
                                           locale: nil)
        
        wait(for: [speakExpectation, dontSpeakExpectation], timeout: 2)
    }
    
    func testFallback() {
        let speechSynthesizersController = MultiplexedSpeechSynthesizer(synthesizers)
        let expectation = XCTestExpectation(description: "Both Synthesizers should be called")
        expectation.expectedFulfillmentCount = 2
        (synthesizers[0] as! FailingSpeechSynthesizerMock).failing = true
        (synthesizers[0] as! FailingSpeechSynthesizerMock).speakExpectation = expectation
        (synthesizers[1] as! FailingSpeechSynthesizerMock).speakExpectation = expectation
        
        speechSynthesizersController.speak(SpokenInstruction(distanceAlongStep: .init(),
                                                             text: "text",
                                                             ssmlText: "text"),
                                           during: Fixture.routeLegProgress(),
                                           locale: nil)
        
        wait(for: [expectation], timeout: 3)
    }

    func testDeinit() {
        let deinitExpectation = expectation(description: "Speech synthesizers should deinitialize")
        deinitExpectation.expectedFulfillmentCount = 2
        (synthesizers[0] as! FailingSpeechSynthesizerMock).deinitExpectation = deinitExpectation
        (synthesizers[1] as! FailingSpeechSynthesizerMock).deinitExpectation = deinitExpectation
        let dummyService = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                                   customRoutingProvider: nil,
                                                   credentials: Fixture.credentials)
        
        var routeController: RouteVoiceController? = RouteVoiceController(navigationService: dummyService,
                                                                          speechSynthesizer: MultiplexedSpeechSynthesizer(synthesizers))
        XCTAssertNotNil(routeController)

        synthesizers = []
        routeController = nil
        
        wait(for: [deinitExpectation], timeout: 3)
    }
    
    func testSystemSpeechSynthesizer() {
        let expectation = XCTestExpectation(description: "Synthesizers speak should be called")
        let sut = SystemSpeechSynthMock()
        sut.speakExpectation = expectation
        let dummyService = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                                   customRoutingProvider: MapboxRoutingProvider(.offline),
                                                   credentials: Fixture.credentials,
                                                   simulating: .always)
        let routeController: RouteVoiceController? = RouteVoiceController(navigationService: dummyService,
                                                                          speechSynthesizer: sut)
        XCTAssertNotNil(routeController)
        dummyService.start()
        
        wait(for: [expectation], timeout: 8)
    }
    
    func testMapboxSpeechSynthesizer() {
        
        let expectation = XCTestExpectation(description: "Synthesizers speak should be called")
        let sut = MapboxSpeechSynthMock()
        sut.speakExpectation = expectation
        let dummyService = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                                   customRoutingProvider: MapboxRoutingProvider(.offline),
                                                   credentials: Fixture.credentials,
                                                   simulating: .always)
        let routeController: RouteVoiceController? = RouteVoiceController(navigationService: dummyService,
                                                                          speechSynthesizer: sut)
        XCTAssertNotNil(routeController)

        dummyService.start()
        
        wait(for: [expectation], timeout: 8)
    }
    
    func testMissingLocaleOnSystemSynth() {
        let expectation = XCTestExpectation(description: "Synthesizer should fail without Locale")
        let sut = SystemSpeechSynthMock()
        sut.locale = nil
        sut.delegate = self
        delegateErrorBlock = { error in
            switch (error) {
            case .undefinedSpeechLocale(_):
                expectation.fulfill()
            default:
                XCTFail()
            }
        }
        
        sut.speak(SpokenInstruction(distanceAlongStep: .init(),
                                    text: "text",
                                    ssmlText: "text"),
                  during: Fixture.routeLegProgress(),
                  locale: nil)
        
        wait(for: [expectation], timeout: 2)
    }
    
    func testMissingLocaleOnMapboxSynth() {
        let expectation = XCTestExpectation(description: "Synthesizer should fail without Locale")
        let sut = MapboxSpeechSynthMock()
        sut.locale = nil
        sut.delegate = self
        delegateErrorBlock = { error in
            switch (error) {
            case .undefinedSpeechLocale(_):
                expectation.fulfill()
            default:
                XCTFail()
            }
        }
        
        sut.speak(SpokenInstruction(distanceAlongStep: .init(),
                                    text: "text",
                                    ssmlText: "text"),
                  during: Fixture.routeLegProgress(),
                  locale: nil)
        
        wait(for: [expectation], timeout: 2)
    }
    
    func testCustomSynthesizerOnMapboxSynth() {
        let expectation = XCTestExpectation(description: "Custom SpeechSynthesizer should be called")
        let sut = SpeechSythesizerMock(accessToken: .mockedAccessToken)
        sut.dataExpectation = expectation
        let synth = MapboxSpeechSynthMock(remoteSpeechSynthesizer: sut)
        
        synth.speak(SpokenInstruction(distanceAlongStep: .init(),
                                      text: "text",
                                      ssmlText: "text"),
                    during: Fixture.routeLegProgress(),
                    locale: nil)
        
        wait(for: [expectation], timeout: 2)
    }
    
    func testMultiplexedParameters() {
        let controller = MultiplexedSpeechSynthesizer(nil, accessToken: .mockedAccessToken, host: nil)
        
        let testLocale = Locale(identifier: "zu")
        
        controller.muted = true
        controller.locale = testLocale
        
        XCTAssert(controller.speechSynthesizers.allSatisfy {
            $0.muted
        }, "Child speech synthesizers should be muted")
        XCTAssert(controller.speechSynthesizers.allSatisfy {
            $0.locale == testLocale
        }, "Child speech synthesizers should have locale \"\(testLocale.identifier)\" ")
    }
}

extension SpeechSynthesizersControllerTests: SpeechSynthesizingDelegate {
    
    func speechSynthesizer(_ speechSynthesizer: SpeechSynthesizing, encounteredError error: SpeechError) {
        delegateErrorBlock?(error)
    }
}
