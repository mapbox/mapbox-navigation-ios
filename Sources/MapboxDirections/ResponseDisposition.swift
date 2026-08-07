import Foundation

struct ResponseDisposition: Decodable, Equatable {
    static let OkCode = "Ok"
    var code: String?
    var message: String?
    var error: String?

    private enum CodingKeys: CodingKey {
        case code, message, error
    }
}
