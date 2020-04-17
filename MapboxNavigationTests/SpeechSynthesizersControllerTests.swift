
import XCTest
import MapboxDirections
import MapboxCoreNavigation
import TestHelper
@testable import MapboxNavigation

class FailingSpeechSynthesizerMock: SpeechSynthesizerStub {
    var failing = false
    var deinitExpectation: XCTestExpectation?
    var speakExpectation: XCTestExpectation?
    
    override func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress) {
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
    
    override func speak(instruction: SpokenInstruction, instructionData: Data) {
        
        
        speakExpectation?.fulfill()
    }
}

class SystemSpeechSynthMock: SystemSpeechSynthesizer {
    var speakExpectation: XCTestExpectation?
    
    override func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress) {
        super.speak(instruction, during: legProgress)
        
        speakExpectation?.fulfill()
    }
}

class SpeechSynthesizersControllerTests: XCTestCase {

    var synthesizers: [SpeechSynthesizing] = []
    let route = Fixture.route(from: "route-with-instructions", options: NavigationRouteOptions(coordinates: [
        CLLocationCoordinate2D(latitude: 40.311012, longitude: -112.47926),
        CLLocationCoordinate2D(latitude: 29.99908, longitude: -102.828197),
    ]))
    
    override func setUp() {
        synthesizers = [
            FailingSpeechSynthesizerMock(),
            FailingSpeechSynthesizerMock()
        ]
    }

    override func tearDown() {
        synthesizers = []
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
                                           during: Fixture.routeLegProgress())
        
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
                                           during: Fixture.routeLegProgress())
        
        wait(for: [expectation], timeout: 3)
    }

    func testDeinit() {
        let deinitExpectation = expectation(description: "Speech synthesizers should deinitialize")
        deinitExpectation.expectedFulfillmentCount = 2
        (synthesizers[0] as! FailingSpeechSynthesizerMock).deinitExpectation = deinitExpectation
        (synthesizers[1] as! FailingSpeechSynthesizerMock).deinitExpectation = deinitExpectation
        let dummyService = MapboxNavigationService(route: route, routeOptions: routeOptions)
        
        var routeController: RouteVoiceController? = RouteVoiceController(navigationService: dummyService,
                                                                          speechSynthesizer: MultiplexedSpeechSynthesizer(synthesizers))
        
        synthesizers = []
        routeController = nil
        
        wait(for: [deinitExpectation], timeout: 3)
    }
    
    func testSystemSpeechSynthesizer() {
        let expectation = XCTestExpectation(description: "Synthesizers speak should be called")
        let sut = SystemSpeechSynthMock()
        sut.speakExpectation = expectation
        let dummyService = MapboxNavigationService(route: route, routeOptions: routeOptions)
        dummyService.simulationMode = .always
        var routeController: RouteVoiceController? = RouteVoiceController(navigationService: dummyService,
                                                                          speechSynthesizer: sut)
        
        dummyService.start()
        
        wait(for: [expectation], timeout: 8)
    }
    
    func testMapboxSpeechSynthesizer() {
        
        let expectation = XCTestExpectation(description: "Synthesizers speak should be called")
        let sut = SystemSpeechSynthMock()
        sut.speakExpectation = expectation
        let dummyService = MapboxNavigationService(route: route, routeOptions: routeOptions)
        dummyService.simulationMode = .always
        var routeController: RouteVoiceController? = RouteVoiceController(navigationService: dummyService,
                                                                          speechSynthesizer: sut)
        
        dummyService.start()
        
        wait(for: [expectation], timeout: 8)
    }
}
