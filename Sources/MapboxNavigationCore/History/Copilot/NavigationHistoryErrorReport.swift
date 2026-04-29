import Foundation

public struct CopilotError: Error {
    enum CopilotErrorType: String {
        case noHistoryFileProvided
        case notFound
        case missingLastHistoryFile
        case failedAttachmentsUpload
        case failedToUploadHistoryFile
        case failedToFetchAccessToken
    }

    var errorType: CopilotErrorType
    var userInfo: [String: String?]?
}

extension CopilotError {
    static func history(
        _ errorType: CopilotErrorType,
        session: NavigationSession? = nil,
        userInfo: [String: String?]? = nil
    ) -> Self {
        var userInfo = userInfo
        if let session {
            var extendedUserInfo = userInfo ?? [:]
            extendedUserInfo["sessionId"] = session.id
            extendedUserInfo["sessionType"] = session.sessionType.rawValue
            if let endedAt = session.endedAt {
                extendedUserInfo["duration"] = "\(Int(endedAt.timeIntervalSince(session.startedAt)))"
            }
            userInfo = extendedUserInfo
        }
        return Self(errorType: errorType, userInfo: userInfo)
    }
}
