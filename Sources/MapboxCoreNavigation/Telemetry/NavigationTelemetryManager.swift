import Foundation

/// :nodoc:
@_spi(MapboxInternal)
public final class NavigationTelemetryConfiguration {
    // NOTE: Added temporarly, should be called only from the main thread
    public static var useNavNativeTelemetryEvents = false
}

/// The `NavigationTelemetryManager` is responsible for telemetry in Navigation.
protocol NavigationTelemetryManager {
    var userInfo: [String: String?]? { get set }

    func sendCarPlayConnectEvent()

    func sendCarPlayDisconnectEvent()

    func createFeedback(screenshotOption: FeedbackScreenshotOption) -> FeedbackEvent?

    func sendActiveNavigationFeedback(_ feedback: FeedbackEvent,
                                      type: ActiveNavigationFeedbackType,
                                      description: String?,
                                      source: FeedbackSource,
                                      completionHandler: UserFeedbackCompletionHandler?)

    func sendPassiveNavigationFeedback(_ feedback: FeedbackEvent,
                                       type: PassiveNavigationFeedbackType,
                                       description: String?,
                                       source: FeedbackSource,
                                       completionHandler: UserFeedbackCompletionHandler?)
}
