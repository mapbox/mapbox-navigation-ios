import UIKit
import MapboxCoreNavigation

extension UIImage {
    fileprivate class func feedbackImage(named: String) -> UIImage {
        return Bundle.mapboxNavigation.image(named: named)!
    }
}


public extension FeedbackType {

    // TODO: Localize these strings
    internal var title: String {
        switch self {
            case .general:
                return "Feedback"
            case .incorrectVisual(_):
                return "Incorrect Visual"
            case .confusingAudio(_):
                return "Confusing Audio"
            case .routeQuality(_):
                return "Route Quality"
            case .illegalRoute(_):
                return "Illegal Route"
            case .roadClosure(_):
                return "Road Closure"
        }
    }

    /// Provides the image name for a given feedback type
    internal var image: UIImage {
        var imageName = ""

        switch self {
            case .general:
                imageName = "feedback"
            case .incorrectVisual(_):
                imageName = "incorrect_visual"
            case .confusingAudio(_):
                imageName = "confusing_audio"
            case .routeQuality(_):
                imageName = "route_quality"
            case .illegalRoute(_):
                imageName = "illegal_route"
            case .roadClosure(_):
                imageName = "road_closure"
        }

        return .feedbackImage(named: imageName)
    }


    /// Generates a `FeedbackItem` for a given `FeedbackType`
    /// - Returns: A `FeedbackItem` model object used to render UI
    func generateFeedbackItem() -> FeedbackItem {
        return FeedbackItem(title: self.title, image: self.image, feedbackType: self)
   }
}

/**
 A single feedback item displayed on an instance of `FeedbackViewController`.
 */
public struct FeedbackItem {
    /**
     The title of feedback item. This will be rendered directly below the image.
     */
    public var title: String
    
    /**
     An image representation of the feedback.
     */
    public var image: UIImage
    
    /**
     The type of feedback that best describes the event.
     */
    public var feedbackType: FeedbackType
    
    /**
     Creates a new `FeedbackItem`.
     */
    public init(title: String, image: UIImage, feedbackType: FeedbackType) {
        self.title = title
        self.image = image
        self.feedbackType = feedbackType
    }
}
