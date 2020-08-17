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
            return "Incorrect Visual"
        case .incorrectVisual(.turnIconIncorrect):
            return "Turn Icon Incorrect"
        case .incorrectVisual(.streetNameIncorrect):
            return "Street Name Incorrect"
        case .incorrectVisual(.instructionUnnecessary):
            return "Instruction Unnecessary"
        case .incorrectVisual(.instructionMissing):
            return "Instruction Missing"
        case .incorrectVisual(.maneuverIncorrect):
            return "Maneuver Incorrect"
        case .incorrectVisual(.exitInfoIncorrect):
            return "Exit Info Incorrect"
        case .incorrectVisual(.laneGuidanceIncorrect):
            return "Lane Guidance Incorrect"
        case .incorrectVisual(.roadKnownByDifferentName):
            return "Road Known By Different Name"
        case .incorrectVisual(.other):
            return "Other"
        case .confusingAudio(.none):
            return "Confusing Audio"
        case .confusingAudio(.guidanceTooEarly):
            return "Guidance Too Early"
        case .confusingAudio(.guidanceTooLate):
            return "Guidance Too Late"
        case .confusingAudio(.pronunciationIncorrect):
            return "Pronunciation Incorrect"
        case .confusingAudio(.roadNameRepeated):
            return "Road Name Repeated"
        case .confusingAudio(.other):
            return "Other"
        case .routeQuality(.none):
            return "Route Quality"
        case .routeQuality(.routeNonDrivable):
            return "Route Non Drivable"
        case .routeQuality(.routeNotPreferred):
            return "Route Not Preferred"
        case .routeQuality(.alternativeRouteNotExpected):
            return "Alternative Route Not Expected"
        case .routeQuality(.routeIncludedMissingRoads):
            return "Route Includes Missing Roads"
        case .routeQuality(.routeHadRoadsTooNarrowToPass):
            return "Route Had Roads Too Narrow To Pass"
        case .routeQuality(.other):
            return "Other"
        case .illegalRoute(.none):
            return "Illegal Route"
        case .illegalRoute(.routedDownAOneWay):
            return "Routed Down A One Way"
        case .illegalRoute(.turnWasNotAllowed):
            return "Turn Was Not Allowed"
        case .illegalRoute(.carsNotAllowedOnStreet):
            return "Cars Not Allowed On Street"
        case .illegalRoute(.turnAtIntersectionUnprotected):
            return "Turn at Intersection Unprotected"
        case .illegalRoute(.other):
            return "Other"
        case .roadClosure(.none):
            return "Road Closure"
        case .roadClosure(.streetPermanentlyBlockedOff):
            return "Street Permanently Blocked Off"
        case .roadClosure(.roadMissingFromMap):
            return "Road Missing From Map"
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
