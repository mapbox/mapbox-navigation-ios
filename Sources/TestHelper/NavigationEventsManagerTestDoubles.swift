import CoreLocation
import Foundation
@_spi(MapboxInternal) @testable import MapboxNavigationCore
import XCTest

public final class NavigationTelemetryManagerSpy: NavigationTelemetryManager {
    public var userInfo: [String: String?]?

    var sendCarPlayConnectEventCalled = false
    var sendCarPlayDisconnectEventCalled = false
    var sendPassiveNavigationFeedbackCalled = false
    var sendActiveNavigationFeedbackCalled = false
    var createFeedbackCalled = false
    var sendNavigationFeedbackCalled = false

    var sendCarPlayConnectExpectation: XCTestExpectation?
    var sendCarPlayDisconnectExpectation: XCTestExpectation?

    var returnedFeedbackEvent: FeedbackEvent? = Fixture.createFeedbackEvent()
    var returnedUserFeedback: MapboxNavigationCore.UserFeedback = .init(
        description: "feedback",
        type: ActiveNavigationFeedbackType.illegalTurn,
        source: .user,
        screenshot: nil,
        location: .init(latitude: 1, longitude: 1)
    )

    var passedActiveNavigationFeedbackType: ActiveNavigationFeedbackType?
    var passedPassiveNavigationFeedbackType: PassiveNavigationFeedbackType?
    var passedDescription: String?
    var passedSource: FeedbackSource?
    var passedFeedbackEvent: MapboxNavigationCore.FeedbackEvent?
    var passedType: MapboxNavigationCore.FeedbackType?

    init() {}

    public func sendCarPlayConnectEvent() async {
        sendCarPlayConnectEventCalled = true
        sendCarPlayConnectExpectation?.fulfill()
    }

    public func sendCarPlayDisconnectEvent() async {
        sendCarPlayDisconnectEventCalled = true
        sendCarPlayDisconnectExpectation?.fulfill()
    }

    public func createFeedback(screenshotOption: FeedbackScreenshotOption) async -> MapboxNavigationCore
    .FeedbackEvent? {
        createFeedbackCalled = true
        return returnedFeedbackEvent
    }

    public func sendActiveNavigationFeedback(
        _ feedback: MapboxNavigationCore.FeedbackEvent,
        type: MapboxNavigationCore.ActiveNavigationFeedbackType,
        description: String?,
        source: MapboxNavigationCore.FeedbackSource
    ) async throws -> MapboxNavigationCore.UserFeedback {
        sendActiveNavigationFeedbackCalled = true
        passedFeedbackEvent = feedback
        passedActiveNavigationFeedbackType = type
        passedDescription = description
        passedSource = source
        return returnedUserFeedback
    }

    public func sendPassiveNavigationFeedback(
        _ feedback: MapboxNavigationCore.FeedbackEvent,
        type: MapboxNavigationCore.PassiveNavigationFeedbackType,
        description: String?,
        source: MapboxNavigationCore.FeedbackSource
    ) async throws -> MapboxNavigationCore.UserFeedback {
        sendPassiveNavigationFeedbackCalled = true
        passedFeedbackEvent = feedback
        passedPassiveNavigationFeedbackType = type
        passedDescription = description
        passedSource = source
        return returnedUserFeedback
    }

    public func sendNavigationFeedback(
        _ feedback: MapboxNavigationCore.FeedbackEvent,
        type: MapboxNavigationCore.FeedbackType,
        description: String?,
        source: MapboxNavigationCore.FeedbackSource
    ) async throws -> MapboxNavigationCore.UserFeedback {
        sendNavigationFeedbackCalled = true
        passedFeedbackEvent = feedback
        passedType = type
        passedDescription = description
        passedSource = source
        return returnedUserFeedback
    }

    public func reset() {
        sendCarPlayConnectEventCalled = false
        sendCarPlayDisconnectEventCalled = false
        sendPassiveNavigationFeedbackCalled = false
        sendActiveNavigationFeedbackCalled = false
        createFeedbackCalled = false
        sendNavigationFeedbackCalled = false

        passedActiveNavigationFeedbackType = nil
        passedPassiveNavigationFeedbackType = nil
        passedDescription = nil
        passedSource = nil
        passedFeedbackEvent = nil
        passedType = nil
    }
}
