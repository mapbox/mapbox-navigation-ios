import Foundation

@objc public enum StyleType: Int, CustomStringConvertible {
    case day
    case night
    
    public init?(description: String) {
        let type: StyleType
        switch description {
        case "day":
            type = .day
        case "night":
            type = .night
        default:
            return nil
        }
        self.init(rawValue: type.rawValue)
    }
    
    public var description: String {
        switch self {
        case .day:
            return "day"
        case .night:
            return "night"
        }
    }
}
