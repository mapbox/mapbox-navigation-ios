import Foundation

/// Feedback type is used to specify the type of feedback being recorded with
/// ``NavigationEventsManager/sendPassiveNavigationFeedback(_:type:description:)``.
public enum PassiveNavigationFeedbackType: FeedbackType {
    case poorGPS
    case incorrectMapData
    case accident
    case camera
    case traffic
    case wrongSpeedLimit
    case other

    public var typeKey: String {
        switch self {
        case .other:
            return "other_issue"
        case .poorGPS:
            return "fd_poor_gps"
        case .incorrectMapData:
            return "fd_incorrect_map_data"
        case .accident:
            return "fd_accident"
        case .camera:
            return "fd_camera"
        case .traffic:
            return "fd_incorrect_traffic"
        case .wrongSpeedLimit:
            return "fd_wrong_speed_limit"
        }
    }

    public var subtypeKey: String? {
        return nil
    }
}
