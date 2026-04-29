import MapboxNavigationCore
import UIKit

extension PassiveNavigationFeedbackType {
    var title: String {
        switch self {
        case .poorGPS:
            return "PASSIVE_NAVIGATION_FEEDBACK_BAD_GPS".localizedString(value: "Poor GPS")
        case .incorrectMapData:
            return "PASSIVE_NAVIGATION_FEEDBACK_INCORRECT_MAP_DATA".localizedString(value: "Incorrect map data")
        case .accident:
            return "PASSIVE_NAVIGATION_FEEDBACK_ACCIDENT".localizedString(value: "Accident")
        case .camera:
            return "PASSIVE_NAVIGATION_FEEDBACK_CAMERA".localizedString(value: "Camera")
        case .traffic:
            return "PASSIVE_NAVIGATION_FEEDBACK_WRONG_TRAFFIC".localizedString(value: "Traffic")
        case .wrongSpeedLimit:
            return "PASSIVE_NAVIGATION_FEEDBACK_WRONG_SPEED_LIMIT".localizedString(value: "Wrong speed limit")
        case .other:
            return "PASSIVE_NAVIGATION_FEEDBACK_OTHER".localizedString(value: "Other")
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
