import UIKit
import MapboxCoreNavigation

extension UIImage {
    fileprivate class func feedbackImage(named: String) -> UIImage {
        return Bundle.mapboxNavigation.image(named: named)!
    }
}


public extension FeedbackType {

    // TODO: Localize these strings
    internal var title: String {
        switch self {
        case .general:
            return "Feedback"
        case .incorrectVisual(.none):
            return "Incorrect visual"
        case .incorrectVisual(.turnIconIncorrect):
            return "Turn icon incorrect"
        case .incorrectVisual(.streetNameIncorrect):
            return "Street name incorrect"
        case .incorrectVisual(.instructionUnnecessary):
            return "Instruction unnecessary"
        case .incorrectVisual(.instructionMissing):
            return "Instruction missing"
        case .incorrectVisual(.maneuverIncorrect):
            return "Maneuver incorrect"
        case .incorrectVisual(.exitInfoIncorrect):
            return "Exit info incorrect"
        case .incorrectVisual(.laneGuidanceIncorrect):
            return "Lane guidance incorrect"
        case .incorrectVisual(.roadKnownByDifferentName):
            return "Road known by different name"
        case .incorrectVisual(.other):
            return "Other"
        case .confusingAudio(.none):
            return "Confusing audio"
        case .confusingAudio(.guidanceTooEarly):
            return "Guidance too early"
        case .confusingAudio(.guidanceTooLate):
            return "Guidance too late"
        case .confusingAudio(.pronunciationIncorrect):
            return "Pronunciation incorrect"
        case .confusingAudio(.roadNameRepeated):
            return "Road name repeated"
        case .confusingAudio(.other):
            return "Other"
        case .routeQuality(.none):
            return "Route quality"
        case .routeQuality(.routeNonDrivable):
            return "Route non drivable"
        case .routeQuality(.routeNotPreferred):
            return "Route not preferred"
        case .routeQuality(.alternativeRouteNotExpected):
            return "Alternative route not expected"
        case .routeQuality(.routeIncludedMissingRoads):
            return "Route includes missing roads"
        case .routeQuality(.routeHadRoadsTooNarrowToPass):
            return "Route had roads too narrow to pass"
        case .routeQuality(.other):
            return "Other"
        case .illegalRoute(.none):
            return "Illegal route"
        case .illegalRoute(.routedDownAOneWay):
            return "Routed down a one way"
        case .illegalRoute(.turnWasNotAllowed):
            return "Turn wasn't allowed"
        case .illegalRoute(.carsNotAllowedOnStreet):
            return "Cars not allowed on street"
        case .illegalRoute(.turnAtIntersectionUnprotected):
            return "Turn at intersection unprotected"
        case .illegalRoute(.other):
            return "Other"
        case .roadClosure(.none):
            return "Road closure"
        case .roadClosure(.streetPermanentlyBlockedOff):
            return "Street permanently blocked off"
        case .roadClosure(.roadMissingFromMap):
            return "Road missing from map"
        case .roadClosure(.other):
            return "Other"
        }
    }

    /// Provides the image name for a given feedback type
    internal var image: UIImage {
        var imageName = ""

        switch self {
            case .general:
                imageName = "feedback"
            case .incorrectVisual(_):
                imageName = "incorrect_visual"
            case .confusingAudio(_):
                imageName = "confusing_audio"
            case .routeQuality(_):
                imageName = "route_quality"
            case .illegalRoute(_):
                imageName = "illegal_route"
            case .roadClosure(_):
                imageName = "road_closure"
        }

        return .feedbackImage(named: imageName)
    }


    /// Generates a `FeedbackItem` for a given `FeedbackType`
    /// - Returns: A `FeedbackItem` model object used to render UI
    func generateFeedbackItem() -> FeedbackItem {
        return FeedbackItem(title: self.title, image: self.image, feedbackType: self)
   }
}

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
    public var feedbackType: FeedbackType
    
    /**
     Creates a new `FeedbackItem`.
     */
    public init(title: String, image: UIImage, feedbackType: FeedbackType) {
        self.title = title
        self.image = image
        self.feedbackType = feedbackType
    }
}

public struct FeedbackSubtypeItem {
    public var item: FeedbackItem
    public var subtype: String?
}
