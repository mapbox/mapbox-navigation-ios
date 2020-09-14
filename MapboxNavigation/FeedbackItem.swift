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
            return NSLocalizedString("INCORRECT_VISUAL_FEEDBACK", bundle: .mapboxNavigation, value: "Looks incorrect", comment: "General category of route feedback where visual instruction was incorrect.")
        case .incorrectVisual(.turnIconIncorrect):
            return NSLocalizedString("INCORRECT_VISUAL_TURN_ICON_INCORRECT_FEEDBACK", bundle: .mapboxNavigation, value: "Turn icon incorrect", comment: "Specific route feedback for incorrect turn arrow being shown.")
        case .incorrectVisual(.streetNameIncorrect):
            return NSLocalizedString("INCORRECT_VISUAL_STREET_NAME_INCORRECT_FEEDBACK", bundle: .mapboxNavigation, value: "Street name incorrect", comment: "Specific route feedback for incorrect street name.")
        case .incorrectVisual(.instructionUnnecessary):
            return NSLocalizedString("INCORRECT_VISUAL_INSTRUCTION_UNNECESSARY_FEEDBACK", bundle: .mapboxNavigation, value: "Instruction unnecessary", comment: "Specific route feedback for an unnecessary instruction.")
        case .incorrectVisual(.instructionMissing):
            return NSLocalizedString("INCORRECT_VISUAL_INSTRUCTION_MISSING_FEEDBACK", bundle: .mapboxNavigation, value: "Instruction missing", comment: "Specific route feedback that an instruction was missing.")
        case .incorrectVisual(.maneuverIncorrect):
            return NSLocalizedString("INCORRECT_VISUAL_MANEUVER_INCORRECT_FEEDBACK", bundle: .mapboxNavigation, value: "Maneuver incorrect", comment: "Specific route feedback that a maneuver specified was incorrect.")
        case .incorrectVisual(.exitInfoIncorrect):
            return NSLocalizedString("INCORRECT_VISUAL_EXIT_INFO_INCORRECT_FEEDBACK", bundle: .mapboxNavigation, value: "Exit info incorrect", comment: "Specific route feedback that an exit was incorrect.")
        case .incorrectVisual(.laneGuidanceIncorrect):
            return NSLocalizedString("INCORRECT_VISUAL_LANE_GUIDANCE_INCORRECT_FEEDBACK", bundle: .mapboxNavigation, value: "Lane guidance incorrect", comment: "Specific route feedback that the wrong lane was specified.")
        case .incorrectVisual(.roadKnownByDifferentName):
            return NSLocalizedString("INCORRECT_VISUAL_ROAD_NAME_DIFFERENT_FEEDBACK", bundle: .mapboxNavigation, value: "Road known by different name", comment: "Specific route feedback that a road is known by another name.")
        case .incorrectVisual(.other):
            return NSLocalizedString("INCORRECT_VISUAL_OTHER_FEEDBACK", bundle: .mapboxNavigation, value: "Other", comment: "Specific route feedback that a visual instruction problem was encountered but not listed as a choice.")
        case .confusingAudio(.none):
            return NSLocalizedString("CONFUSING_AUDIO_FEEDBACK", bundle: .mapboxNavigation, value: "Confusing audio", comment: "Specific route feedback that audio guidance provided was confusing.")
        case .confusingAudio(.guidanceTooEarly):
            return NSLocalizedString("CONFUSING_AUDIO_GUIDANCE_TOO_EARLY_FEEDBACK", bundle: .mapboxNavigation, value: "Guidance too early", comment: "Specific route feedback that audio guidance was provided too early before a maneuever.")
        case .confusingAudio(.guidanceTooLate):
            return NSLocalizedString("CONFUSING_AUDIO_GUIDANCE_TOO_LATE_FEEDBACK", bundle: .mapboxNavigation, value: "Guidance too late", comment: "Specific route feedback that audio guidance was provided too late for a maneuever.")
        case .confusingAudio(.pronunciationIncorrect):
            return NSLocalizedString("CONFUSING_AUDIO_PRONUNCIATION_INCORRECT_FEEDBACK", bundle: .mapboxNavigation, value: "Pronunciation incorrect", comment: "Specific route feedback that audio guidance used incorrect pronunciation.")
        case .confusingAudio(.roadNameRepeated):
            return NSLocalizedString("CONFUSING_AUDIO_ROADNAME_REPEATED_FEEDBACK", bundle: .mapboxNavigation, value: "Road name repeated", comment: "Specific route feedback that audio guidance repeated a road name.")
        case .confusingAudio(.other):
            return NSLocalizedString("CONFUSING_AUDIO_OTHER_FEEDBACK", bundle: .mapboxNavigation, value: "Other", comment: "Specific route feedback that an audio guidance problem was encountered but not listed as a choice.")
        case .routeQuality(.none):
            return NSLocalizedString("ROUTE_QUALITY_FEEDBACK", bundle: .mapboxNavigation, value: "Route quality", comment: "General category of route feedback where route quality was poor.")
        case .routeQuality(.routeNonDrivable):
            return NSLocalizedString("ROUTE_QUALITY_NON_DRIVABLE_FEEDBACK", bundle: .mapboxNavigation, value: "Route non drivable", comment: "Specific route feedback that route was not drivable.")
        case .routeQuality(.routeNotPreferred):
            return NSLocalizedString("ROUTE_QUALITY_NOT_PREFERRED_FEEDBACK", bundle: .mapboxNavigation, value: "Route not preferred", comment: "Specific route feedback that route was not ideal according to user.")
        case .routeQuality(.alternativeRouteNotExpected):
            return NSLocalizedString("ROUTE_QUALITY_ALTERNATIVE_ROUTE_NOT_EXPECTED_FEEDBACK", bundle: .mapboxNavigation, value: "Alternative route not expected", comment: "Specific route feedback that user was offered an alternative that was unexpected.")
        case .routeQuality(.routeIncludedMissingRoads):
            return NSLocalizedString("ROUTE_QUALITY_INCLUDED_MISSING_ROADS_FEEDBACK", bundle: .mapboxNavigation, value: "Route includes missing roads", comment: "Specific route feedback that route contained non-existant roads.")
        case .routeQuality(.routeHadRoadsTooNarrowToPass):
            return NSLocalizedString("ROUTE_QUALITY_ROADS_TOO_NARROW_FEEDBACK", bundle: .mapboxNavigation, value: "Route had roads too narrow to pass", comment: "Specific route feedback that route contained impassible, narrow roads.")
        case .routeQuality(.other):
            return NSLocalizedString("ROUTE_QUALITY_OTHER_FEEDBACK", bundle: .mapboxNavigation, value: "Other", comment: "Specific route feedback that a route quality problem was encountered but not listed as a choice.")
        case .illegalRoute(.none):
            return NSLocalizedString("ROUTE_QUALITY_ILLEGAL_ROUTE_FEEDBACK", bundle: .mapboxNavigation, value: "Illegal route", comment: "General route feedback that route contained illegal instructions.")
        case .illegalRoute(.routedDownAOneWay):
            return NSLocalizedString("ROUTE_QUALITY_ILLEGAL_ROUTE_ONE_WAY_FEEDBACK", bundle: .mapboxNavigation, value: "Routed down a one way", comment: "Specific route feedback that route travelled wrong way on a one-way road.")
        case .illegalRoute(.turnWasNotAllowed):
            return NSLocalizedString("ROUTE_QUALITY_ILLEGAL_ROUTE_TURN_NOT_ALLOWED_FEEDBACK", bundle: .mapboxNavigation, value: "Turn wasn't allowed", comment: "Specific route feedback that route suggested an illegal turn.")
        case .illegalRoute(.carsNotAllowedOnStreet):
            return NSLocalizedString("ROUTE_QUALITY_ILLEGAL_ROUTE_CARS_NOT_ALLOWED_FEEDBACK", bundle: .mapboxNavigation, value: "Cars not allowed on street", comment: "Specific route feedback that route suggested an illegal roadway.")
        case .illegalRoute(.turnAtIntersectionUnprotected):
            return NSLocalizedString("ROUTE_QUALITY_ILLEGAL_ROUTE_UNPROTECTED_TURN_FEEDBACK", bundle: .mapboxNavigation, value: "Turn at intersection unprotected", comment: "Specific route feedback that route suggested an illegal unprotected turn.")
        case .illegalRoute(.other):
            return NSLocalizedString("ILLEGAL_ROUTE_OTHER_FEEDBACK", bundle: .mapboxNavigation, value: "Other", comment: "Specific route feedback that a illegal route problem was encountered but not listed as a choice.")
        case .roadClosure(.none):
            return NSLocalizedString("ROUTE_QUALITY_ROAD_CLOSURE_FEEDBACK", bundle: .mapboxNavigation, value: "Road closure", comment: "General route feedback that route contained closed road.")
        case .roadClosure(.streetPermanentlyBlockedOff):
            return NSLocalizedString("ROUTE_QUALITY_ROAD_CLOSURE_PERMANENT_FEEDBACK", bundle: .mapboxNavigation, value: "Street permanently blocked off", comment: "Specifc route feedback that route contained road that is permanently closed.")
        case .roadClosure(.roadMissingFromMap):
            return NSLocalizedString("ROUTE_QUALITY_ROAD_MISSING_FROM_MAP_FEEDBACK", bundle: .mapboxNavigation, value: "Road missing from map", comment: "Specifc route feedback that route contained road not shown on map.")
        case .roadClosure(.other):
            return NSLocalizedString("ROAD_CLOSURE_OTHER_FEEDBACK", bundle: .mapboxNavigation, value: "Other", comment: "Specific route feedback that a road closure type was encountered but not listed as a choice.")
        case .positioning(.none):
            return NSLocalizedString("POSITIONING", bundle: .mapboxNavigation, value: "Positioning", comment: "General category of route feedback where user position is incorrect.")
        case .positioning(.userPosition):
            return NSLocalizedString("POSITIONING_USER", bundle: .mapboxNavigation, value: "Your position", comment: "Specific route feedback that user positioning is incorrect.")
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
            case .positioning(_):
                imageName = "positioning"
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
