import UIKit
import MapboxCoreNavigation

extension UIImage {
    fileprivate class func feedbackImage(named: String) -> UIImage {
        return Bundle.mapboxNavigation.image(named: named)!
    }
}

struct FeedbackItem {
    var title: String
    var image: UIImage
    var feedbackType: FeedbackType
    
    init(title: String, image: UIImage, feedbackType: FeedbackType) {
        self.title = title
        self.image = image
        self.feedbackType = feedbackType
    }
    
    static let closure = FeedbackItem(title: closureTitle, image: .feedbackImage(named:"feedback-closed-road"), feedbackType: .roadClosed)
    static let turnNotAllowed = FeedbackItem(title: notAllowedTitle, image:  .feedbackImage(named:"feedback-no-turn-allowed"), feedbackType: .notAllowed)
    static let reportTraffic = FeedbackItem(title: reportTrafficTitle, image: .feedbackImage(named:"feedback-traffic"), feedbackType: .reportTraffic)
    static let confusingInstructions = FeedbackItem(title: confusingInstructionTitle, image: .feedbackImage(named:"feedback-confusing-directions"), feedbackType: .confusingInstruction)
    static let badRoute = FeedbackItem(title: badRouteTitle, image: .feedbackImage(named:"feedback-wrong-directions"), feedbackType: .routingError)
    static let missingRoad = FeedbackItem(title: missingExitTitle, image: .feedbackImage(named:"feedback-missing-road"), feedbackType: .missingRoad)
    static let missingExit = FeedbackItem(title: missingRoadTitle, image: .feedbackImage(named:"feedback-exit"), feedbackType: .missingExit)
    static let generalMapError = FeedbackItem(title: generalIssueTitle, image: .feedbackImage(named:"feedback-map-error"), feedbackType: .mapIssue)
}

fileprivate let closureTitle = NSLocalizedString("FEEDBACK_ROAD_CLOSURE", bundle: .mapboxNavigation, value: "Road\nClosed", comment: "Feedback type for Road Closed")
fileprivate let notAllowedTitle = NSLocalizedString("FEEDBACK_NOT_ALLOWED", bundle: .mapboxNavigation, value: "Not\nAllowed", comment: "Feedback type for a maneuver that is Not Allowed")
fileprivate let reportTrafficTitle = NSLocalizedString("FEEDBACK_REPORT_TRAFFIC", bundle: .mapboxNavigation, value: "Report\nTraffic", comment: "Feedback type for Report Traffic")
fileprivate let confusingInstructionTitle = NSLocalizedString("FEEDBACK_CONFUSING_INSTRUCTION", bundle: .mapboxNavigation, value: "Confusing\nInstruction", comment: "Feedback type for Confusing Instruction")
fileprivate let badRouteTitle = NSLocalizedString("FEEDBACK_BAD_ROUTE", bundle: .mapboxNavigation, value: "Bad \nRoute", comment: "Feedback type for Bad Route")
fileprivate let missingExitTitle = NSLocalizedString("FEEDBACK_MISSING_EXIT", bundle: .mapboxNavigation, value: "Missing\nExit", comment: "Feedback type for Missing Exit")
fileprivate let missingRoadTitle = NSLocalizedString("FEEDBACK_MISSING_ROAD", bundle: .mapboxNavigation, value: "Missing\nRoad", comment: "Feedback type for Missing Road")
fileprivate let generalIssueTitle = NSLocalizedString("FEEDBACK_GENERAL_ISSUE", bundle: .mapboxNavigation, value: "Other\nMap Issue", comment: "Feedback type for Other Map Issue Issue")
