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
        let imageName = switch self {
        case .poorGPS:
            "feedback_poor_gps"
        case .incorrectMapData:
            "feedback_map_data"
        case .accident:
            "feedback_accident"
        case .camera:
            "feedback_camera"
        case .traffic:
            "feedback_traffic"
        case .wrongSpeedLimit:
            "feedback_speed_limit"
        case .other:
            "feedback_other"
        }
        return .feedbackImage(named: imageName)
    }

    /// Generates a `FeedbackItem` for a given `PassiveNavigationFeedbackType`
    /// - Returns: A `FeedbackItem` model object used to render UI
    func generateFeedbackItem() -> FeedbackItem {
        return FeedbackItem(title: title, image: image, feedbackType: .passiveNavigation(self))
    }
}
