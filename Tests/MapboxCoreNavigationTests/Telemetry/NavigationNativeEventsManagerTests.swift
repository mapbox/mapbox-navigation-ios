import XCTest
import CoreLocation
@testable import TestHelper
@_spi(MapboxInternal) @testable import MapboxCoreNavigation
@_implementationOnly import MapboxCommon_Private

final class NavigationNativeEventsManagerTests: TestCase {
    private var eventsManager: NavigationNativeEventsManager!
    private var telemetry: TelemetrySpy!

    private var eventsMetadataProvider: EventsMetadataProvider!

    override func setUp() {
        super.setUp()

        eventsMetadataProvider = EventsMetadataProvider(appState: EventAppState())
        telemetry = TelemetrySpy()
        let navigator = CoreNavigatorSpy()
        navigator.returnedTelemetry = telemetry
        navigator.returnedEventsMetadataProvider = eventsMetadataProvider
        eventsManager = NavigationNativeEventsManager(navigator: navigator)
    }

    override func tearDown() {
        super.tearDown()
        eventsManager = nil
        telemetry = nil
    }

    func testSetUserInfo() {
        let userInfo = ["a": "b"]
        eventsManager.userInfo = userInfo
        XCTAssertEqual(eventsMetadataProvider.userInfo, userInfo)
    }

    func testSendCarPlayConnectEvent() {
        eventsManager.sendCarPlayConnectEvent()
        XCTAssertTrue(telemetry.postOuterDeviceEventCalled)
        XCTAssertEqual(telemetry.passedAction, .connected)
    }

    func testSendCarPlayDisconnectEvent() {
        eventsManager.sendCarPlayDisconnectEvent()
        XCTAssertTrue(telemetry.postOuterDeviceEventCalled)
        XCTAssertEqual(telemetry.passedAction, .disconnected)
    }

    func testCreateFeedbackIfAutomaticScreenshot() {
        _ = eventsManager.createFeedback(screenshotOption: .automatic)
        XCTAssertTrue(telemetry.startBuildUserFeedbackMetadataCalled)
    }

    func testCreateFeedbackIfCustomScreenshot() {
        let image = Fixture.image(named: "i-280")
        let feedback = eventsManager.createFeedback(screenshotOption: .custom(image))
        let expectedImage = image.jpegData(compressionQuality: 0.2)?.base64EncodedString()
        guard case let .native(metadata) = feedback?.contentType else {
            XCTFail("Expect NavNative FeedbackEvent")
            return
        }
        XCTAssertEqual(metadata.screenshot, expectedImage)
        XCTAssertTrue(telemetry.startBuildUserFeedbackMetadataCalled)
    }

    func testSendActiveNavigationFeedback() {
        let image = "image string value"
        let userFeedbackHandle = NativeUserFeedbackHandleSpy()
        let metadata = FeedbackMetadata(userFeedbackHandle: userFeedbackHandle, screenshot: image)
        let feedback = FeedbackEvent(metadata: metadata)
        var callbackCalled = false
        let type = ActiveNavigationFeedbackType.confusingAudio(subtype: .guidanceTooEarly)
        eventsManager.sendActiveNavigationFeedback(feedback,
                                                   type: type,
                                                   description: "description",
                                                   source: .reroute) { result in
            guard case .success(let userFeedback) = result else {
                XCTFail()
                return
            }
            XCTAssertEqual(userFeedback.type.typeKey, type.typeKey)
            XCTAssertEqual(userFeedback.type.subtypeKey, type.subtypeKey)
            XCTAssertEqual(userFeedback.description, "description")
            XCTAssertEqual(userFeedback.source, .reroute)
            XCTAssertEqual(userFeedback.screenshot, image)
            XCTAssertEqual(userFeedback.location.coordinate, userFeedback.location.coordinate)
            callbackCalled = true
        }
        XCTAssertTrue(telemetry.postUserFeedbackCalled)
        XCTAssertFalse(callbackCalled)
        XCTAssertEqual(telemetry.passedUserFeedback?.description, "description")
        XCTAssertEqual(telemetry.passedUserFeedback?.feedbackType, "incorrect_audio_guidance")
        XCTAssertEqual(telemetry.passedUserFeedback?.feedbackSubType, ["guidance_too_early"])
        XCTAssertEqual(telemetry.passedUserFeedback?.screenshot?.base64, image)
        XCTAssertNotNil(telemetry.passedFeedbackMetadata)

        let location = CLLocation(latitude: 37.208674, longitude: 19.524650)
        let expected = Expected<CLLocation, NSString>(value: location)
        telemetry.passedUserFeedbackCallback?(expected)
        XCTAssertTrue(callbackCalled)
    }

