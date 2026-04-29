import MapboxNavigationCore
import UIKit

extension ActiveNavigationFeedbackType {
    var title: String {
        switch self {
        case .closure:
            return "ROUTE_QUALITY_ROAD_CLOSURE_FEEDBACK".localizedString(value: "Closure")
        case .badRoute, .poorRoute:
            return "ROUTE_QUALITY_POOR_ROUTE_FEEDBACK".localizedString(value: "Poor route")
        case .wrongSpeedLimit:
            return "WRONG_SPEED_LIMIT".localizedString(value: "Wrong speed limit")
        case .illegalTurn:
            return "ROUTE_QUALITY_ILLEGAL_ROUTE_TURN_NOT_ALLOWED_FEEDBACK".localizedString(value: "Illegal turn")
        case .roadClosed:
            return "ROUTE_QUALITY_ROAD_CLOSED_FEEDBACK".localizedString(value: "Road closed")
        case .incorrectLaneGuidance:
            return "ROUTE_QUALITY_INCORRECT_LANE_GUIDANCE_FEEDBACK".localizedString(value: "Incorrect lane guidance")
        case .other:
            return "OTHER".localizedString(value: "Other")
        case .arrival:
            return "ROUTE_QUALITY_ROAD_CLOSED_FEEDBACK".localizedString(value: "Arrival")
        case .falsePositiveTraffic:
            return "ROUTE_QUALITY_FP_TRAFFIC_FEEDBACK".localizedString(value: "FP Traffic")
        case .falseNegativeTraffic:
            return "ROUTE_QUALITY_FN_TRAFFIC_FEEDBACK".localizedString(value: "FN Traffic")
        case .missingConstruction:
            return "ROUTE_QUALITY_MISSING_CONSTRUCTION_FEEDBACK".localizedString(value: "Missing Construction")
        case .missingSpeedLimit:
            return "ROUTE_QUALITY_MISSING_SPEED_LIMIT_FEEDBACK".localizedString(value: "Missing speed limit")
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
