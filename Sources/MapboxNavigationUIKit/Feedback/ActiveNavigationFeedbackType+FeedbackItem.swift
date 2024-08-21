import MapboxNavigationCore
import UIKit

extension ActiveNavigationFeedbackType {
    // TODO: Localize these strings
    var title: String {
        switch self {
        case .closure:
            return "Closure"
        case .poorRoute:
            return "Poor route"
        case .wrongSpeedLimit:
            return "Wrong speed limit"
        case .badRoute:
            return "Bad route"
        case .illegalTurn:
            return "Illegal turn"
        case .roadClosed:
            return "Road closed"
        case .incorrectLaneGuidance:
            return "Incorrect lane guidance"
        case .other:
            return "Other"
        case .arrival:
            return "Arrival"
        case .falsePositiveTraffic:
            return "FP Traffic"
        case .falseNegativeTraffic:
            return "FN Traffic"
        case .missingConstruction:
            return "Missing Construction"
        case .missingSpeedLimit:
            return "Missing speed limit"
        }
    }

    /// Provides the image name for a given feedback type
    var image: UIImage {
        switch self {
        case .closure:
            .feedbackImage(named: "feedback_closure")
        case .poorRoute:
            .feedbackImage(named: "feedback_poor_route")
        case .wrongSpeedLimit:
            .feedbackImage(named: "feedback_speed_limit")
        case .badRoute:
            .feedbackImage(named: "feedback_poor_route")
        case .illegalTurn:
            .feedbackImage(named: "feedback_illegal_turn")
        case .roadClosed:
            .feedbackImage(named: "feedback_closure")
        case .incorrectLaneGuidance:
            .feedbackImage(named: "feedback_lane_quidance")
        case .other:
            .feedbackImage(named: "feedback_other")
        case .arrival:
            .feedbackImage(named: "feedback_arrival")
        case .falsePositiveTraffic:
            .feedbackImage(named: "feedback_traffic")
        case .falseNegativeTraffic:
            .feedbackImage(named: "feedback_traffic")
        case .missingConstruction:
            .feedbackImage(named: "feedback_construction")
        case .missingSpeedLimit:
            .feedbackImage(named: "feedback_speed_limit")
        }
    }

    /// Generates a `FeedbackItem` for a given `ActiveNavigationFeedbackType`
    /// - Returns: A `FeedbackItem` model object used to render UI
    func generateFeedbackItem() -> FeedbackItem {
        return FeedbackItem(title: title, image: image, feedbackType: .activeNavigation(self))
    }
}
