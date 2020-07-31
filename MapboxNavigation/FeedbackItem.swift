import UIKit
import MapboxCoreNavigation

extension UIImage {
    fileprivate class func feedbackImage(named: String) -> UIImage {
        return Bundle.mapboxNavigation.image(named: named)!
    }
}


public extension FeedbackType {

    internal var title: String {
        switch self {
            case .general:
                return NSLocalizedString("FEEDBACK_TYPE_GENERAL", bundle: .mapboxNavigation, value: "Feedback", comment: "Feedback type for general or unknown issue")
            case .looksIncorrect(_):
                return NSLocalizedString("FEEDBACK_TYPE_LOOKS_INCORRECT", bundle: .mapboxNavigation, value: "Looks Incorrect", comment: "Feedback type for visual that looks incorrect")
            case .confusingAudio(_):
                return NSLocalizedString("FEEDBACK_TYPE_CONFUSING_AUDIO", bundle: .mapboxNavigation, value: "Confusing Audio", comment: "Feedback type for confusing audio")
            case .routeQuality(_):
                return NSLocalizedString("FEEDBACK_TYPE_ROUTE_QUALITY", bundle: .mapboxNavigation, value: "Route Quality", comment: "Feedback type for route quality")
            case .illegalRoute(_):
                return NSLocalizedString("FEEDBACK_TYPE_ILLEGAL_ROUTE", bundle: .mapboxNavigation, value: "Illegal Route", comment: "Feedback type for illegal route")
            case .roadClosure(_):
                return NSLocalizedString("FEEDBACK_TYPE_ROAD_CLOSURE", bundle: .mapboxNavigation, value: "Road Closure", comment: "Feedback type for road closure")
        }
    }

    /// Provides the image name for a given feedback type
    internal var image: UIImage {
        var imageName = ""

        switch self {
            case .general:
                imageName = "feedback"
            case .looksIncorrect(_):
                imageName = "looks_incorrect"
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
