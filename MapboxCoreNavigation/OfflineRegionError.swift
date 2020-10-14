import Foundation
import MapboxCommon

public enum OfflineRegionErrorType: Int {
    case unknown = 0
    case notFound
    case unauthorized
    case rateLimited
    case badConnection
    case serverIssue
    case invalidResponse
    case corrupt
    case filesystemError
}

public struct OfflineRegionError {
    public let errorType: OfflineRegionErrorType
    public let message: String

    init(_ error: OfflineDataError) {
        self.message = error.message
        self.errorType = OfflineRegionErrorType(rawValue: error.code.rawValue) ?? .unknown
    }
}
