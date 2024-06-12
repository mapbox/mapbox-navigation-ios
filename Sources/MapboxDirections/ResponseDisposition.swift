import Foundation

struct ResponseDisposition: Decodable, Equatable {
    var code: String?
    var message: String?
    var error: String?

    private enum CodingKeys: CodingKey {
        case code, message, error
    }
}
