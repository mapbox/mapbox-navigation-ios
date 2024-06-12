import CoreLocation
import Foundation
import MapboxCommon
import MapboxNavigationNative_Private
import UIKit

/// The ``NavigationEventsManager`` is responsible for being the liaison between MapboxCoreNavigation and the Mapbox
/// telemetry.
public final class NavigationEventsManager: Sendable {
    let navNativeEventsManager: NavigationTelemetryManager?

    // MARK: Configuring Events

    /// Optional application metadata that that can help Mapbox more reliably diagnose problems that occur in the SDK.
    /// For example, you can provide your application’s name and version, a unique identifier for the end user, and a
    /// session identifier.
    /// To include this information, use the following keys: "name", "version", "userId", and "sessionId".
    public var userInfo: [String: String?]? {
        get { navNativeEventsManager?.userInfo }
        set { navNativeEventsManager?.userInfo = newValue }
    }

    required init(
        eventsMetadataProvider: EventsMetadataProvider,
        telemetry: Telemetry
    ) {
        self.navNativeEventsManager = NavigationNativeEventsManager(
            eventsMetadataProvider: eventsMetadataProvider,
            telemetry: telemetry
        )
    }

    init(navNativeEventsManager: NavigationTelemetryManager?) {
        self.navNativeEventsManager = navNativeEventsManager
    }

    // MARK: Sending Feedback Events

    /// Create feedback about the current road segment/maneuver to be sent to the Mapbox data team.
    ///
    /// You can pair this with a custom feedback UI in your app to flag problems during navigation such as road
    /// closures, incorrect instructions, etc.
    ///  If you provide a custom feedback UI that lets users elaborate on an issue, you should call this before you show
    /// the custom UI so the location and timestamp are more accurate. Alternatively, you can use
    /// `FeedbackViewContoller` which handles feedback lifecycle internally.
    /// - Parameter screenshotOption: The options to configure how the screenshot for the vent is provided.
    /// - Returns: A ``FeedbackEvent``.
    /// - Postcondition: Call ``sendActiveNavigationFeedback(_:type:description:)`` and
    /// ``sendPassiveNavigationFeedback(_:type:description:)`` with the returned feedback to attach additional metadata
    /// to the feedback and send it.
    public func createFeedback(screenshotOption: FeedbackScreenshotOption = .automatic) async -> FeedbackEvent? {
        await navNativeEventsManager?.createFeedback(screenshotOption: screenshotOption)
    }

    /// You can pair this with a custom feedback UI in your app to flag problems during navigation such as road
    /// closures, incorrect instructions, etc.
    /// - Parameters:
    ///   - feedback: A ``FeedbackEvent`` created with ``createFeedback(screenshotOption:)`` method.
    ///   - type: An ``ActiveNavigationFeedbackType`` used to specify the type of feedback.
    ///   - description: A custom string used to describe the problem in detail.
    public func sendActiveNavigationFeedback(
        _ feedback: FeedbackEvent,
        type: ActiveNavigationFeedbackType,
        description: String? = nil
    ) {
        Task {
            await sendActiveNavigationFeedback(
                feedback,
                type: type,
                description: description,
                source: .user
            )
        }
    }

    /// Send passive navigation feedback to the Mapbox data team.
    ///
    /// You can pair this with a custom feedback UI in your app to flag problems during navigation such as road
    /// closures, incorrect instructions, etc.
    /// - Parameters:
    ///   - feedback: A ``FeedbackEvent`` created with ``createFeedback(screenshotOption:)`` method.
    ///   - type: A ``PassiveNavigationFeedbackType`` used to specify the type of feedback.
    ///   - description: A custom string used to describe the problem in detail.
    public func sendPassiveNavigationFeedback(
        _ feedback: FeedbackEvent,
        type: PassiveNavigationFeedbackType,
        description: String? = nil
    ) {
        Task {
            await sendPassiveNavigationFeedback(
                feedback,
                type: type,
                description: description,
                source: .user
            )
        }
    }

    /// Send active navigation feedback to the Mapbox data team.
    ///
    /// You can pair this with a custom feedback UI in your app to flag problems during navigation such as road
    /// closures, incorrect instructions, etc.
    /// - Parameters:
    ///   - feedback: A ``FeedbackEvent`` created with ``createFeedback(screenshotOption:)`` method.
    ///   - type: An ``ActiveNavigationFeedbackType`` used to specify the type of feedback.
    ///   - description: A custom string used to describe the problem in detail.
    ///   - source: A ``FeedbackSource`` used to specify feedback source.
    /// - Returns: The sent ``UserFeedback``.
    public func sendActiveNavigationFeedback(
        _ feedback: FeedbackEvent,
        type: ActiveNavigationFeedbackType,
        description: String?,
        source: FeedbackSource
    ) async -> UserFeedback? {
        return try? await navNativeEventsManager?.sendActiveNavigationFeedback(
            feedback,
            type: type,
            description: description,
            source: source
        )
    }

    ///  Send  navigation feedback to the Mapbox data team.
    /// - Parameters:
    ///   - feedback: A ``FeedbackEvent`` created with ``createFeedback(screenshotOption:)`` method.
    ///   - type: An ``FeedbackType`` used to specify the type of feedback.
    ///   - description: A custom string used to describe the problem in detail.
    ///   - source: A ``FeedbackSource`` used to specify feedback source.
    /// - Returns: The sent ``UserFeedback``.
    public func sendNavigationFeedback(
        _ feedback: FeedbackEvent,
        type: FeedbackType,
        description: String?,
        source: FeedbackSource
    ) async throws -> UserFeedback? {
        return try? await navNativeEventsManager?.sendNavigationFeedback(
            feedback,
            type: type,
            description: description,
            source: source
        )
    }

    /// Send passive navigation feedback to the Mapbox data team.
    ///
    /// You can pair this with a custom feedback UI in your app to flag problems during navigation such as road
    /// closures, incorrect instructions, etc.
    /// - Parameters:
    ///   - feedback: A ``FeedbackEvent`` created with ``createFeedback(screenshotOption:)`` method.
    ///   - type: A ``PassiveNavigationFeedbackType`` used to specify the type of feedback.
    ///   - description: A custom string used to describe the problem in detail.
    ///   - source: A `FeedbackSource` used to specify feedback source.
    /// - Returns: The sent ``UserFeedback``.
    public func sendPassiveNavigationFeedback(
        _ feedback: FeedbackEvent,
        type: PassiveNavigationFeedbackType,
        description: String?,
        source: FeedbackSource
    ) async -> UserFeedback? {
        return try? await navNativeEventsManager?.sendPassiveNavigationFeedback(
            feedback,
            type: type,
            description: description,
            source: source
        )
    }

    /// Send event that Car Play was connected.
    public func sendCarPlayConnectEvent() {
        navNativeEventsManager?.sendCarPlayConnectEvent()
    }

    /// Send event that Car Play was disconnected.
    public func sendCarPlayDisconnectEvent() {
        navNativeEventsManager?.sendCarPlayDisconnectEvent()
    }
}
