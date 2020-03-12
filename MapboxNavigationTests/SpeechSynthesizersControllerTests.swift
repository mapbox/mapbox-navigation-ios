
import XCTest
import MapboxDirections
import MapboxCoreNavigation
import TestHelper
import MapboxNavigation

class SpeechSynthesizerMock: SpeechSynthesizerStub {
    var failing = false
    var deinitExpectation: XCTestExpectation?
    var speakExpectation: XCTestExpectation?
    
    override func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress) {
        delegate?.speechSynthesizer(self,
                                    didSpeak: instruction,
                                    with: failing ? SpeechError.unsupportedLocale(languageCode: "none") : nil)
        
        speakExpectation?.fulfill()
    }
    
    deinit {
        deinitExpectation?.fulfill()
    }
}

class SpeechSynthesizersControllerTests: XCTestCase {

    var synthesizers: [SpeechSynthesizing] = []
    
    override func setUp() {
        synthesizers = [
            SpeechSynthesizerMock(),
            SpeechSynthesizerMock()
        ]
    }

    override func tearDown() {
        synthesizers = []
    }

    func testNoFallback() {
        let speakExpectation = XCTestExpectation(description: "Priority Synthesizer should be called")
        let dontSpeakExpectation = XCTestExpectation(description: "Fallback Synthesizer should not be called")
        dontSpeakExpectation.isInverted = true
        
        (synthesizers[0] as! SpeechSynthesizerMock).speakExpectation = speakExpectation
        (synthesizers[1] as! SpeechSynthesizerMock).speakExpectation = dontSpeakExpectation
        let speechSynthesizersController = SpeechSynthesizersController(synthesizers)
        
        
        speechSynthesizersController.speak(SpokenInstruction(distanceAlongStep: .init(),
                                                             text: "text",
                                                             ssmlText: "text"),
                                           during: Fixture.routeLegProgress())
        
        wait(for: [speakExpectation, dontSpeakExpectation], timeout: 2)
    }
    
    func testFallback() {
        let speechSynthesizersController = SpeechSynthesizersController(synthesizers)
        let expectation = XCTestExpectation(description: "Both Synthesizers should be called")
        expectation.expectedFulfillmentCount = 2
        (synthesizers[0] as! SpeechSynthesizerMock).failing = true
        (synthesizers[0] as! SpeechSynthesizerMock).speakExpectation = expectation
        (synthesizers[1] as! SpeechSynthesizerMock).speakExpectation = expectation
        
        speechSynthesizersController.speak(SpokenInstruction(distanceAlongStep: .init(),
                                                             text: "text",
                                                             ssmlText: "text"),
                                           during: Fixture.routeLegProgress())
        
        wait(for: [expectation], timeout: 3)
    }

    func testDeinit() {
        let route = Fixture.route(from: "route-with-instructions", options: NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 40.311012, longitude: -112.47926),
            CLLocationCoordinate2D(latitude: 29.99908, longitude: -102.828197),
        ]))
        let deinitExpectation = expectation(description: "Speech synthesizers should deinitialize")
        deinitExpectation.expectedFulfillmentCount = 2
        (synthesizers[0] as! SpeechSynthesizerMock).deinitExpectation = deinitExpectation
        (synthesizers[1] as! SpeechSynthesizerMock).deinitExpectation = deinitExpectation
        let dummyService = MapboxNavigationService(route: route)
        
        var routeController: RouteVoiceController? = RouteVoiceController(navigationService: dummyService,
                                                                          speechSynthesizer: SpeechSynthesizersController(synthesizers))
        
        synthesizers = []
        routeController = nil
        
        wait(for: [deinitExpectation], timeout: 3)
    }
}
