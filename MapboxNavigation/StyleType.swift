import Foundation

@objc(MBStyleType)
public enum StyleType: Int, CustomStringConvertible {
    
    case daytimeStyle
    case nighttimeStyle
    
    public init?(description: String) {
        let type: StyleType
        switch description {
        case "daytimeStyle":
            type = .daytimeStyle
        case "nighttimeStyle":
            type = .nighttimeStyle
        default:
            return nil
        }
        self.init(rawValue: type.rawValue)
    }
    
    public var description: String {
        switch self {
        case .daytimeStyle:
            return "daytimeStyle"
        case .nighttimeStyle:
            return "nighttimeStyle"
        }
    }
}
