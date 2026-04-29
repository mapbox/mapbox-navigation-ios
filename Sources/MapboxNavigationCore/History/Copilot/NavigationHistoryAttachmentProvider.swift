import Foundation

enum NavigationHistoryAttachmentProvider {
    enum Error: Swift.Error {
        case noFile
        case unsupportedFormat
        case noTokenOwner
    }

    static func attachementArchive(for session: NavigationSession) throws -> AttachmentArchive {
        guard let fileUrl = session.lastHistoryFileUrl else { throw Error.noFile }

        return try .init(
            fileUrl: fileUrl,
            fileName: session.attachmentFileName(),
            fileId: UUID().uuidString,
            sessionId: session.attachmentSessionId(),
            fileType: .gzip,
            createdAt: session.startedAt
        )
    }
}

extension NavigationSession {
    var formattedStartedAt: String {
        startedAt.metadataValue
    }

    var formattedEndedAt: String? {
        endedAt?.metadataValue
    }
}

extension NavigationSession {
    private typealias Error = NavigationHistoryAttachmentProvider.Error

    fileprivate func attachmentFileName() throws -> String {
        guard let historyFormat else { throw Error.unsupportedFormat }

        return Self.composeParts(fallback: "_", separator: "__", escape: ["_", "/"], parts: [
            /* log-start-date */ startedAt.metadataValue,
            /* log-end-date */ endedAt?.metadataValue,
            /* sdk-platform */ "ios",
            /* nav-sdk-version */ navigationSdkVersion,
            /* nav-native-sdk-version */ navigationNativeSdkVersion,
            /* nav-session-id */ nil,
            /* app-version */ appVersion,
            /* app-user-id */ userId,
            /* app-session-id */ appSessionId,
        ]) + ".\(historyFormat.fileExtension)"
    }

    fileprivate func attachmentSessionId() throws -> String {
        guard let owner = tokenOwner else { throw Error.noTokenOwner }

        return Self.composeParts(fallback: "-", separator: "/", parts: [
            /* unique-prefix */ "co-pilot", owner,
            // We can use 1.1 for 1.0 as there are only changes to file name and session id
            /* specification-version */ "1.1",
            /* app-mode */ appMode,
            /* dt */ nil,
            /* hr */ nil,
            /* drive-mode */ sessionType.metadataValue,
            /* telemetry-user-id */ nil,
            /* drive-id */ id,
        ])
    }

    private static func composeParts(
        fallback: String,
        separator: String,
        escape: [Character] = [],
        parts: [String?]
    ) -> String {
        parts
            .map { part in
                part.map { escapePart(part: $0, charsToEscape: escape) }
            }
            .map { $0 ?? fallback }
            .joined(separator: separator)
    }

    /// Escape characters from `charsToEscape` by prefixing `\` to them
    private static func escapePart(part: String, charsToEscape: [Character]) -> String {
        charsToEscape.reduce(part) {
            $0.replacingOccurrences(of: "\($1)", with: "\\\($1)")
        }
    }
}

extension Date {
    fileprivate static let metadataFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds,
            .withFullTime,
            .withDashSeparatorInDate,
            .withColonSeparatorInTime,
            .withColonSeparatorInTimeZone,
        ]
        return formatter
    }()

    fileprivate var metadataValue: String {
        Self.metadataFormatter.string(from: self)
    }
}

extension NavigationHistoryFormat {
    fileprivate var fileExtension: String {
        switch self {
        case .json:
            return "json"
        case .protobuf:
            return "pbf.gz"
        case .unknown(let ext):
            return ext
        }
    }
}

extension NavigationSession.SessionType {
    var metadataValue: String {
        switch self {
        case .activeGuidance:
            return "active-guidance"
        case .freeDrive:
            return "free-drive"
        }
    }
}
