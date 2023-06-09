import MapboxNavigationNative
@testable import MapboxCoreNavigation
@_implementationOnly import MapboxNavigationNative_Private

class TelemetrySpy: Telemetry {
    var postCustomEventCalled = false
    var postOuterDeviceEventCalled = false
    var startBuildUserFeedbackMetadataCalled = false
    var postUserFeedbackCalled = false
    var onChangeApplicationStateCalled = false

    var returnedUserFeedbackHandle: UserFeedbackHandle
    var passedAction: OuterDeviceAction?
    var passedUserFeedback: UserFeedback?
    var passedUserFeedbackCallback: UserFeedbackCallback?
    var passedFeedbackMetadata: UserFeedbackMetadata?

    init() {
        let navigator = NativeNavigatorSpy()
        let telemetry = navigator.getTelemetryForEventsMetadataProvider(EventsMetadataInterfaceSpy())
        returnedUserFeedbackHandle = telemetry.startBuildUserFeedbackMetadata()
    }

    func postCustomEvent(forType type: String, version: String, payload: String?) {
        postCustomEventCalled = true
    }

    func postOuterDeviceEvent(for action: OuterDeviceAction) {
        postOuterDeviceEventCalled = true
        passedAction = action
    }

    func startBuildUserFeedbackMetadata() -> UserFeedbackHandle {
        startBuildUserFeedbackMetadataCalled = true
        return returnedUserFeedbackHandle
    }

    func postUserFeedback(for feedbackMetadata: UserFeedbackMetadata,
                          userFeedback: UserFeedback,
                          callback: @escaping UserFeedbackCallback) {
        postUserFeedbackCalled = true
        passedFeedbackMetadata = feedbackMetadata
        passedUserFeedback = userFeedback
        passedUserFeedbackCallback = callback
    }

    func onChangeApplicationState(forAppState appState: ApplicationState) {
        onChangeApplicationStateCalled = true
    }
}

class NativeUserFeedbackHandleSpy: NativeUserFeedbackHandle {
    var returnedUserFeedbackMetadata: UserFeedbackMetadata = .init(locationsBefore: [],
                                                                   locationsAfter: [],
                                                                   step: nil)

    func getMetadata() -> UserFeedbackMetadata {
        returnedUserFeedbackMetadata
    }
}

final class EventsMetadataInterfaceSpy: EventsMetadataInterface {
    func provideEventsMetadata() -> EventsMetadata {
        .init(volumeLevel: nil,
              audioType: nil,
              screenBrightness: nil,
              percentTimeInForeground: nil,
              percentTimeInPortrait: nil,
              batteryPluggedIn: nil,
              batteryLevel: nil,
              connectivity: "",
              appMetadata: nil)
    }

    func screenshot() -> ScreenshotFormat? {
        nil
    }
}
