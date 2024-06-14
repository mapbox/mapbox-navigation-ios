import Foundation

@_documentation(visibility: internal)
public enum SearchFeedbackType: FeedbackType {
    case incorrectName
    case incorrectAddress
    case incorrectLocation
    case missingResult
    case other

    public var typeKey: String {
        switch self {
        case .missingResult:
            return "cannot_find"
        case .incorrectName:
            return "incorrect_name"
        case .incorrectAddress:
            return "incorrect_address"
        case .incorrectLocation:
            return "incorrect_location"
        case .other:
            return "other_result_issue"
        }
    }

    public var subtypeKey: String? {
        return nil
    }
}
