import UIKit
import MapboxCoreNavigation


extension UIImage {
    fileprivate class func feedbackImage(named: String) -> UIImage {
        return Bundle.mapboxNavigation.image(named: named)!.withRenderingMode(.alwaysTemplate)
    }
}

struct FeedbackItem {
    var title: String
    var image: UIImage
    var feedbackType: FeedbackType
    var backgroundColor: UIColor
    var audio: Data? = nil
    
    init(title: String, image: UIImage, feedbackType: FeedbackType, backgroundColor: UIColor) {
        self.title = title
        self.image = image
        self.feedbackType = feedbackType
        self.backgroundColor = backgroundColor
    }
    
    static let instructionTiming = FeedbackItem(title: instructionTimingTitle, image: .feedbackImage(named: "feedback_routing"), feedbackType: .instructionTiming, backgroundColor: #colorLiteral(red: 0.9347146749, green: 0.5047877431, blue: 0.1419634521, alpha: 1))
    static let confusingInstruction = FeedbackItem(title: confusingInstructionTitle, image: .feedbackImage(named: "feedback_hazard"), feedbackType: .confusingInstruction, backgroundColor: #colorLiteral(red: 0.9347146749, green: 0.5047877431, blue: 0.1419634521, alpha: 1))
    static let notAllowed = FeedbackItem(title: notAllowedTitle, image: .feedbackImage(named: "feedback_turn_not_allowed"), feedbackType: .unallowedTurn, backgroundColor: #colorLiteral(red: 0.9347146749, green: 0.5047877431, blue: 0.1419634521, alpha: 1))
    static let gpsInaccurate = FeedbackItem(title: gpsInaccurateTitle, image: .feedbackImage(named: "feedback_other"), feedbackType: .inaccurateGPS, backgroundColor: #colorLiteral(red: 0.9823123813, green: 0.6965931058, blue: 0.1658670604, alpha: 1))
    static let badRoute = FeedbackItem(title: badRouteTitle, image: .feedbackImage(named: "feedback_road_closed"), feedbackType: .badRoute, backgroundColor: #colorLiteral(red: 0.9823123813, green: 0.6965931058, blue: 0.1658670604, alpha: 1))
    static let reportTraffic = FeedbackItem(title: reportTrafficTitle, image: .feedbackImage(named: "feedback_car_crash"), feedbackType: .reportTraffic, backgroundColor: #colorLiteral(red: 0.9823123813, green: 0.6965931058, blue: 0.1658670604, alpha: 1))
    
    // TODO: Replace icons
    static let instructionIssue = FeedbackItem(title: instructionIssueTitle, image: .feedbackImage(named: "feedback_car_crash"), feedbackType: .reportTraffic, backgroundColor: #colorLiteral(red: 0.9823123813, green: 0.6965931058, blue: 0.1658670604, alpha: 1))
    static let heavyTraffic = FeedbackItem(title: instructionIssueTitle, image: .feedbackImage(named: "feedback_car_crash"), feedbackType: .reportTraffic, backgroundColor: #colorLiteral(red: 0.9823123813, green: 0.6965931058, blue: 0.1658670604, alpha: 1))
}

fileprivate let instructionTimingTitle = NSLocalizedString("FEEDBACK_INSTRUCTION_TIMING", bundle: .mapboxNavigation, value: "Instruction \nTiming", comment: "Feedback type for Instruction Timing")
fileprivate let confusingInstructionTitle = NSLocalizedString("FEEDBACK_CONFUSING_INSTRUCTION", bundle: .mapboxNavigation, value: "Confusing \nInstruction", comment: "Feedback type for Confusing Instruction")
fileprivate let notAllowedTitle = NSLocalizedString("FEEDBACK_NOT_ALLOWED", bundle: .mapboxNavigation, value: "Not \nAllowed", comment: "Feedback type for turn not allowed")
fileprivate let gpsInaccurateTitle = NSLocalizedString("FEEDBACK_GPS_INACCURATE", bundle: .mapboxNavigation, value: "GPS \nInaccurate", comment: "Feedback type for inaccurate GPS")
fileprivate let badRouteTitle = NSLocalizedString("FEEDBACK_BAD_ROUTE", bundle: .mapboxNavigation, value: "Bad \nRoute", comment: "Feedback type for Bad Route")
fileprivate let reportTrafficTitle = NSLocalizedString("FEEDBACK_REPORT_TRAFFIC", bundle: .mapboxNavigation, value: "Report \nTraffic", comment: "Feedback type for Report Traffic")
fileprivate let instructionIssueTitle = NSLocalizedString("FEEDBACK_INSTRUCTION_ISSUE", bundle: .mapboxNavigation, value: "Instruction \nIssue", comment: "Feedback type for Instruction Issue")
fileprivate let heavyTrafficTitle = NSLocalizedString("FEEDBACK_HEAVY_TRAFFIC", bundle: .mapboxNavigation, value: "Heavy \nTraffic", comment: "Feedback type for Heavy Traffic")

