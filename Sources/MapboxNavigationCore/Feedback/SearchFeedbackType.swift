import Foundation

@_documentation(visibility: internal)
public enum SearchFeedbackType: FeedbackType {
    case incorrectName
    case incorrectAddress
    case incorrectLocation
    case phoneNumber
    case resultRank
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
        case .phoneNumber:
            return "incorrect_phone_number"
        case .resultRank:
            return "incorrect_result_rank"
        }
    }

    public var subtypeKey: String? {
        return nil
    }
}
