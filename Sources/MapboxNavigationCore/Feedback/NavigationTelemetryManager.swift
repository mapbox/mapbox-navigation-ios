import CoreLocation
import Foundation

public struct UserFeedback: @unchecked Sendable {
    public let description: String?
    public let type: FeedbackType
    public let source: FeedbackSource
    public let screenshot: String?
    public let location: CLLocation
}

/// The ``NavigationTelemetryManager`` is responsible for telemetry in Navigation.
protocol NavigationTelemetryManager: AnyObject, Sendable {
    var userInfo: [String: String?]? { get set }

    func sendCarPlayConnectEvent()

    func sendCarPlayDisconnectEvent()

    func createFeedback(screenshotOption: FeedbackScreenshotOption) async -> FeedbackEvent?

    func sendActiveNavigationFeedback(
        _ feedback: FeedbackEvent,
        type: ActiveNavigationFeedbackType,
        description: String?,
        source: FeedbackSource
    ) async throws -> UserFeedback

    func sendPassiveNavigationFeedback(
        _ feedback: FeedbackEvent,
        type: PassiveNavigationFeedbackType,
        description: String?,
        source: FeedbackSource
    ) async throws -> UserFeedback

    func sendNavigationFeedback(
        _ feedback: FeedbackEvent,
        type: FeedbackType,
        description: String?,
        source: FeedbackSource
    ) async throws -> UserFeedback
}
