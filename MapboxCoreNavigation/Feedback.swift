import Foundation

@objc(MBFeedbackType)
public enum FeedbackType: Int, CustomStringConvertible {
    case general
    
    public init?(description: String) {
        let level: FeedbackType
        switch description {
        case "general":
            level = .general
        default:
            return nil
        }
        self.init(rawValue: level.rawValue)
    }
    
    public var description: String {
        switch self {
        case .general:
            return "general"
        }
    }
}
