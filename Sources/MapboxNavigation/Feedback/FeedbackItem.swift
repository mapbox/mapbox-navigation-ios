import UIKit
import MapboxCoreNavigation

/**
 A single feedback item displayed on an instance of `FeedbackViewController`.
 */
public struct FeedbackItem {
    /**
     The title of feedback item. This will be rendered directly below the image.
     */
    public var title: String
    
    /**
     An image representation of the feedback.
     */
    public var image: UIImage
    
    /**
     The type of feedback that best describes the event.
     */
    public var type: FeedbackItemType
    
    /**
     Creates a new `FeedbackItem` from navigation feedback.
     */
    public init(title: String, image: UIImage, feedbackType: FeedbackItemType) {
        self.title = title
        self.image = image
        self.type = feedbackType
    }
    
    static func subtypeItems(for type: FeedbackItemType) -> [FeedbackItem] {
        switch type {
        case .activeNavigation(let type):
            let subtypes: [ActiveNavigationFeedbackType]
            switch type {
            case .looksIncorrect:
                subtypes = LooksIncorrectSubtype.allCases.map { .looksIncorrect(subtype: $0) }
            case .confusingAudio:
                subtypes = ConfusingAudioSubtype.allCases.map { .confusingAudio(subtype: $0) }
            case .routeQuality:
                subtypes = RouteQualitySubtype.allCases.map { .routeQuality(subtype: $0) }
            case .illegalRoute:
                subtypes = IllegalRouteSubtype.allCases.map { .illegalRoute(subtype: $0) }
            case .roadClosure:
                subtypes = RoadClosureSubtype.allCases.map { .roadClosure(subtype: $0) }
            case .positioning, .custom, .other:
                subtypes = []
            }
            return subtypes.map { $0.generateFeedbackItem() }
        case .passiveNavigation(let type):
            let subtypes: [PassiveNavigationFeedbackType]
            switch type {
            case .badGPS, .custom, .other:
                subtypes = []
            case .incorrectVisual:
                subtypes = PassiveNavigationIncorrectVisualSubtype.allCases.map { .incorrectVisual(subtype: $0) }
            case .roadIssue:
                subtypes = PassiveNavigationRoadIssueSubtype.allCases.map { .roadIssue(subtype: $0) }
            case .wrongTraffic:
                subtypes = PassiveNavigationWrongTrafficSubtype.allCases.map { .wrongTraffic(subtype: $0) }
            }
            return subtypes.map { $0.generateFeedbackItem() }
        }
    }
}

extension NavigationEventsManager {
    func sendFeedback(_ feedback: FeedbackEvent, type: FeedbackItemType) {
        switch type {
        case .activeNavigation(let type):
            sendActiveNavigationFeedback(feedback, type: type)
        case .passiveNavigation(let type):
            sendPassiveNavigationFeedback(feedback, type: type)
        }
    }
}

extension UIImage {
    static func feedbackImage(named: String) -> UIImage {
        return Bundle.mapboxNavigation.image(named: named) ?? UIImage()
    }
}
