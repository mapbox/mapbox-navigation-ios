import Foundation

/**
 Feedback type is used to specify the type of feedback being recorded with `NavigationEventsManager.sendPassiveNavigationFeedback(_:type:description:)`.
 */
public enum PassiveNavigationFeedbackType: FeedbackType {
    
    /// Indicates an incorrect visual.
    case incorrectVisual(subtype: PassiveNavigationIncorrectVisualSubtype?)
    
    /// Indicates a road closure was observed.
    case roadIssue(subtype: PassiveNavigationRoadIssueSubtype?)
    
    /// Indicates a wrong traffic.
    case wrongTraffic(subtype: PassiveNavigationWrongTrafficSubtype?)
    
    /// The user’s location is not matching the real position of the vehicle.
    case badGPS
    
    /// Indicates a custom feedback type and subtype.
    case custom(type: String, subtype: String?)
    
    /// Indicates other feedback. You should provide a `description` string to `NavigationEventsManager.sendPassiveNavigationFeedback(_:type:description:)`
    /// to elaborate on the feedback if possible.
    case other
    
    public var typeKey: String {
        switch self {
        case .incorrectVisual:
            return "incorrect_visual"
        case .roadIssue:
            return "road_issue"
        case .wrongTraffic:
            return "traffic_issue"
        case .badGPS:
            return "positioning_issue"
        case .custom(let type, _):
            return type
        case .other:
            return "other_issue"
        }
    }
    
    public var subtypeKey: String? {
        switch self {
        case .incorrectVisual(subtype: .incorrectStreetName):
            return "street_name_incorrect"
        case .incorrectVisual(subtype: .incorrectSpeedLimit):
            return "incorrect_speed_limit"
        case .roadIssue(subtype: .streetPermanentlyBlockedOff):
            return "street_permanently_blocked_off"
        case .roadIssue(subtype: .streetTemporarilyBlockedOff):
            return "street_temporarily_blocked_off"
        case .roadIssue(subtype: .missingRoad):
            return "missing_road"
        case .wrongTraffic(subtype: .congestion):
            return "traffic_congestion"
        case .wrongTraffic(subtype: .moderate):
            return "traffic_moderate"
        case .wrongTraffic(subtype: .noTraffic):
            return "traffic_no"
        case .custom(_, let subtype):
            return subtype
        case .badGPS,
             .other,
             .incorrectVisual(subtype: nil),
             .roadIssue(subtype: nil),
             .wrongTraffic(subtype: nil):
            return nil
        }
    }
}

/// Enum denoting the subtypes of the  `Incorrect Visual` top-level category.
public enum PassiveNavigationIncorrectVisualSubtype: CaseIterable {
    /// The name of the street that appears for the driver on the map is incorrect.
    case incorrectStreetName
    
    /// The speed limit displayed on the UI overlay does not match the speed limit of the road.
    case incorrectSpeedLimit
}

/// Enum denoting the subtypes of the  `Road Issue` top-level category.
public enum PassiveNavigationRoadIssueSubtype: CaseIterable {
    /// The map data is incorrect, the certain piece must be excluded from routing because user won’t be ever able to follow any route based on that piece .
    case streetPermanentlyBlockedOff
    
    /// The user is unable to follow the route due to a temporary closure.
    case streetTemporarilyBlockedOff
    
    /// The map data is incorrect or outdated, the user isn’t able to follow any route based on that road.
    case missingRoad
}

/// Enum denoting the subtypes of the  `Wrong Traffic` top-level category.
public enum PassiveNavigationWrongTrafficSubtype: CaseIterable {
    /// The traffic displayed on the map is not reflecting the actual congestion of the road.
    case congestion
    
    /// The traffic displayed on the map is not reflecting the actual moderate traffic of the road.
    case moderate
    
    /// The traffic displayed on the map is displaying traffic when there isn’t any.
    case noTraffic
}
