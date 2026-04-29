import Foundation

public enum NavigationHistoryFormat: Codable, Equatable, Sendable {
    case json
    case protobuf
    case unknown(String)

    private static let jsonExt = "json"
    private static let protobufExt = "pbf.gz"

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case Self.jsonExt:
            self = .json
        case Self.protobufExt:
            self = .protobuf
        default:
            self = .unknown(value)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let value: String = switch self {
        case .json:
            Self.jsonExt
        case .protobuf:
            Self.protobufExt
        case .unknown(let ext):
            ext
        }
        try container.encode(value)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.json, .json), (.protobuf, .protobuf):
            return true
        case (.unknown(let lhsExt), .unknown(let rhsExt)):
            return lhsExt == rhsExt
        default:
            return false
        }
    }
}
