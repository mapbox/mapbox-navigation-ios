import Foundation

@objc(MBStyleType)
public enum StyleType: Int, CustomStringConvertible {
    
    case dayStyle
    case nightStyle
    
    public init?(description: String) {
        let type: StyleType
        switch description {
        case "dayStyle":
            type = .dayStyle
        case "nightStyle":
            type = .nightStyle
        default:
            return nil
        }
        self.init(rawValue: type.rawValue)
    }
    
    public var description: String {
        switch self {
        case .dayStyle:
            return "dayStyle"
        case .nightStyle:
            return "nightStyle"
        }
    }
}
