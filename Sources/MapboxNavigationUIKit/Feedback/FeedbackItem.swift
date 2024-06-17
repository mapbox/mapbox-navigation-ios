import MapboxNavigationCore
import UIKit

/// A single feedback item displayed on an instance of ``FeedbackViewController`.
public struct FeedbackItem {
    /// The title of feedback item. This will be rendered directly below the image.
    public var title: String

    /// An image representation of the feedback.
    public var image: UIImage

    /// The type of feedback that best describes the event.
    public var type: FeedbackItemType

    /// Creates a new `FeedbackItem` from navigation feedback.
    public init(title: String, image: UIImage, feedbackType: FeedbackItemType) {
        self.title = title
        self.image = image
        self.type = feedbackType
    }
}

extension NavigationEventsManager {
    func sendFeedback(_ feedback: FeedbackEvent, type: FeedbackItemType) {
        switch type {
        case .activeNavigation(let type):
            sendActiveNavigationFeedback(feedback, type: type)
        case .passiveNavigation(let type):
            sendPassiveNavigationFeedback(feedback, type: type)
        }
    }
}

extension UIImage {
    static func feedbackImage(named: String) -> UIImage {
        return Bundle.mapboxNavigation.image(named: named) ?? UIImage()
    }
}
