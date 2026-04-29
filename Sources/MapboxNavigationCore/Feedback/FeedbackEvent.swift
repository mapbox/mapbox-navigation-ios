import Foundation

/// Feedback event that can be created using ``NavigationEventsManager/createFeedback(screenshotOption:)``.
/// Use ``NavigationEventsManager/sendActiveNavigationFeedback(_:type:description:)`` to send it to the server.
/// Conforms to the `Codable` protocol, so the application can store the event persistently.
public struct FeedbackEvent: Codable, Equatable, Sendable {
    public let metadata: FeedbackMetadata

    init(metadata: FeedbackMetadata) {
        self.metadata = metadata
    }

    public var contents: [String: Any] {
        return metadata.contents
    }
}
