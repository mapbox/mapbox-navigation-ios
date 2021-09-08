import MapboxCoreNavigation
import UIKit

extension PassiveNavigationFeedbackType {
    
    var title: String {
        switch self {
        case .badGPS:
            return NSLocalizedString("PASSIVE_NAVIGATION_FEEDBACK_BAD_GPS", bundle: .mapboxNavigation, value: "Bad GPS", comment: "Specific route feedback that user positioning is incorrect.")
        case .incorrectVisual(subtype: .incorrectSpeedLimit):
            return NSLocalizedString("PASSIVE_NAVIGATION_FEEDBACK_INCORRECT_VISUAL_INCORRECT_SPEED_LIMIT", bundle: .mapboxNavigation, value: "Speed limit incorrect", comment: "Specific route feedback that a speed limit is incorrect.")
        case .incorrectVisual(subtype: .incorrectStreetName):
            return NSLocalizedString("PASSIVE_NAVIGATION_FEEDBACK_INCORRECT_VISUAL_STREET_NAME_INCORRECT", bundle: .mapboxNavigation, value: "Street name incorrect", comment: "Specific route feedback for incorrect street name.")
        case .roadIssue(subtype: .missingRoad):
            return NSLocalizedString("PASSIVE_NAVIGATION_FEEDBACK_ROAD_ISSUE_MISSING_ROAD", bundle: .mapboxNavigation, value: "Missing road", comment: "Feedback that map shows a non-existant road.")
        case .roadIssue(subtype: .streetTemporarilyBlockedOff):
            return NSLocalizedString("PASSIVE_NAVIGATION_FEEDBACK_ROAD_ISSUE_STREET_TEMPORARILY_BLOCKED_OFF", bundle: .mapboxNavigation, value: "Street temporarily blocked off", comment: "Feedback that a street is temporarily blocked off.")
        case .roadIssue(subtype: .streetPermanentlyBlockedOff):
            return NSLocalizedString("PASSIVE_NAVIGATION_FEEDBACK_ROAD_ISSUE_STREET_PERMANENTLY_BLOCKED_OFF", bundle: .mapboxNavigation, value: "Street permanently blocked off", comment: "Feedback that a street is permanently blocked off.")
        case .wrongTraffic(subtype: .congestion):
            return NSLocalizedString("PASSIVE_NAVIGATION_FEEDBACK_WRONG_TRAFFIC_CONGESTION", bundle: .mapboxNavigation, value: "Congestion", comment: "Feedback that there is a congestion on the road.")
        case .wrongTraffic(subtype: .moderate):
            return NSLocalizedString("PASSIVE_NAVIGATION_FEEDBACK_WRONG_TRAFFIC_MODERATE", bundle: .mapboxNavigation, value: "Moderate", comment: "Feedback that there is a moderate traffic on the road.")
        case .wrongTraffic(subtype: .noTraffic):
            return NSLocalizedString("PASSIVE_NAVIGATION_FEEDBACK_WRONG_TRAFFIC_NO_TRAFFIC", bundle: .mapboxNavigation, value: "No traffic", comment: "Feedback that there is no traffic on the road.")
        case .incorrectVisual(subtype: .none):
            return NSLocalizedString("PASSIVE_NAVIGATION_FEEDBACK_INCORRECT_VISUAL", bundle: .mapboxNavigation, value: "Looks incorrect", comment: "General category of feedback where something looks incorrect.")
        case .roadIssue(subtype: .none):
            return NSLocalizedString("PASSIVE_NAVIGATION_FEEDBACK_ROAD_ISSUE", bundle: .mapboxNavigation, value: "Road issue", comment: "General category of feedback where there is an issue on the road.")
        case .wrongTraffic(subtype: .none):
            return NSLocalizedString("PASSIVE_NAVIGATION_WRONG_TRAFFIC", bundle: .mapboxNavigation, value: "Wrong traffic", comment: "General category of feedback where there is a wrong traffic.")
        case .other:
            return "Other"
        case .custom:
            return "Custom"
        }
    }
    
    var image: UIImage {
        let imageName: String

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
        return FeedbackItem(title: title, image: image, feedbackType: .passiveNavigation(self))
    }
}
