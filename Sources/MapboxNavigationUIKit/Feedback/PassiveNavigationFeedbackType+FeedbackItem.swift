import MapboxNavigationCore
import UIKit

extension PassiveNavigationFeedbackType {
    var title: String {
        switch self {
        case .poorGPS:
            return "Poor GPS"
        case .incorrectMapData:
            return "Incorrect map data"
        case .accident:
            return "Accident"
        case .camera:
            return "Camera"
        case .traffic:
            return "Traffic"
        case .wrongSpeedLimit:
            return "Wrong speed limit"
        case .other:
            return "Other"
        }
    }

    var image: UIImage {
        return .feedbackImage(named: "feedback_icon")
    }

    /// Generates a `FeedbackItem` for a given `PassiveNavigationFeedbackType`
    /// - Returns: A `FeedbackItem` model object used to render UI
    func generateFeedbackItem() -> FeedbackItem {
        return FeedbackItem(title: title, image: image, feedbackType: .passiveNavigation(self))
    }
}
