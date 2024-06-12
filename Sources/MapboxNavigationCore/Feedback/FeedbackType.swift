import Foundation

/// Common protocol for ``ActiveNavigationFeedbackType`` and ``PassiveNavigationFeedbackType``.
public protocol FeedbackType: Sendable {
    var typeKey: String { get }
    var subtypeKey: String? { get }
}
