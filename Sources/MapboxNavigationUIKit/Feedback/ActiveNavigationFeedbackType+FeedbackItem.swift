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
        }
    }

    /// Provides the image name for a given feedback type
    var image: UIImage {
        switch self {
        case .closure:
            .feedbackImage(named: "closed_road")
        case .poorRoute:
            .feedbackImage(named: "bad_route")
        case .wrongSpeedLimit:
            .feedbackImage(named: "incorrect_speedlimit")
        case .badRoute:
            .feedbackImage(named: "bad_route")
        case .illegalTurn:
            .feedbackImage(named: "illegal_turn")
        case .roadClosed:
            .feedbackImage(named: "closed_road")
        case .incorrectLaneGuidance:
            .feedbackImage(named: "wrong_lane_guidance")
        case .other:
            .feedbackImage(named: "wrong_address")
        case .arrival:
            .feedbackImage(named: "bad_route")
        }
    }

    /// Generates a `FeedbackItem` for a given `ActiveNavigationFeedbackType`
    /// - Returns: A `FeedbackItem` model object used to render UI
    func generateFeedbackItem() -> FeedbackItem {
        return FeedbackItem(title: title, image: image, feedbackType: .activeNavigation(self))
    }
}