    func testSendPassiveNavigationFeedback() {
        let image = "image string value"
        let userFeedbackHandle = NativeUserFeedbackHandleSpy()
        let metadata = FeedbackMetadata(userFeedbackHandle: userFeedbackHandle, screenshot: image)
        let feedback = FeedbackEvent(metadata: metadata)

        var callbackCalled = false
        let type = PassiveNavigationFeedbackType.incorrectVisual(subtype: .incorrectSpeedLimit)
        eventsManager.sendPassiveNavigationFeedback(feedback,
                                                    type: type,
                                                    description: "description",
                                                    source: .reroute) { result in
            guard case .success(let userFeedback) = result else {
                XCTFail()
                return
            }
            XCTAssertEqual(userFeedback.type.typeKey, type.typeKey)
            XCTAssertEqual(userFeedback.type.subtypeKey, type.subtypeKey)
            XCTAssertEqual(userFeedback.description, "description")
            XCTAssertEqual(userFeedback.source, .reroute)
            XCTAssertEqual(userFeedback.screenshot, image)
            XCTAssertEqual(userFeedback.location.coordinate, userFeedback.location.coordinate)
            callbackCalled = true
        }

        XCTAssertTrue(telemetry.postUserFeedbackCalled)
        XCTAssertFalse(callbackCalled)
        XCTAssertEqual(telemetry.passedUserFeedback?.description, "description")
        XCTAssertEqual(telemetry.passedUserFeedback?.feedbackType, "incorrect_visual")
        XCTAssertEqual(telemetry.passedUserFeedback?.feedbackSubType, ["incorrect_speed_limit"])
        XCTAssertEqual(telemetry.passedUserFeedback?.screenshot?.base64, image)
        XCTAssertNotNil(telemetry.passedFeedbackMetadata)

        let location = CLLocation(latitude: 37.208674, longitude: 19.524650)
        let expected = Expected<CLLocation, NSString>(value: location)
        telemetry.passedUserFeedbackCallback?(expected)
        XCTAssertTrue(callbackCalled)
    }

    func testSendPassiveNavigationFeedbackIfError() {
        let image = "image string value"
        let userFeedbackHandle = NativeUserFeedbackHandleSpy()
        let metadata = FeedbackMetadata(userFeedbackHandle: userFeedbackHandle, screenshot: image)
        let feedback = FeedbackEvent(metadata: metadata)
        let reason = "failed"

        var callbackCalled = false
        eventsManager.sendPassiveNavigationFeedback(feedback,
                                                    type: .other,
                                                    description: "description",
                                                    source: .reroute) { result in
            guard case .failure(let error) = result,
                  case .failedToSend(let passedReason) = error else {
                XCTFail()
                return
            }
            XCTAssertEqual(passedReason, reason)
            callbackCalled = true
        }

        XCTAssertTrue(telemetry.postUserFeedbackCalled)
        let expected = Expected<CLLocation, NSString>(error: reason as NSString)
        telemetry.passedUserFeedbackCallback?(expected)
        XCTAssertTrue(callbackCalled)
    }

    func testSendActiveNavigationFeedbackIfError() {
        let image = "image string value"
        let userFeedbackHandle = NativeUserFeedbackHandleSpy()
        let metadata = FeedbackMetadata(userFeedbackHandle: userFeedbackHandle, screenshot: image)
        let feedback = FeedbackEvent(metadata: metadata)
        let reason = "failed"

        var callbackCalled = false
        eventsManager.sendActiveNavigationFeedback(feedback,
                                                   type: .other,
                                                   description: "description",
                                                   source: .reroute) { result in
            guard case .failure(let error) = result,
                  case .failedToSend(let passedReason) = error else {
                XCTFail()
                return
            }
            XCTAssertEqual(passedReason, reason)
            callbackCalled = true
        }

        XCTAssertTrue(telemetry.postUserFeedbackCalled)
        let expected = Expected<CLLocation, NSString>(error: reason as NSString)
        telemetry.passedUserFeedbackCallback?(expected)
        XCTAssertTrue(callbackCalled)
    }
}
