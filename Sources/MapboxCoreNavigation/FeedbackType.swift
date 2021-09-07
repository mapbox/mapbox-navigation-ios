import Foundation

/**
 Common protocol for `ActiveNavigationFeedbackType` and `PassiveNavigationFeedbackType`.
 */
public protocol FeedbackTypeProtocol { // TODO: rename to `FeedbackType` in PR https://github.com/mapbox/mapbox-navigation-ios/pull/3327
    var typeKey: String { get }
    var subtypeKey: String? { get }
}
