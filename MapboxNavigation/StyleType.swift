import Foundation

@objc(MBStyleType)
public enum StyleType: Int, CustomStringConvertible {
    
    case lightStyle
    case darkStyle
    
    public init?(description: String) {
        let type: StyleType
        switch description {
        case "lightStyle":
            type = .lightStyle
        case "darkStyle":
            type = .darkStyle
        default:
            return nil
        }
        self.init(rawValue: type.rawValue)
    }
    
    public var description: String {
        switch self {
        case .lightStyle:
            return "lightStyle"
        case .darkStyle:
            return "darkStyle"
        }
    }
}
