import UIKit

/// Indicates screenshotting behavior of ``NavigationEventsManager``.
public enum FeedbackScreenshotOption: Sendable {
    case automatic
    case custom(UIImage)
}
