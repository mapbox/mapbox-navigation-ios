import Foundation
import MapboxCommon

/**
 An error code describing why an error occurred.
 */
public enum OfflineRegionErrorType: Int {
    /**
     Unknown error
     */
    case unknown = 0
    /**
     The offline pack could not be found on the server
     */
    case notFound
    /**
     The download failed because the access token is invalid
     */
    case unauthorized
    /**
     The download failed permanently because the request was rate limited
     */
    case rateLimited
    /**
     The download failed permanently due to a connection issue
     */
    case badConnection
    /**
     The download failed permanently due to a server issue
     */
    case serverIssue
    /**
     The data received from the server is invalid
     */
    case invalidResponse
    /**
     The offline pack is corrupt and can't be used
     */
    case corrupt
    /**
     The offline pack could not be downloaded because a file system error occurred
     */
    case filesystemError
}

/**
 Describes an error that occured while querying for offline regions, or downloading and verifying an offline pack.
 */
public struct OfflineRegionError {
    /**
     An error code describing why an error occurred.
     */
    public let errorType: OfflineRegionErrorType

    /**
     A textual description of what went wrong
     */
    public let message: String

    init(_ error: OfflineDataError) {
        self.message = error.message
        self.errorType = OfflineRegionErrorType(rawValue: error.code.rawValue) ?? .unknown
    }
}
