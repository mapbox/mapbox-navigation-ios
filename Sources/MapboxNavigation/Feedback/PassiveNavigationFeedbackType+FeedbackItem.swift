import MapboxCoreNavigation
import UIKit

extension PassiveNavigationFeedbackType {
    
    var title: String {
        switch self {
        case .badGPS:
            return "Bad GPS"
        case .incorrectVisual:
            return "Incorrect Visual"
        case .roadIssue:
            return "Road Issue"
        case .wrongTraffic:
            return "Wrong Traffic"
        case .custom:
            return "Custom"
        case .other:
            return "Other"
        }
    }
    
    var image: UIImage {
        var imageName = ""

        switch self {
        case .badGPS:
            imageName = "positioning"
        case .incorrectVisual:
            imageName = "incorrect_visual"
        case .roadIssue:
            imageName = "route_quality"
        case .wrongTraffic:
            imageName = "illegal_route"
        case .custom, .other:
            imageName = ""
        }

        return .feedbackImage(named: imageName)
    }
    
    /// Generates a `FeedbackItem` for a given `PassiveNavigationFeedbackType`
    /// - Returns: A `FeedbackItem` model object used to render UI
    func generateFeedbackItem() -> FeedbackItem {
        return FeedbackItem(title: title, image: image, passiveNavigationFeedbackType: self)
    }
}
