import Foundation
import CoreLocation

/// :nodoc:
/// Notifies that a new user feedback has been posted.
@_spi(MapboxInternal)
public typealias UserFeedbackCompletionHandler = (Result<UserFeedback, NavigationEventsManagerError>) -> Void

/// :nodoc:
@_spi(MapboxInternal)
public struct UserFeedback {
    public let description: String?
    public let type: FeedbackType
    public let source: FeedbackSource
    public let screenshot: String?
    public let location: CLLocation
}
