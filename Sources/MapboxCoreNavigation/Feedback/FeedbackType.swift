import Foundation

/**
 Common protocol for `ActiveNavigationFeedbackType` and `PassiveNavigationFeedbackType`.
 */
public protocol FeedbackType {
    var typeKey: String { get }
    var subtypeKey: String? { get }
}
